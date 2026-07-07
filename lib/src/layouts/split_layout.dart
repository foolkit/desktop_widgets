import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 二分栏布局的方向。
enum SplitAxis {
  /// 水平方向，分栏左右排列。
  horizontal,

  /// 垂直方向，分栏上下排列。
  vertical,
}

/// 二分栏尺寸的计算单位。
enum SplitSizeUnit {
  /// 按容器尺寸的比例分配。
  proportional,

  /// 按像素值分配，优先级高的分栏优先获得其指定像素。
  pixel,
}

/// [SplitLayout] 中一个分栏的配置。
class SplitPanel {
  /// 创建一个分栏配置。
  const SplitPanel({
    required this.child,
    this.backgroundColor,
    this.priority = 0,
    this.size,
    this.minSize,
    this.maxSize,
    this.keepAlive = false,
  });

  /// 分栏内容。
  final Widget child;

  /// 分栏背景色。
  final Color? backgroundColor;

  /// 布局尺寸计算优先级，数值越低优先级越高。
  final int priority;

  /// 初始尺寸。
  ///
  /// 当 [SplitLayout.sizeUnit] 为 [SplitSizeUnit.proportional] 时，
  /// 该值表示占容器可用空间的比例（0.0 ~ 1.0）。
  /// 当 [SplitLayout.sizeUnit] 为 [SplitSizeUnit.pixel] 时，
  /// 该值表示像素尺寸。
  final double? size;

  /// 最小尺寸（宽度或高度）。
  final double? minSize;

  /// 最大尺寸（宽度或高度）。
  final double? maxSize;
  final bool keepAlive;
}

/// 用于从外部控制 [SplitLayout] 的状态。
class SplitLayoutController extends ChangeNotifier {
  final List<bool> _visible = <bool>[true, true];

  /// 第一个分栏是否可见。
  bool get panel0Visible => _visible[0];

  /// 第二个分栏是否可见。
  bool get panel1Visible => _visible[1];

  /// 返回指定分栏的可见性。
  bool isPanelVisible(int index) {
    assert(index == 0 || index == 1, 'index must be 0 or 1');
    return _visible[index];
  }

  /// 设置指定分栏的可见性。
  void setPanelVisible(int index, bool visible) {
    assert(index == 0 || index == 1, 'index must be 0 or 1');
    if (_visible[index] == visible) return;
    _visible[index] = visible;
    notifyListeners();
  }

  /// 切换指定分栏的可见性。
  void togglePanel(int index) => setPanelVisible(index, !_visible[index]);
}

/// 二分栏布局组件。
///
/// 包含两个分栏和一条分隔线，支持按比例或按像素分配尺寸，
/// 可通过 [SplitLayoutController] 控制分栏显隐，支持拖拽调整尺寸。
class SplitLayout extends StatefulWidget {
  /// 创建一个二分栏布局。
  const SplitLayout({
    super.key,
    required this.panels,
    this.axis = SplitAxis.horizontal,
    this.sizeUnit = SplitSizeUnit.proportional,
    this.resizable = true,
    this.dividerThickness = 1,
    this.dividerColor,
    this.panelAnimationDuration = const Duration(milliseconds: 200),
    this.panelAnimationCurve = Curves.easeOutCubic,
    this.controller,
  }) : assert(panels.length == 2, 'SplitLayout requires exactly 2 panels');

  /// 两个分栏配置，长度必须为 2。
  final List<SplitPanel> panels;

  /// 布局方向，默认为 [SplitAxis.horizontal]。
  final SplitAxis axis;

  /// 尺寸计算单位，默认为 [SplitSizeUnit.proportional]。
  final SplitSizeUnit sizeUnit;

  /// 是否可通过拖拽分隔线调整分栏尺寸。
  final bool resizable;

  /// 分隔线视觉厚度。
  final double dividerThickness;

  /// 分隔线颜色，默认使用 [ThemeData.dividerColor]。
  final Color? dividerColor;

  final Duration panelAnimationDuration;

  final Curve panelAnimationCurve;

  /// 外部控制器，用于控制分栏显隐。
  final SplitLayoutController? controller;

  @override
  State<SplitLayout> createState() => _SplitLayoutState();
}

class _SplitLayoutState extends State<SplitLayout>
    with SingleTickerProviderStateMixin {
  late final SplitLayoutController _internalController;
  late final AnimationController _visibilityController;
  late Animation<double> _visibilityAnimation;

  SplitLayoutController get _effectiveController =>
      widget.controller ?? _internalController;

  bool _lastPanel0Visible = true;
  bool _lastPanel1Visible = true;
  bool _visibilityAnimating = false;
  double _currentPanel0Size = 0.0;
  double _currentDividerSize = 0.0;
  double _currentPanel1Size = 0.0;
  double _fromPanel0Size = 0.0;
  double _fromDividerSize = 0.0;
  double _fromPanel1Size = 0.0;

  /// 在 [SplitSizeUnit.proportional] 模式下，第一个分栏占可用空间的比例。
  double _ratio = 0.5;

  /// 在 [SplitSizeUnit.pixel] 模式下，优先级较高的分栏的像素尺寸。
  double _pixelSize = 200.0;

  /// 当前被跟踪的分栏索引（尺寸计算以该分栏为基准）。
  late int _primaryIndex;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: widget.panelAnimationDuration,
    )
      ..addListener(() {
        if (_visibilityAnimating) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() => _visibilityAnimating = false);
        }
      });
    _visibilityAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: widget.panelAnimationCurve,
    );
    _internalController = SplitLayoutController();
    _internalController.addListener(_onControllerChanged);
    _lastPanel0Visible = _effectiveController.isPanelVisible(0);
    _lastPanel1Visible = _effectiveController.isPanelVisible(1);
    _initSizing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SplitLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (oldWidget.panelAnimationDuration != widget.panelAnimationDuration ||
        oldWidget.panelAnimationCurve != widget.panelAnimationCurve) {
      _visibilityController.duration = widget.panelAnimationDuration;
      _visibilityAnimation = CurvedAnimation(
        parent: _visibilityController,
        curve: widget.panelAnimationCurve,
      );
    }

    final prioritiesChanged = oldWidget.panels[0].priority !=
            widget.panels[0].priority ||
        oldWidget.panels[1].priority != widget.panels[1].priority;
    if (oldWidget.sizeUnit != widget.sizeUnit || prioritiesChanged) {
      _initSizing();
    }
  }

  @override
  void dispose() {
    _internalController.dispose();
    widget.controller?.removeListener(_onControllerChanged);
    _visibilityController.dispose();
    super.dispose();
  }

  void _initSizing() {
    if (widget.sizeUnit == SplitSizeUnit.proportional) {
      _primaryIndex = 0;
      final initial = widget.panels[0].size;
      _ratio = initial == null ? 0.5 : initial.clamp(0.0, 1.0);
    } else {
      _primaryIndex = widget.panels[0].priority <= widget.panels[1].priority
          ? 0
          : 1;
      final initial = widget.panels[_primaryIndex].size;
      _pixelSize = initial ?? 200.0;
    }
  }

  void _onControllerChanged() {
    final panel0Visible = _effectiveController.isPanelVisible(0);
    final panel1Visible = _effectiveController.isPanelVisible(1);

    final visibilityChanged =
        panel0Visible != _lastPanel0Visible || panel1Visible != _lastPanel1Visible;
    if (visibilityChanged) {
      _visibilityAnimating = true;
      _fromPanel0Size = _currentPanel0Size;
      _fromDividerSize = _currentDividerSize;
      _fromPanel1Size = _currentPanel1Size;
      _visibilityController.forward(from: 0.0);
    }
    _lastPanel0Visible = panel0Visible;
    _lastPanel1Visible = panel1Visible;
    setState(() {});
  }

  double get _dividerHitSize =>
      widget.resizable ? math.max(8.0, widget.dividerThickness) : widget.dividerThickness;

  double _primarySize(double available) {
    final primaryPanel = widget.panels[_primaryIndex];
    final otherIndex = 1 - _primaryIndex;
    final otherPanel = widget.panels[otherIndex];

    if (widget.sizeUnit == SplitSizeUnit.proportional) {
      // 在按比例模式下，minSize/maxSize 也是比例值（0.0 ~ 1.0）。
      final minPrimary = primaryPanel.minSize ?? 0.0;
      final maxPrimary = primaryPanel.maxSize ?? 1.0;
      final minOther = otherPanel.minSize ?? 0.0;
      final maxOther = otherPanel.maxSize ?? 1.0;

      double ratio = _ratio;
      // 保证主分栏的比例约束
      ratio = ratio.clamp(minPrimary, maxPrimary);
      // 保证另一个分栏的比例约束
      ratio = ratio.clamp(1.0 - maxOther, 1.0 - minOther);
      return available * ratio.clamp(0.0, 1.0);
    }

    // 按像素模式：minSize/maxSize 为像素值。
    double desired = _pixelSize;
    final minPrimary = primaryPanel.minSize ?? 0.0;
    final maxPrimary = primaryPanel.maxSize ?? double.infinity;
    final minOther = otherPanel.minSize ?? 0.0;
    final maxOther = otherPanel.maxSize ?? double.infinity;

    // 先按自身 min/max 收敛
    desired = desired.clamp(minPrimary, maxPrimary);
    // 再保证另一个分栏满足其 min/max
    desired = desired.clamp(available - maxOther, available - minOther);
    // 最后限制在可用范围内
    return desired.clamp(0.0, available);
  }

  void _onDragUpdate(DragUpdateDetails details, double available) {
    final delta = widget.axis == SplitAxis.horizontal
        ? details.delta.dx
        : details.delta.dy;
    final multiplier = _primaryIndex == 0 ? 1.0 : -1.0;

    if (widget.sizeUnit == SplitSizeUnit.proportional) {
      final newRatio = _ratio + delta * multiplier / available;
      _ratio = newRatio.clamp(0.0, 1.0);
    } else {
      final newSize = _pixelSize + delta * multiplier;
      _pixelSize = newSize.clamp(0.0, available);
    }
    setState(() {});
  }

  Widget _buildPanelContent(int index, SplitPanel panel) {
    return Container(
      color: panel.backgroundColor,
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: panel.child,
      ),
    );
  }

  Widget _buildPanelWithVisibility(
    int index,
    SplitPanel panel,
    double size, {
    required bool visible,
  }) {
    final shouldBuild = visible || panel.keepAlive || _visibilityAnimating;
    if (!shouldBuild) return const SizedBox.shrink();

    final contentVisible = visible || _visibilityAnimating;
    final content = Offstage(
      offstage: !contentVisible,
      child: TickerMode(
        enabled: contentVisible,
        child: _buildPanelContent(index, panel),
      ),
    );

    if (!size.isFinite) {
      if (!contentVisible) return const SizedBox.shrink();
      return Expanded(child: content);
    }

    return ClipRect(
      child: widget.axis == SplitAxis.horizontal
          ? SizedBox(width: size, child: content)
          : SizedBox(height: size, child: content),
    );
  }

  Widget _buildDivider(double available, {required bool enabled}) {
    final dividerColor = widget.dividerColor ?? Theme.of(context).dividerColor;
    final hitSize = _dividerHitSize;

    Widget visualDivider;
    if (widget.axis == SplitAxis.horizontal) {
      visualDivider = Container(
        width: hitSize,
        alignment: Alignment.center,
        child: Container(
          width: widget.dividerThickness,
          color: dividerColor,
        ),
      );
    } else {
      visualDivider = Container(
        height: hitSize,
        alignment: Alignment.center,
        child: Container(
          height: widget.dividerThickness,
          color: dividerColor,
        ),
      );
    }

    if (!widget.resizable) return visualDivider;
    if (!enabled) {
      return MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: visualDivider,
      );
    }

    return MouseRegion(
      cursor: widget.axis == SplitAxis.horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        key: const ValueKey<String>('splitLayoutDivider'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: widget.axis == SplitAxis.horizontal
            ? (details) => _onDragUpdate(details, available)
            : null,
        onVerticalDragUpdate: widget.axis == SplitAxis.vertical
            ? (details) => _onDragUpdate(details, available)
            : null,
        child: visualDivider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = widget.axis == SplitAxis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        final panel0Visible = _effectiveController.isPanelVisible(0);
        final panel1Visible = _effectiveController.isPanelVisible(1);

        if (!panel0Visible && !panel1Visible) {
          if (!widget.panels[0].keepAlive && !widget.panels[1].keepAlive) {
            return const SizedBox.shrink();
          }

          return Offstage(
            offstage: true,
            child: TickerMode(
              enabled: false,
              child: Stack(
                children: <Widget>[
                  if (widget.panels[0].keepAlive)
                    _buildPanelContent(0, widget.panels[0]),
                  if (widget.panels[1].keepAlive)
                    _buildPanelContent(1, widget.panels[1]),
                ],
              ),
            ),
          );
        }

        final bothVisible = panel0Visible && panel1Visible;

        final dividerTo = bothVisible ? _dividerHitSize : 0.0;
        final availableTo = total - dividerTo;

        late final double panel0To;
        late final double panel1To;
        if (bothVisible) {
          final primarySize = _primarySize(availableTo);
          final secondarySize = availableTo - primarySize;
          panel0To = _primaryIndex == 0 ? primarySize : secondarySize;
          panel1To = _primaryIndex == 0 ? secondarySize : primarySize;
        } else {
          panel0To = panel0Visible ? total : 0.0;
          panel1To = panel1Visible ? total : 0.0;
        }

        Widget buildWithSizes({
          required double panel0Size,
          required double dividerSize,
          required double panel1Size,
        }) {
          final dividerSlot = ClipRect(
            child: widget.axis == SplitAxis.horizontal
                ? SizedBox(
                    width: dividerSize,
                    child: _buildDivider(availableTo, enabled: bothVisible),
                  )
                : SizedBox(
                    height: dividerSize,
                    child: _buildDivider(availableTo, enabled: bothVisible),
                  ),
          );

          final children = <Widget>[
            _buildPanelWithVisibility(
              0,
              widget.panels[0],
              panel0Size,
              visible: panel0Visible,
            ),
            dividerSlot,
            _buildPanelWithVisibility(
              1,
              widget.panels[1],
              panel1Size,
              visible: panel1Visible,
            ),
          ];

          return widget.axis == SplitAxis.horizontal
              ? Row(children: children)
              : Column(children: children);
        }

        if (_visibilityAnimating) {
          final t = _visibilityAnimation.value;
          return buildWithSizes(
            panel0Size: lerpDouble(_fromPanel0Size, panel0To, t) ?? panel0To,
            dividerSize: lerpDouble(_fromDividerSize, dividerTo, t) ?? dividerTo,
            panel1Size: lerpDouble(_fromPanel1Size, panel1To, t) ?? panel1To,
          );
        }

        _currentPanel0Size = panel0To;
        _currentDividerSize = dividerTo;
        _currentPanel1Size = panel1To;
        return buildWithSizes(
          panel0Size: panel0To,
          dividerSize: dividerTo,
          panel1Size: panel1To,
        );
      },
    );
  }
}
