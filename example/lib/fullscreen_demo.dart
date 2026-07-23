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

  late final FullscreenController _controller;
  late FullscreenSystemAdapter _systemAdapter;
  bool _ownsSystemAdapter = false;
  bool _isSyncingSystemChange = false;
  bool _isSyncingOverlayChange = false;
  bool _isApplyingSystemChange = false;

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
          dismissOnBarrierTap: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final useTwoColumns = constraints.maxWidth >= 1100;

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
                          Expanded(child: _buildStatusCard(theme)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildPreviewTarget(theme)),
                        ],
                      )
                    else ...<Widget>[
                      _buildStatusCard(theme),
                      const SizedBox(height: 24),
                      _buildPreviewTarget(theme),
                    ],
                    const SizedBox(height: 24),
                    _buildActionCard(theme),
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
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPreviewTarget(ThemeData theme) {
    return FullscreenTarget(
      identifier: _previewIdentifier,
      fullscreenBuilder: (BuildContext context) => _buildFullscreenPreview(context),
      child: _buildPreviewCard(theme),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(minHeight: 320),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.preview, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Workspace Preview',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This area previews a mail-and-editor style desktop workspace so the fullscreen overlay has realistic content to expand.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildWorkspacePreview(theme, compact: true)),
          ],
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 760),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.primaryContainer,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(32),
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _systemSupported
                    ? 'The desktop window and the in-app overlay are now linked. Exit with the close button, Esc, or the action panel.'
                    : 'The system window stays untouched here, but the package overlay still demonstrates the fullscreen workspace layout.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildWorkspacePreview(theme, compact: false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspacePreview(ThemeData theme, {required bool compact}) {
    final sidebarWidth = compact ? 180.0 : 220.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
                  _buildBadge(theme, 'Sync Ready'),
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
                            ...<String>[
                              'Inbox Review',
                              'Launch Notes',
                              'Retention Board',
                              'Design QA',
                            ].map(
                              (String item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(Icons.chevron_right, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(item)),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              compact
                                  ? 'Compact preview'
                                  : 'Fullscreen preview keeps the same workspace',
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
                      children: <Widget>[
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text('Working Area', style: theme.textTheme.titleMedium),
                                      const Spacer(),
                                      _buildBadge(theme, '3 focus tasks'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: <Widget>[
                                        _buildPreviewMetricCard(
                                          theme,
                                          title: 'Messages',
                                          value: '18',
                                          icon: Icons.mail_outline,
                                        ),
                                        _buildPreviewMetricCard(
                                          theme,
                                          title: 'Drafts',
                                          value: '5',
                                          icon: Icons.edit_note,
                                        ),
                                        _buildPreviewMetricCard(
                                          theme,
                                          title: 'Approvals',
                                          value: '2',
                                          icon: Icons.fact_check_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: compact ? 120 : 150,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.visibility_outlined),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Live workspace preview',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Use the buttons above to switch between overlay-only and linked desktop fullscreen modes.',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
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

  Widget _buildPreviewMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
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
