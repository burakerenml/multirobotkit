import 'package:flutter/material.dart';

import 'package:multirobotkit_desktop_app/rssi.dart';



void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double currentHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight:currentHeight*0.06 ,
          title: const Text("Multi-Robot Kit Information Panel"),
          backgroundColor: Colors.black,
        ),
        body: const RssiPage()
      ),
    );
  }
}

