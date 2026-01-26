import 'package:flutter/services.dart';

class BatteryOptimization {
  static const _channel =
      MethodChannel('zenith/battery_optimization');

  static Future<void> requestDisable() async {
    try {
      await _channel.invokeMethod('disableBatteryOptimization');
    } catch (_) {}
  }
}
