import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_stc_tutk/flutter_stc_tutk.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_stc_tutk');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterStcTutk.platformVersion, '42');
  });
}
