import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'date_time_format.dart';

class InputSegment extends StatefulWidget {
  const InputSegment({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.focusNode,
  });

  final SegmentType type;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final FocusNode focusNode;

  @override
  State<InputSegment> createState() => _InputSegmentState();
}

class _InputSegmentState extends State<InputSegment> {
  late TextEditingController _controller;

  int get maxLength => widget.type == SegmentType.year ? 4 : 2;

  int get maxValue {
    return switch (widget.type) {
      SegmentType.year => 9999,
      SegmentType.month => 12,
      SegmentType.day => 31,
      SegmentType.hour => 23,
      SegmentType.minute => 59,
      SegmentType.second => 59,
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant InputSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_isEditing) {
      _controller.text = _formatValue(widget.value);
    }
  }

  bool get _isEditing => widget.focusNode.hasFocus;

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    } else {
      _controller.text = _formatValue(widget.value);
    }
  }

  String _formatValue(int value) {
    return value.toString().padLeft(maxLength, '0');
  }

  void _updateValue(String text) {
    if (text.isEmpty) return;
    final intValue = int.tryParse(text);
    if (intValue == null) return;
    final clamped = intValue.clamp(0, maxValue);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
    if (text.length >= maxLength) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              final newValue = (widget.value + 1).clamp(0, maxValue);
              widget.onChanged(newValue);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              final newValue = (widget.value - 1).clamp(0, maxValue);
              widget.onChanged(newValue);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.tab ||
                event.logicalKey == LogicalKeyboardKey.minus ||
                event.logicalKey == LogicalKeyboardKey.space) {
              widget.onNext();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              final delta = signal.scrollDelta.dy > 0 ? -1 : 1;
              final newValue = (widget.value + delta).clamp(0, maxValue);
              widget.onChanged(newValue);
            }
          },
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (text) {
              _updateValue(text);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }
}
