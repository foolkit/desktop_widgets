import 'package:flutter/material.dart';
import 'package:desktop_widgets/desktop_widgets.dart';

class SplitLayoutDemo extends StatefulWidget {
  const SplitLayoutDemo({super.key});

  @override
  State<SplitLayoutDemo> createState() => _SplitLayoutDemoState();
}

class _SplitLayoutDemoState extends State<SplitLayoutDemo> {
  final SplitLayoutController _controller = SplitLayoutController();
  SplitAxis _axis = SplitAxis.horizontal;
  SplitSizeUnit _sizeUnit = SplitSizeUnit.proportional;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPanel(String title, Color color) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              SegmentedButton<SplitAxis>(
                selected: <SplitAxis>{_axis},
                onSelectionChanged: (selection) {
                  setState(() => _axis = selection.first);
                },
                segments: const <ButtonSegment<SplitAxis>>[
                  ButtonSegment(
                    value: SplitAxis.horizontal,
                    label: Text('水平'),
                  ),
                  ButtonSegment(
                    value: SplitAxis.vertical,
                    label: Text('垂直'),
                  ),
                ],
              ),
              SegmentedButton<SplitSizeUnit>(
                selected: <SplitSizeUnit>{_sizeUnit},
                onSelectionChanged: (selection) {
                  setState(() => _sizeUnit = selection.first);
                },
                segments: const <ButtonSegment<SplitSizeUnit>>[
                  ButtonSegment(
                    value: SplitSizeUnit.proportional,
                    label: Text('按比例'),
                  ),
                  ButtonSegment(
                    value: SplitSizeUnit.pixel,
                    label: Text('按像素'),
                  ),
                ],
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FilterChip(
                        label: const Text('分栏 0'),
                        selected: _controller.panel0Visible,
                        onSelected: (selected) {
                          _controller.setPanelVisible(0, selected);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('分栏 1'),
                        selected: _controller.panel1Visible,
                        onSelected: (selected) {
                          _controller.setPanelVisible(1, selected);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SplitLayout(
              axis: _axis,
              sizeUnit: _sizeUnit,
              controller: _controller,
              panels: <SplitPanel>[
                SplitPanel(
                  size: _sizeUnit == SplitSizeUnit.proportional ? 1/3 : 200,
                  minSize: _sizeUnit == SplitSizeUnit.proportional ? 0.0 : 100,
                  maxSize: _sizeUnit == SplitSizeUnit.proportional ? 1.0 : 400,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: _buildPanel('Panel 0', theme.colorScheme.primaryContainer),
                ),
                SplitPanel(
                  priority: 1,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: _buildPanel('Panel 1', theme.colorScheme.secondaryContainer),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
