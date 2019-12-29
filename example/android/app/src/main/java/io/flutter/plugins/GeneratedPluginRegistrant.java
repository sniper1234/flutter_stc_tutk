package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import com.stc.flutter.tutk.flutter_stc_tutk.FlutterStcTutkPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    FlutterStcTutkPlugin.registerWith(registry.registrarFor("com.stc.flutter.tutk.flutter_stc_tutk.FlutterStcTutkPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
