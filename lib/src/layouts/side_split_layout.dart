import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 主分栏在整体布局中的位置。
enum SideSplitMainPosition {
  /// 主分栏在左侧，顺序：主分栏、副分栏、侧栏按钮。
  start,

  /// 主分栏在右侧，顺序：侧栏按钮、副分栏、主分栏。
  end,
}

/// 一个可配置的面板项，用于 [SideSplitLayout]。
class SidePanel {
  const SidePanel({required this.button, required this.panel, this.tooltip});

  /// 显示在侧边按钮栏中的组件。
  final Widget button;

  /// 当该面板激活时显示在副分栏中的组件。
  final Widget panel;

  /// 悬停在按钮上时显示的提示文本。
  final String? tooltip;
}

/// 左右分栏布局组件。
///
/// 包含常驻的主分栏、可通过侧边按钮激活的副分栏，以及侧边按钮栏。
/// 同一时刻最多只有一个副分栏显示；再次点击已激活的按钮可关闭该面板。
/// 每个副分栏的宽度可以通过拖拽分隔线单独调整。
class SideSplitLayout extends StatefulWidget {
  const SideSplitLayout({
    super.key,
    required this.child,
    this.panels = const <SidePanel>[],
    this.extraButtons = const <Widget>[],
    this.mainPosition = SideSplitMainPosition.start,
    this.sideWidth = 56,
    this.panelWidth = 250,
    this.minPanelWidth = 120,
    this.maxPanelWidth,
    this.dividerWidth = 1,
    this.dividerColor,
    this.backgroundColor,
    this.initialSelectedIndex,
    this.selectedIndex,
    this.onSelectedIndexChanged,
  }) : assert(
          selectedIndex == null || initialSelectedIndex == null,
          'Do not provide both selectedIndex and initialSelectedIndex. '
          'Use selectedIndex for controlled mode, or initialSelectedIndex for uncontrolled mode.',
        );

  /// 主分栏内容，始终显示。
  final Widget child;

  /// 副分栏列表，每个面板通过一个侧边按钮控制显示或隐藏。
  final List<SidePanel> panels;

  /// 附加在面板按钮下方的其他按钮或组件。
  final List<Widget> extraButtons;

  /// 主分栏的位置，默认 [SideSplitMainPosition.start]。
  final SideSplitMainPosition mainPosition;

  /// 侧边按钮栏的宽度。
  final double sideWidth;

  /// 副分栏的默认宽度。
  final double panelWidth;

  /// 副分栏允许的最小宽度。
  final double minPanelWidth;

  /// 副分栏允许的最大宽度，不设置时受父布局约束限制。
  final double? maxPanelWidth;

  /// 分隔线的宽度。
  final double dividerWidth;

  /// 分隔线颜色，默认为 [ThemeData.dividerColor]。
  final Color? dividerColor;

  /// 侧边按钮栏背景色。
  final Color? backgroundColor;

  /// 非受控模式下初始激活的副分栏索引。
  ///
  /// 仅在 [selectedIndex] 为 null 时生效。
  final int? initialSelectedIndex;

  /// 受控模式下当前激活的副分栏索引。
  final int? selectedIndex;

  /// 当激活的副分栏索引变化时调用。
  final ValueChanged<int?>? onSelectedIndexChanged;

  @override
  State<SideSplitLayout> createState() => _SideSplitLayoutState();
}

class _SideSplitLayoutState extends State<SideSplitLayout> {
  int? _selectedIndex;
  int? _interactionIndex;
  final Map<int, double> _panelWidths = <int, double>{};

  int? get _effectiveIndex => widget.selectedIndex ?? _selectedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex == null) {
      _selectedIndex = widget.initialSelectedIndex;
    }
    _interactionIndex = _effectiveIndex;
  }

  @override
  void didUpdateWidget(covariant SideSplitLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _interactionIndex = widget.selectedIndex;
    }
  }

  void _togglePanel(int index) {
    final current = _interactionIndex ?? _effectiveIndex;
    final next = current == index ? null : index;
    _interactionIndex = next;

    if (widget.selectedIndex == null) {
      setState(() => _selectedIndex = next);
    }
    widget.onSelectedIndexChanged?.call(next);
  }

  double _widthFor(int index, double maxAvailable) {
    final width = _panelWidths.putIfAbsent(index, () => widget.panelWidth);
    return width.clamp(widget.minPanelWidth, maxAvailable);
  }

  void _updatePanelWidth(int index, double delta, double maxAvailable) {
    final current = _panelWidths.putIfAbsent(index, () => widget.panelWidth);
    final next = (current + delta).clamp(widget.minPanelWidth, maxAvailable);
    if (next != current) {
      setState(() => _panelWidths[index] = next);
    }
  }

  Widget _buildSideButton(int index, SidePanel panel, bool selected) {
    final theme = Theme.of(context);
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _togglePanel(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.sideWidth,
          height: widget.sideWidth,
          color: selected
              ? theme.highlightColor.withValues(alpha: 0.4)
              : Colors.transparent,
          alignment: Alignment.center,
          child: panel.button,
        ),
      ),
    );

    if (panel.tooltip == null) return button;
    return Tooltip(message: panel.tooltip, child: button);
  }

  Widget _buildResizeHandle(int index, double maxAvailable) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        key: const ValueKey<String>('sideSplitLayoutResizer'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          final direction = widget.mainPosition == SideSplitMainPosition.start
              ? -1.0
              : 1.0;
          _updatePanelWidth(index, details.delta.dx * direction, maxAvailable);
        },
        child: VerticalDivider(
          width: 8,
          thickness: widget.dividerWidth,
          color: widget.dividerColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _effectiveIndex;

    final sideBar = Container(
      width: widget.sideWidth,
      color: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < widget.panels.length; i++)
            _buildSideButton(i, widget.panels[i], selected == i),
          if (widget.extraButtons.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            for (final button in widget.extraButtons) button,
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPanelWidth = widget.maxPanelWidth == null
            ? math.max(
                widget.minPanelWidth,
                constraints.maxWidth - widget.sideWidth - 8,
              )
            : math.min(
                widget.maxPanelWidth!,
                math.max(
                  widget.minPanelWidth,
                  constraints.maxWidth - widget.sideWidth - 8,
                ),
              );

        final panel =
            selected != null && selected >= 0 && selected < widget.panels.length
            ? SizedBox(
                key: ValueKey<int>(selected),
                width: _widthFor(selected, maxPanelWidth),
                child: widget.panels[selected].panel,
              )
            : null;

        final resizeHandle = panel != null
            ? _buildResizeHandle(selected!, maxPanelWidth)
            : null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.mainPosition == SideSplitMainPosition.start
              ? <Widget>[
                  Expanded(child: widget.child),
                  ?resizeHandle,
                  ?panel,
                  sideBar,
                ]
              : <Widget>[
                  sideBar,
                  ?panel,
                  ?resizeHandle,
                  Expanded(child: widget.child),
                ],
        );
      },
    );
  }
}
