import 'dart:async';

import 'package:flutter/services.dart';

class Qrcode {
  static const MethodChannel _channel =
      const MethodChannel('qrcode');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> scanQRCode(int type, String title, String text) async {
    final Map<String, Object> argument = Map();
    argument['scanType'] = type;
    argument['handlePermissions'] = true;
    argument['executeAfterPermissionGranted'] = true;
    argument['title'] = title;
    argument['text'] = text;
    return await _channel.invokeMethod('scanQRCode', argument);
  }
}
