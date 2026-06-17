import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_widgets/desktop_widgets.dart';
import 'package:desktop_widgets/desktop_widgets_platform_interface.dart';
import 'package:desktop_widgets/desktop_widgets_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopWidgetsPlatform
    with MockPlatformInterfaceMixin
    implements DesktopWidgetsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopWidgetsPlatform initialPlatform = DesktopWidgetsPlatform.instance;

  test('$MethodChannelDesktopWidgets is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopWidgets>());
  });

  test('getPlatformVersion', () async {
    DesktopWidgets desktopWidgetsPlugin = DesktopWidgets();
    MockDesktopWidgetsPlatform fakePlatform = MockDesktopWidgetsPlatform();
    DesktopWidgetsPlatform.instance = fakePlatform;

    expect(await desktopWidgetsPlugin.getPlatformVersion(), '42');
  });
}
