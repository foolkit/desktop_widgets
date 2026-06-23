import 'package:flutter/material.dart';

class InlineDropdown<T> extends StatefulWidget {
  const InlineDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.itemWidth = 56,
    this.menuMaxHeight = 240,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? label;
  final double itemWidth;
  final double menuMaxHeight;

  @override
  State<InlineDropdown<T>> createState() => _InlineDropdownState<T>();
}

class _InlineDropdownState<T> extends State<InlineDropdown<T>> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _select(T value) {
    setState(() {
      _isOpen = false;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.onChanged == null ? null : _toggle,
            child: Container(
              width: widget.itemWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.value.toString().padLeft(2, '0'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen)
            Container(
              width: widget.itemWidth,
              constraints: BoxConstraints(maxHeight: widget.menuMaxHeight),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return InkWell(
                    onTap: () {
                      if (item.value != null) {
                        _select(item.value as T);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      alignment: Alignment.center,
                      child: DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!,
                      child: item.child,
                    ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
