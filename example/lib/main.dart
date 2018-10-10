import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:qrcode/qrcode.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    Qrcode.scanQRCode(2, "扫描二维码", "请将二维码放入框中").then((s) {
      print('AAAAAAAAAA    $s');
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = "await Qrcode.platformVersion";
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new CupertinoApp(
      home: new CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Plugin example app'),
        ),
        child: Center(
          child: Text('Running on: XXXXXXX')
        ),
        // appBar: new AppBar(
        //   title: const Text('Plugin example app'),
        // ),
        // body: new Center(
        //   child: new Text('Running on: $_platformVersion\n'),
        // ),
      ),
    );
  }
}
