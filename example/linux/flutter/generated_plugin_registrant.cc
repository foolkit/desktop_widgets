//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_widgets/desktop_widgets_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_widgets_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopWidgetsPlugin");
  desktop_widgets_plugin_register_with_registrar(desktop_widgets_registrar);
}
