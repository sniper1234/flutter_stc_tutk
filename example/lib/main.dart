import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_stc_tutk/flutter_stc_tutk.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _videoResultMessage = 'UnknownVideo';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    String videoResultMessage;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterStcTutk.platformVersion;
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sample on: $_platformVersion\n'),
        ),
        body: Center(
            child: Column(children: <Widget>[
          SizedBox(
              width: 380,
              height: 380,
              child: Platform.isIOS
                  ? UiKitView(viewType: 'stc_video_player_view')
                  : (Platform.isAndroid
                      ? AndroidView(
                          viewType: 'stc_video_player_view',
                        )
                      : Container(
                          height: 0,
                          width: 0,
                        ))),
          FloatingActionButton(
            onPressed: () {
              FlutterStcTutk.startLiveVideo(
                  "ABXG1TRYG5PRSD1R111A", "T39S24CM2BF1");
            },
            child: Text("Start"),
          ),
          FloatingActionButton(
            onPressed: () {
              FlutterStcTutk.stopLiveVideo(
                  "ABXG1TRYG5PRSD1R111A", "T39S24C20FPY");
            },
            child: Text("Stop"),
          )
        ])),
      ),
    );
  }
}
