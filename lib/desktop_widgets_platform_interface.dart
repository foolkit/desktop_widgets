import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_widgets_method_channel.dart';

abstract class DesktopWidgetsPlatform extends PlatformInterface {
  /// Constructs a DesktopWidgetsPlatform.
  DesktopWidgetsPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopWidgetsPlatform _instance = MethodChannelDesktopWidgets();

  /// The default instance of [DesktopWidgetsPlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopWidgets].
  static DesktopWidgetsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopWidgetsPlatform] when
  /// they register themselves.
  static set instance(DesktopWidgetsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
