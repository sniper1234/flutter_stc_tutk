import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterStcTutk {
  static const MethodChannel _channel =
      const MethodChannel('flutter_stc_tutk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> startLiveVideo(String uid, String deviceSN) async {
    final String result = await _channel.invokeMethod('startLiveVideo', {"uid": uid, "deviceSN":deviceSN});
    return result;
  }

  static Future<String> stopLiveVideo(String uid, String deviceSN) async {
    final String result = await _channel.invokeMethod('stopLiveVideo', {"uid": uid, "deviceSN":deviceSN});
    return result;
  }
}
