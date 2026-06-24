import 'package:flutter/material.dart';
import 'package:desktop_widgets/desktop_widgets.dart';

class SideSplitLayoutDemo extends StatefulWidget {
  const SideSplitLayoutDemo({super.key});

  @override
  State<SideSplitLayoutDemo> createState() => _SideSplitLayoutDemoState();
}

class _SideSplitLayoutDemoState extends State<SideSplitLayoutDemo> {
  int? _selectedIndex;

  static const List<String> _labels = <String>['Search', 'Settings', 'Notification'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SideSplitLayout(
      sideWidth: 64,
      panelWidth: 280,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      onSelectedIndexChanged: (index) => setState(() => _selectedIndex = index),
      panels: <SidePanel>[
        SidePanel(
          button: const Icon(Icons.search),
          tooltip: 'Search',
          panel: _buildPanel(
            color: theme.colorScheme.primaryContainer,
            title: 'Search panel',
            description: 'Search here',
          ),
        ),
        SidePanel(
          button: const Icon(Icons.settings),
          tooltip: 'Settings',
          panel: _buildPanel(
            color: theme.colorScheme.secondaryContainer,
            title: 'Settins panel',
            description: 'Adjusting settings here',
          ),
        ),
        SidePanel(
          button: const Icon(Icons.notifications),
          tooltip: 'Notification',
          panel: _buildPanel(
            color: theme.colorScheme.tertiaryContainer,
            title: 'Notification panel',
            description: 'View recent notifications',
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
            Text(
              'Main area',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Current selection：${_selectedIndex != null ? _labels[_selectedIndex!] : 'None'}',
              style: theme.textTheme.bodyLarge,
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
