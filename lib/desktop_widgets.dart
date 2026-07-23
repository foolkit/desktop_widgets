export 'src/pickers/date_time_picker.dart';
export 'src/pickers/date_time_format.dart';
export 'src/layouts/fullscreen.dart';
export 'src/layouts/side_split_layout.dart';
export 'src/layouts/split_layout.dart';

import 'desktop_widgets_platform_interface.dart';

class DesktopWidgets {
  Future<String?> getPlatformVersion() {
    return DesktopWidgetsPlatform.instance.getPlatformVersion();
  }
}
