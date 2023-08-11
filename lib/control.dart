import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:gamepads/gamepads.dart';
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  StreamSubscription<GamepadEvent>? _subscription;
  SerialPort serialPort = SerialPort(SerialPort.availablePorts.last);
  bool loading = false;


  @override
  void initState() {
    super.initState();
    serialPort.open(mode: SerialPortMode.write);
    _subscription = Gamepads.events.listen((event) {
        final eventString = event.toString();
        final eventBytes = utf8.encode(eventString);
        serialPort.write(Uint8List.fromList(eventBytes));
        debugPrint(event.toString());
        
    });

  }
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Page"),
        backgroundColor: Colors.black,
      ),
      
  
    );
  }
}