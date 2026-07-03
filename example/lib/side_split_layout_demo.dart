import 'package:flutter/material.dart';
import 'package:desktop_widgets/desktop_widgets.dart';

class SideSplitLayoutDemo extends StatefulWidget {
  const SideSplitLayoutDemo({super.key});

  @override
  State<SideSplitLayoutDemo> createState() => _SideSplitLayoutDemoState();
}

class _SideSplitLayoutDemoState extends State<SideSplitLayoutDemo> {
  int? _selectedIndex = 0;

  static const List<String> _labels = <String>[
    'Search',
    'Settings',
    'Notification',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SideSplitLayout(
      sideWidth: 64,
      panelWidth: 280,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      panelAnimationDuration: const Duration(milliseconds: 200),
      panelAnimationCurve: Curves.easeOutCubic,
      selectedIndex: _selectedIndex,
      onSelectedIndexChanged: (index) => setState(() => _selectedIndex = index),
      panels: <SidePanel>[
        SidePanel(
          button: const Icon(Icons.search),
          tooltip: 'Search',
          keepAlive: true,
          panel: const _SearchDraftPanel(),
        ),
        SidePanel(
          button: const Icon(Icons.settings),
          tooltip: 'Settings',
          panel: _buildPanel(
            color: theme.colorScheme.secondaryContainer,
            title: 'Settings panel',
            description: 'Adjust settings here.',
          ),
        ),
        SidePanel(
          button: const Icon(Icons.notifications),
          tooltip: 'Notification',
          panel: _buildPanel(
            color: theme.colorScheme.tertiaryContainer,
            title: 'Notification panel',
            description: 'View recent notifications.',
          ),
        ),
      ],
      extraButtons: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'New',
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(content: Text('<New> button clicked.')),
            );
          },
        ),
      ],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Main area', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Current selection: ${_selectedIndex != null ? _labels[_selectedIndex!] : 'None'}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  child: const Text('Select Search'),
                ),
                FilledButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('Select Settings'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _selectedIndex = null),
                  child: const Text('Hide Panel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Search panel keeps its draft when reopened.',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Switch from Search to Settings to see the width animate continuously from A to B.',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Use the external buttons to verify controlled mode stays stable during animation.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(description),
        ],
      ),
    );
  }
}

class _SearchDraftPanel extends StatefulWidget {
  const _SearchDraftPanel();

  @override
  State<_SearchDraftPanel> createState() => _SearchDraftPanelState();
}

class _SearchDraftPanelState extends State<_SearchDraftPanel> {
  final TextEditingController _controller = TextEditingController(
    text: 'Keep this draft',
  );

  bool _includeTitles = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Search panel', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Draft query',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeTitles,
              title: const Text('Include titles'),
              onChanged: (value) => setState(() => _includeTitles = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Close the panel and open it again to confirm the draft and switch state are preserved.',
            ),
          ],
        ),
      ),
    );
  }
}
