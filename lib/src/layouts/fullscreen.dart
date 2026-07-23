import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全屏内容的构建器。
typedef FullscreenBuilder = Widget Function(BuildContext context);

/// 控制 [FullscreenScope] 内当前全屏目标的控制器。
class FullscreenController extends ChangeNotifier {
  Object? _activeIdentifier;

  /// 当前处于全屏状态的目标标识。
  Object? get activeIdentifier => _activeIdentifier;

  /// 当前是否存在激活的全屏目标。
  bool get isFullscreen => _activeIdentifier != null;

  /// 显示指定标识的全屏目标。
  void show(Object identifier) {
    if (_activeIdentifier == identifier) return;
    _activeIdentifier = identifier;
    notifyListeners();
  }

  /// 退出当前全屏。
  void hide() {
    if (_activeIdentifier == null) return;
    _activeIdentifier = null;
    notifyListeners();
  }

  /// 切换指定目标的全屏状态。
  void toggle(Object identifier) {
    if (_activeIdentifier == identifier) {
      hide();
      return;
    }
    show(identifier);
  }
}

/// 为其子树提供应用内全屏能力，并通过 [OverlayEntry] 托管全屏层。
class FullscreenScope extends StatefulWidget {
  const FullscreenScope({
    super.key,
    required this.child,
    this.controller,
    this.barrierColor = const Color(0xCC000000),
    this.padding = const EdgeInsets.all(24),
    this.dismissOnBarrierTap = false,
    this.dismissOnEscape = true,
    this.showCloseButton = true,
    this.closeButtonTooltip = 'Exit fullscreen',
  });

  /// 常驻子树。
  final Widget child;

  /// 外部控制器；不传时自动创建内部控制器。
  final FullscreenController? controller;

  /// 全屏层遮罩颜色。
  final Color barrierColor;

  /// 全屏内容与边缘的内边距。
  final EdgeInsetsGeometry padding;

  /// 点击遮罩时是否退出全屏。
  final bool dismissOnBarrierTap;

  /// 是否支持按 `Esc` 键退出。
  final bool dismissOnEscape;

  /// 是否显示右上角关闭按钮。
  final bool showCloseButton;

  /// 关闭按钮提示文案。
  final String closeButtonTooltip;

  /// 获取当前作用域中的 [FullscreenController]。
  static FullscreenController of(BuildContext context, {bool listen = false}) {
    final controller = maybeOf(context, listen: listen);
    if (controller != null) return controller;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('未在当前上下文中找到 FullscreenScope。'),
      ErrorDescription('请确保调用发生在 FullscreenScope 子树内，或者显式传入控制器。'),
    ]);
  }

  /// 尝试获取当前作用域中的 [FullscreenController]。
  static FullscreenController? maybeOf(
    BuildContext context, {
    bool listen = false,
  }) {
    final inherited = _inheritedOf(context, listen: listen);
    return inherited?.controller;
  }

  static _FullscreenScopeState? _maybeStateOf(BuildContext context) {
    return _inheritedOf(context, listen: false)?.state;
  }

  static _FullscreenScopeInherited? _inheritedOf(
    BuildContext context, {
    required bool listen,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<_FullscreenScopeInherited>();
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<_FullscreenScopeInherited>();
    return element?.widget as _FullscreenScopeInherited?;
  }

  @override
  State<FullscreenScope> createState() => _FullscreenScopeState();
}

class _FullscreenScopeState extends State<FullscreenScope> {
  late final FullscreenController _internalController;
  late final FocusNode _focusNode;
  final Map<Object, _FullscreenTargetState> _targets =
      <Object, _FullscreenTargetState>{};

  OverlayEntry? _overlayEntry;

  FullscreenController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = FullscreenController();
    _focusNode = FocusNode(debugLabel: 'FullscreenScopeOverlay');
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FullscreenScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController).removeListener(
        _handleControllerChanged,
      );
      _effectiveController.addListener(_handleControllerChanged);
      _syncOverlay();
    } else if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    _removeOverlay();
    _focusNode.dispose();
    _internalController.dispose();
    super.dispose();
  }

  void _register(_FullscreenTargetState target) {
    _targets[target.widget.identifier] = target;
    _syncOverlay();
  }

  void _unregister(_FullscreenTargetState target, Object identifier) {
    if (identical(_targets[identifier], target)) {
      _targets.remove(identifier);
      _syncOverlay();
    }
  }

  void _moveRegistration(Object oldIdentifier, _FullscreenTargetState target) {
    if (identical(_targets[oldIdentifier], target)) {
      _targets.remove(oldIdentifier);
    }
    _targets[target.widget.identifier] = target;
    _syncOverlay();
  }

  void _handleControllerChanged() {
    _syncOverlay();
  }

  void _syncOverlay() {
    final activeIdentifier = _effectiveController.activeIdentifier;
    final activeTarget = activeIdentifier == null
        ? null
        : _targets[activeIdentifier];

    if (activeTarget == null) {
      _removeOverlay();
      if (activeIdentifier != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_effectiveController.activeIdentifier == activeIdentifier &&
              !_targets.containsKey(activeIdentifier)) {
            _effectiveController.hide();
          }
        });
      }
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      overlay.insert(_overlayEntry!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.canRequestFocus) return;
        _focusNode.requestFocus();
      });
      return;
    }
    _overlayEntry!.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.canRequestFocus) return;
      _focusNode.requestFocus();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final activeIdentifier = _effectiveController.activeIdentifier;
    final activeTarget = activeIdentifier == null
        ? null
        : _targets[activeIdentifier];

    if (activeTarget == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Material(
        color: widget.barrierColor,
        child: SafeArea(
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              if (!widget.dismissOnEscape) {
                return KeyEventResult.ignored;
              }
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _effectiveController.hide();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.dismissOnBarrierTap
                        ? _effectiveController.hide
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: widget.padding,
                    child: Center(child: activeTarget.buildFullscreen(context)),
                  ),
                ),
                if (widget.showCloseButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      tooltip: widget.closeButtonTooltip,
                      onPressed: _effectiveController.hide,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FullscreenScopeInherited(
      controller: _effectiveController,
      state: this,
      child: widget.child,
    );
  }
}

/// 注册一个可被 [FullscreenController] 激活的目标组件。
class FullscreenTarget extends StatefulWidget {
  const FullscreenTarget({
    super.key,
    required this.identifier,
    required this.child,
    this.fullscreenChild,
    this.fullscreenBuilder,
  }) : assert(
         fullscreenChild == null || fullscreenBuilder == null,
         'fullscreenChild and fullscreenBuilder cannot both be provided',
       );

  /// 目标标识；需与控制器中的标识对应。
  final Object identifier;

  /// 常规布局下展示的内容。
  final Widget child;

  /// 全屏时展示的静态内容。
  final Widget? fullscreenChild;

  /// 全屏时的动态构建器；优先级高于 [fullscreenChild]。
  final FullscreenBuilder? fullscreenBuilder;

  @override
  State<FullscreenTarget> createState() => _FullscreenTargetState();
}

class _FullscreenTargetState extends State<FullscreenTarget> {
  _FullscreenScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = FullscreenScope._maybeStateOf(context);
    if (_scope == nextScope) return;
    _scope?._unregister(this, widget.identifier);
    _scope = nextScope;
    _scope?._register(this);
  }

  @override
  void didUpdateWidget(covariant FullscreenTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scope == null) return;
    if (oldWidget.identifier != widget.identifier) {
      _scope!._moveRegistration(oldWidget.identifier, this);
      return;
    }
    _scope!._register(this);
  }

  @override
  void dispose() {
    _scope?._unregister(this, widget.identifier);
    super.dispose();
  }

  Widget buildFullscreen(BuildContext context) {
    if (widget.fullscreenBuilder != null) {
      return widget.fullscreenBuilder!(context);
    }
    return widget.fullscreenChild ?? widget.child;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FullscreenScopeInherited extends InheritedWidget {
  const _FullscreenScopeInherited({
    required this.controller,
    required this.state,
    required super.child,
  });

  final FullscreenController controller;
  final _FullscreenScopeState state;

  @override
  bool updateShouldNotify(covariant _FullscreenScopeInherited oldWidget) {
    return oldWidget.controller != controller || oldWidget.state != state;
  }
}
