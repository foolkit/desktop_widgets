#include "include/desktop_widgets/desktop_widgets_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "desktop_widgets_plugin.h"

void DesktopWidgetsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  desktop_widgets::DesktopWidgetsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
