import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_widgets_platform_interface.dart';

/// An implementation of [DesktopWidgetsPlatform] that uses method channels.
class MethodChannelDesktopWidgets extends DesktopWidgetsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_widgets');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
