
import 'desktop_widgets_platform_interface.dart';

class DesktopWidgets {
  Future<String?> getPlatformVersion() {
    return DesktopWidgetsPlatform.instance.getPlatformVersion();
  }
}
