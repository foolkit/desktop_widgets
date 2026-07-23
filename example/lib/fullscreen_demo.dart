import 'package:desktop_widgets/desktop_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

abstract class FullscreenSystemAdapter extends ChangeNotifier {
  bool get isSupported;

  bool get isFullscreen;

  Future<void> initialize();

  Future<void> setFullscreen(bool isFullscreen);
}

class WindowManagerFullscreenSystemAdapter extends FullscreenSystemAdapter
    with WindowListener {
  bool _isFullscreen = false;
  bool _isInitialized = false;
  bool _isRegistered = false;

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;
    _isInitialized = true;
    windowManager.addListener(this);
    _isRegistered = true;
    await _refreshState();
  }

  @override
  Future<void> setFullscreen(bool isFullscreen) async {
    if (!isSupported) return;
    await windowManager.setFullScreen(isFullscreen);
    await _refreshState();
  }

  @override
  void onWindowEnterFullScreen() {
    _updateFullscreen(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    _updateFullscreen(false);
  }

  Future<void> _refreshState() async {
    _updateFullscreen(await windowManager.isFullScreen());
  }

  void _updateFullscreen(bool value) {
    if (_isFullscreen == value) return;
    _isFullscreen = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isRegistered) {
      windowManager.removeListener(this);
      _isRegistered = false;
    }
    super.dispose();
  }
}

class FullscreenDemo extends StatefulWidget {
  const FullscreenDemo({super.key, this.systemFullscreenAdapter});

  final FullscreenSystemAdapter? systemFullscreenAdapter;

  @override
  State<FullscreenDemo> createState() => _FullscreenDemoState();
}

class _FullscreenDemoState extends State<FullscreenDemo> {
  static const String _previewIdentifier = 'example-fullscreen-preview';
  static const List<_WorkspaceSpace> _spaces = <_WorkspaceSpace>[
    _WorkspaceSpace(
      title: 'Inbox Review',
      summary: 'Clear incoming requests and turn blockers into actionable notes.',
      badge: '12 updates',
      icon: Icons.inbox_outlined,
    ),
    _WorkspaceSpace(
      title: 'Launch Notes',
      summary: 'Track release notes, copy review, and the final launch checklist.',
      badge: 'Ready to ship',
      icon: Icons.rocket_launch_outlined,
    ),
    _WorkspaceSpace(
      title: 'Retention Board',
      summary: 'Compare experiments and keep the weekly retention brief focused.',
      badge: '3 experiments',
      icon: Icons.insights_outlined,
    ),
    _WorkspaceSpace(
      title: 'Design QA',
      summary: 'Review interaction polish and capture the last visual adjustments.',
      badge: '5 review items',
      icon: Icons.design_services_outlined,
    ),
  ];
  static const List<_WorkspaceMetric> _metrics = <_WorkspaceMetric>[
    _WorkspaceMetric(
      title: 'Messages',
      value: '18',
      detail: 'Unread messages need triage before the next planning sync.',
      icon: Icons.mail_outline,
    ),
    _WorkspaceMetric(
      title: 'Drafts',
      value: '5',
      detail: 'Draft content is ready for review and final copy polish.',
      icon: Icons.edit_note,
    ),
    _WorkspaceMetric(
      title: 'Approvals',
      value: '2',
      detail: 'Two approvals are blocking the linked fullscreen launch checklist.',
      icon: Icons.fact_check_outlined,
    ),
  ];

  late final FullscreenController _controller;
  late FullscreenSystemAdapter _systemAdapter;
  bool _ownsSystemAdapter = false;
  bool _isSyncingSystemChange = false;
  bool _isSyncingOverlayChange = false;
  bool _isApplyingSystemChange = false;
  _WorkspaceSpace _activeSpace = _spaces.first;
  _WorkspaceMetric _activeMetric = _metrics.first;

  bool get _overlayFullscreen => _controller.isFullscreen;

  bool get _systemSupported => _systemAdapter.isSupported;

  bool get _systemFullscreen => _systemAdapter.isFullscreen;

  @override
  void initState() {
    super.initState();
    _controller = FullscreenController()..addListener(_handleOverlayChanged);
    _attachSystemAdapter(widget.systemFullscreenAdapter);
  }

  @override
  void didUpdateWidget(covariant FullscreenDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.systemFullscreenAdapter != widget.systemFullscreenAdapter) {
      _detachSystemAdapter();
      _attachSystemAdapter(widget.systemFullscreenAdapter);
    }
  }

  @override
  void dispose() {
    _detachSystemAdapter();
    _controller
      ..removeListener(_handleOverlayChanged)
      ..dispose();
    super.dispose();
  }

  void _attachSystemAdapter(FullscreenSystemAdapter? adapter) {
    _systemAdapter = adapter ?? WindowManagerFullscreenSystemAdapter();
    _ownsSystemAdapter = adapter == null;
    _systemAdapter.addListener(_handleSystemChanged);
    _initializeSystemAdapter(_systemAdapter);
  }

  void _detachSystemAdapter() {
    _systemAdapter.removeListener(_handleSystemChanged);
    if (_ownsSystemAdapter) {
      _systemAdapter.dispose();
    }
  }

  Future<void> _initializeSystemAdapter(FullscreenSystemAdapter adapter) async {
    await adapter.initialize();
    if (!mounted || !identical(adapter, _systemAdapter)) return;
    _applySystemState(adapter.isFullscreen);
  }

  void _handleSystemChanged() {
    _applySystemState(_systemAdapter.isFullscreen);
  }

  void _applySystemState(bool isFullscreen) {
    if (!_systemSupported || _isSyncingOverlayChange) {
      return;
    }

    final needsSync = isFullscreen != _controller.isFullscreen;
    if (!needsSync) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isSyncingOverlayChange) return;

      _isSyncingSystemChange = true;
      try {
        if (isFullscreen && !_controller.isFullscreen) {
          _controller.show(_previewIdentifier);
        } else if (!isFullscreen && _controller.isFullscreen) {
          _controller.hide();
        }
      } finally {
        _isSyncingSystemChange = false;
      }
    });
  }

  void _handleOverlayChanged() {
    if (!_systemSupported || _isSyncingSystemChange || _isApplyingSystemChange) {
      return;
    }

    if (_overlayFullscreen || !_systemFullscreen) {
      return;
    }

    _syncSystemToOverlay(false);
  }

  Future<void> _syncSystemToOverlay(bool isFullscreen) async {
    if (!_systemSupported) return;
    if (_systemAdapter.isFullscreen == isFullscreen && !_isApplyingSystemChange) {
      return;
    }

    setState(() {
      _isApplyingSystemChange = true;
    });

    _isSyncingOverlayChange = true;
    try {
      await _systemAdapter.setFullscreen(isFullscreen);
      if (!mounted) return;
      _applySystemState(_systemAdapter.isFullscreen);
    } finally {
      _isSyncingOverlayChange = false;
      if (mounted) {
        setState(() {
          _isApplyingSystemChange = false;
        });
      }
    }
  }

  Future<void> _enterLinkedFullscreen() async {
    if (!_systemSupported) {
      _controller.show(_previewIdentifier);
      return;
    }

    await _setLinkedFullscreen(true);
  }

  Future<void> _exitFullscreen() async {
    if (!_systemSupported) {
      _controller.hide();
      return;
    }

    await _setLinkedFullscreen(false);
  }

  Future<void> _setLinkedFullscreen(bool isFullscreen) async {
    if (_isApplyingSystemChange) return;

    setState(() {
      _isApplyingSystemChange = true;
    });

    _isSyncingOverlayChange = true;
    try {
      await _systemAdapter.setFullscreen(isFullscreen);
      if (!mounted) return;

      if (isFullscreen) {
        _controller.show(_previewIdentifier);
      } else {
        _controller.hide();
      }
    } finally {
      _isSyncingOverlayChange = false;
      if (mounted) {
        setState(() {
          _isApplyingSystemChange = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_controller, _systemAdapter]),
      builder: (BuildContext context, Widget? child) {
        return FullscreenScope(
          controller: _controller,
          padding: EdgeInsets.zero,
          dismissOnBarrierTap: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final useTwoColumns = constraints.maxWidth >= 1120;

                return ListView(
                  children: <Widget>[
                    Text('Fullscreen', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Text(
                      'Preview how the package overlay and desktop window fullscreen can stay in sync without coupling the core library to window_manager.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The workspace preview below remains available on every platform. On desktop, the demo also drives the native window fullscreen state.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (!_systemSupported) ...<Widget>[
                      const SizedBox(height: 24),
                      _buildFallbackNotice(theme),
                    ],
                    const SizedBox(height: 24),
                    if (useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 320,
                            child: Column(
                              children: <Widget>[
                                _buildStatusCard(theme),
                                const SizedBox(height: 24),
                                _buildActionCard(theme),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: _buildPreviewTarget(theme, compact: false)),
                        ],
                      )
                    else ...<Widget>[
                      _buildStatusCard(theme),
                      const SizedBox(height: 24),
                      _buildPreviewTarget(theme, compact: true),
                      const SizedBox(height: 24),
                      _buildActionCard(theme),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackNotice(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'System fullscreen is unavailable on this platform. Use the in-app overlay preview instead.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final statusItems = <Widget>[
      _buildStatusItem(
        theme,
        icon: _systemSupported ? Icons.desktop_windows : Icons.phone_android,
        label: 'Platform',
        value: _systemSupported ? 'Desktop window_manager' : 'Overlay fallback',
      ),
      _buildStatusItem(
        theme,
        icon: _systemFullscreen ? Icons.fullscreen : Icons.aspect_ratio,
        label: 'System Window',
        value: _systemSupported
            ? (_systemFullscreen ? 'Fullscreen' : 'Windowed')
            : 'Unavailable',
      ),
      _buildStatusItem(
        theme,
        icon: _overlayFullscreen ? Icons.layers : Icons.layers_outlined,
        label: 'App Overlay',
        value: _overlayFullscreen ? 'Fullscreen' : 'Windowed',
      ),
      _buildStatusItem(
        theme,
        icon: _activeSpace.icon,
        label: 'Focused space',
        value: _activeSpace.title,
      ),
      _buildStatusItem(
        theme,
        icon: _activeMetric.icon,
        label: 'Focus metric',
        value: _activeMetric.title,
      ),
      _buildStatusItem(
        theme,
        icon: _systemSupported ? Icons.sync : Icons.warning_amber_rounded,
        label: 'Sync Status',
        value: _systemSupported
            ? (_isApplyingSystemChange ? 'Syncing...' : 'Linked')
            : 'Preview only',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Status Panel', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Track the current desktop window state and the package overlay state separately.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...statusItems,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTarget(ThemeData theme, {required bool compact}) {
    return FullscreenTarget(
      identifier: _previewIdentifier,
      fullscreenBuilder: (BuildContext context) => _buildFullscreenPreview(context),
      child: _buildPreviewCard(theme, compact: compact),
    );
  }

  Widget _buildPreviewCard(ThemeData theme, {required bool compact}) {
    final previewHeight = compact ? 520.0 : 600.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox(
          height: previewHeight,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.space_dashboard_outlined, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Workspace Canvas',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    _buildBadge(theme, _systemSupported ? 'Linked ready' : 'Overlay only'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Switch the focused space and metrics to preview how the fullscreen surface behaves like a real desktop workbench.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildWorkspacePreview(
                    theme,
                    compact: compact,
                    immersive: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(ThemeData theme) {
    final primaryLabel =
        _systemSupported ? 'Enter Linked Fullscreen' : 'Open Overlay Preview';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _systemSupported
                  ? 'Enter linked fullscreen to switch both the desktop window and the package overlay together.'
                  : 'Use the overlay preview action to validate the package fullscreen experience on unsupported platforms.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _isApplyingSystemChange ? null : _enterLinkedFullscreen,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(primaryLabel),
                ),
                OutlinedButton.icon(
                  onPressed: _overlayFullscreen || _systemFullscreen
                      ? _exitFullscreen
                      : null,
                  icon: const Icon(Icons.fullscreen_exit),
                  label: Text(
                    _systemSupported
                        ? 'Exit Linked Fullscreen'
                        : 'Exit Overlay Preview',
                  ),
                ),
              ],
            ),
            if (_isApplyingSystemChange) ...<Widget>[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenPreview(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      key: const ValueKey<String>('fullscreen-demo-overlay-surface'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.fullscreen, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fullscreen Workspace',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  _buildBadge(theme, _systemSupported ? 'Window linked' : 'Overlay preview'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _systemSupported
                    ? 'The desktop window and overlay stay linked while the workspace stretches edge-to-edge.'
                    : 'The system window stays untouched here, but the overlay still expands into a full workspace surface.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildWorkspacePreview(
                  theme,
                  compact: false,
                  immersive: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspacePreview(
    ThemeData theme, {
    required bool compact,
    required bool immersive,
  }) {
    if (compact) {
      return _buildCompactWorkspacePreview(theme, immersive: immersive);
    }

    final sidebarWidth = compact ? 208.0 : 244.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.menu),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Campaign Planner',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _buildBadge(theme, immersive ? 'Fullscreen active' : 'Sync ready'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: sidebarWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Spaces', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            ..._spaces.map(
                              (_WorkspaceSpace space) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSpaceTile(theme, space: space),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              immersive
                                  ? 'Tap any space to keep the fullscreen workspace interactive.'
                                  : 'The compact preview mirrors the same navigation and focus state.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Focused space',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Focus: ${_activeSpace.title}',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _activeSpace.summary,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _metrics
                              .map(
                                (_WorkspaceMetric metric) => _buildPreviewMetricCard(
                                  theme,
                                  metric: metric,
                                  compact: compact,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Icon(Icons.visibility_outlined),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _activeMetric.title,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      _buildBadge(theme, _activeSpace.badge),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activeMetric.detail,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.35 + (_metrics.indexOf(_activeMetric) * 0.2),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    immersive
                                        ? 'Use the buttons above, the close button, or Esc to exit linked fullscreen.'
                                        : 'Use the action buttons to switch between overlay-only and linked desktop fullscreen modes.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWorkspacePreview(
    ThemeData theme, {
    required bool immersive,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.menu),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Campaign Planner',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildBadge(theme, immersive ? 'Fullscreen active' : 'Sync ready'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Spaces', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _spaces
                          .map(
                            (_WorkspaceSpace space) => SizedBox(
                              width: 164,
                              child: _buildSpaceTile(theme, space: space),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Focused space',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Focus: ${_activeSpace.title}',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _activeSpace.summary,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _metrics.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int index) {
                          return _buildPreviewMetricCard(
                            theme,
                            metric: _metrics[index],
                            compact: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.visibility_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _activeMetric.title,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                _buildBadge(theme, _activeSpace.badge),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _activeMetric.detail,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.35 + (_metrics.indexOf(_activeMetric) * 0.2),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Compact preview keeps the same interactions without forcing a cramped split-pane layout.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewMetricCard(
    ThemeData theme, {
    required _WorkspaceMetric metric,
    required bool compact,
  }) {
    final selected = identical(metric, _activeMetric);
    final width = compact ? 156.0 : 196.0;
    final contentPadding = compact ? 12.0 : 16.0;
    final iconSpacing = compact ? 12.0 : 16.0;
    final valueSpacing = compact ? 6.0 : 8.0;
    final valueStyle = compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall;

    return SizedBox(
      width: width,
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectMetric(metric),
          child: Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(metric.icon, color: selected ? theme.colorScheme.primary : null),
                SizedBox(height: iconSpacing),
                Text(metric.title, style: theme.textTheme.bodyMedium),
                SizedBox(height: valueSpacing),
                Text(metric.value, style: valueStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectSpace(_WorkspaceSpace space) {
    if (identical(space, _activeSpace)) return;
    setState(() {
      _activeSpace = space;
    });
  }

  void _selectMetric(_WorkspaceMetric metric) {
    if (identical(metric, _activeMetric)) return;
    setState(() {
      _activeMetric = metric;
    });
  }

  Widget _buildSpaceTile(
    ThemeData theme, {
    required _WorkspaceSpace space,
  }) {
    final selected = identical(space, _activeSpace);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectSpace(space),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.play_arrow_rounded : space.icon,
                size: 18,
                color: selected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  space.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected ? theme.colorScheme.primary : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label, style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _WorkspaceSpace {
  const _WorkspaceSpace({
    required this.title,
    required this.summary,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String summary;
  final String badge;
  final IconData icon;
}

class _WorkspaceMetric {
  const _WorkspaceMetric({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
}
