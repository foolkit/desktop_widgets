import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'date_time_format.dart';
import 'input_field.dart';
import 'picker_panel.dart';

class DateTimePicker extends StatefulWidget {
  const DateTimePicker({
    super.key,
    this.initialValue,
    this.format = const DateTimeFormatConfig(),
    this.onChanged,
    this.showSeconds = true,
    this.firstDayOfWeekIsMonday = true,
    this.decoration,
    this.style,
    this.width = 240,
    this.panelWidth = 320,
    this.panelMaxHeight,
  });

  final DateTime? initialValue;
  final DateTimeFormatConfig format;
  final ValueChanged<DateTime>? onChanged;
  final bool showSeconds;
  final bool firstDayOfWeekIsMonday;
  final InputDecoration? decoration;
  final TextStyle? style;
  final double? width;
  final double? panelWidth;
  final double? panelMaxHeight;

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _value;
  final ValueNotifier<DateTime> _valueNotifier = ValueNotifier<DateTime>(DateTime.now());
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _inputKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final List<FocusNode> _focusNodes = [];
  bool _ignoreNextShowPanel = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? DateTime.now();
    _valueNotifier.value = _value;
    _initFocusNodes();
    developer.log(
      'DateTimePicker init: initialValue=$_value, showSeconds=${widget.showSeconds}, panelMaxHeight=${widget.panelMaxHeight}',
      name: 'DateTimePicker',
    );
  }

  void _initFocusNodes() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
    final count = widget.format.getSegmentTypes(showSeconds: widget.showSeconds).length;
    for (int i = 0; i < count; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _setValue(DateTime newValue) {
    developer.log('DateTimePicker _setValue: old=$_value, new=$newValue', name: 'DateTimePicker');
    _value = newValue;
    _valueNotifier.value = _value;
    _overlayEntry?.markNeedsBuild();
    widget.onChanged?.call(_value);
  }

  void _updateSegmentValue(SegmentType type, int newValue) {
    developer.log('DateTimePicker _updateSegmentValue: type=$type, newValue=$newValue', name: 'DateTimePicker');
    setState(() {
      switch (type) {
        case SegmentType.year:
          _value = DateTime(newValue, _value.month, _value.day, _value.hour, _value.minute, _value.second);
          break;
        case SegmentType.month:
          final maxDay = _getDaysInMonth(_value.year, newValue);
          final day = _value.day > maxDay ? maxDay : _value.day;
          _value = DateTime(_value.year, newValue, day, _value.hour, _value.minute, _value.second);
          break;
        case SegmentType.day:
          final maxDay = _getDaysInMonth(_value.year, _value.month);
          final day = newValue > maxDay ? maxDay : newValue;
          _value = DateTime(_value.year, _value.month, day, _value.hour, _value.minute, _value.second);
          break;
        case SegmentType.hour:
          _value = DateTime(_value.year, _value.month, _value.day, newValue, _value.minute, _value.second);
          break;
        case SegmentType.minute:
          _value = DateTime(_value.year, _value.month, _value.day, _value.hour, newValue, _value.second);
          break;
        case SegmentType.second:
          _value = DateTime(_value.year, _value.month, _value.day, _value.hour, _value.minute, newValue);
          break;
      }
    });
    _valueNotifier.value = _value;
    _overlayEntry?.markNeedsBuild();
    widget.onChanged?.call(_value);
  }

  void _showPanel() {
    developer.log('DateTimePicker _showPanel called, _overlayEntry=${_overlayEntry != null}, _ignoreNextShowPanel=$_ignoreNextShowPanel', name: 'DateTimePicker');
    if (_ignoreNextShowPanel) {
      developer.log('DateTimePicker ignoring _showPanel due to recent outside tap', name: 'DateTimePicker');
      _ignoreNextShowPanel = false;
      return;
    }
    if (_overlayEntry != null) {
      _hidePanel();
      return;
    }

    final overlay = Overlay.of(context);
    final panelWidth = widget.panelWidth ?? 320;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: panelWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: TapRegion(
            onTapOutside: (_) {
              developer.log('DateTimePicker tap outside panel detected, hiding panel', name: 'DateTimePicker');
              _ignoreNextShowPanel = true;
              _hidePanel();
            },
            child: ValueListenableBuilder<DateTime>(
              valueListenable: _valueNotifier,
              builder: (context, value, child) {
                developer.log('DateTimePicker overlay rebuild: value=$value', name: 'DateTimePicker');
                return DateTimePickerPanel(
                  value: value,
                  onChanged: _setValue,
                  showSeconds: widget.showSeconds,
                  firstDayOfWeekIsMonday: widget.firstDayOfWeekIsMonday,
                  width: panelWidth,
                  maxHeight: widget.panelMaxHeight,
                );
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {});
    }
    developer.log('DateTimePicker OverlayEntry inserted', name: 'DateTimePicker');
  }

  void _hidePanel() {
    developer.log('DateTimePicker _hidePanel called', name: 'DateTimePicker');
    _overlayEntry?.remove();
    _overlayEntry = null;
    widget.onChanged?.call(_value);
    if (mounted) {
      setState(() {});
    }
  }

  int _getSegmentValue(SegmentType type) {
    return switch (type) {
      SegmentType.year => _value.year,
      SegmentType.month => _value.month,
      SegmentType.day => _value.day,
      SegmentType.hour => _value.hour,
      SegmentType.minute => _value.minute,
      SegmentType.second => _value.second,
    };
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.format.getSegmentTypes(showSeconds: widget.showSeconds);
    final widgets = <Widget>[];

    for (int i = 0; i < segments.length; i++) {
      final type = segments[i];
      widgets.add(
        InputSegment(
          type: type,
          value: _getSegmentValue(type),
          onChanged: (v) => _updateSegmentValue(type, v),
          onNext: () {
            if (i < _focusNodes.length - 1) {
              _focusNodes[i + 1].requestFocus();
            }
          },
          onPrevious: () {
            if (i > 0) {
              _focusNodes[i - 1].requestFocus();
            }
          },
          focusNode: _focusNodes[i],
        ),
      );

      if (i < segments.length - 1) {
        final isDateTimeBoundary = (widget.format.dateFirst && i == 2) || (!widget.format.dateFirst && i == (widget.showSeconds ? 2 : 1));
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              isDateTimeBoundary ? ' ' : (type == SegmentType.year || type == SegmentType.month || type == SegmentType.day ? widget.format.dateSeparator : widget.format.timeSeparator),
              style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }
    }

    final inputField = TextField(
      key: _inputKey,
      readOnly: true,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_overlayEntry != null ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          onPressed: _showPanel,
        ),
      ),
      controller: TextEditingController(text: widget.format.format(_value, showSeconds: widget.showSeconds)),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: widget.width,
        child: inputField,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    developer.log('DateTimePicker didUpdateWidget', name: 'DateTimePicker');
    if (oldWidget.showSeconds != widget.showSeconds || oldWidget.format != widget.format) {
      _initFocusNodes();
    }
  }

  @override
  void dispose() {
    developer.log('DateTimePicker dispose: removing OverlayEntry', name: 'DateTimePicker');
    _overlayEntry?.remove();
    _overlayEntry = null;
    _valueNotifier.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
