import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:gamepads/gamepads.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/camera_macos_view.dart';
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String? deviceId;
  int quarterTurns = 0;
  final int numberOfMarkers = 2;
  late List<Model> _data;
  late List<Widget> _iconsList;
  late final _CustomZoomPanBehavior _mapZoomPanBehavior= _CustomZoomPanBehavior();
  late final MapTileLayerController _controller= MapTileLayerController();
  String selectedRobot="none";
  StreamSubscription<GamepadEvent>? _subscription;
  SerialPort serialPort = SerialPort(SerialPort.availablePorts.last);
  bool loading = false;
  @override
  void initState() {
    cameraFunc();
    super.initState();
        _data = <Model>[
    Model("1",40.988967, 29.052070),
    Model("2",40.987893, 29.052688),



  ];

  _iconsList = <Widget>[
    Image.asset(
      "assets/images/hızıricon.png",
      width: 90,
      height: 90,
      
      ),
    Image.asset(
      "assets/images/opa.png",
      width: 50,
      height: 50,
      
      ),
    

  ];
    serialPort.open(mode: SerialPortMode.write);
    _subscription = Gamepads.events.listen((event) {
        final eventString = "robo$selectedRobot"+event.toString();
        final eventBytes = utf8.encode(eventString);
        serialPort.write(Uint8List.fromList(eventBytes));
        debugPrint(eventString);
        
    });
    _mapZoomPanBehavior.onTap = writePosition;

  }

  @override
  void dispose() {
    _subscription?.cancel();
    serialPort.close();
    super.dispose();
  }
Future<String?> cameraFunc() async{
  List<CameraMacOSDevice> videoDevices = await CameraMacOS.instance.listDevices();
  for(var camera in videoDevices){
    //if(camera.localizedName == "USB2.0 PC CAMERA"){
      deviceId=camera.deviceId;
    //}
  }
  
  return deviceId;
  } 
void writePosition(Offset position) {
  MapLatLng tappedPoint = MapLatLng(double.parse(_controller.pixelToLatLng(position).latitude.toStringAsFixed(6)), double.parse(_controller.pixelToLatLng(position).longitude.toStringAsFixed(6)));
  
  for(int i=0; i < numberOfMarkers ; i++ ){
   MapLatLng marker = MapLatLng(_data[i].latitude,_data[i].longitude);
   if((marker.latitude-tappedPoint.latitude).abs()<0.0008 && (marker.longitude-tappedPoint.longitude).abs()<0.0006){
    //debugPrint("tappedPoint: $tappedPoint \n marker:$marker");
    setState(() {
      selectedRobot = _data[i].name;
    });
    
   }
   //debugPrint("tappedPoint: $tappedPoint \n marker:$marker");
  }
  debugPrint(selectedRobot);
}
  @override
  Widget build(BuildContext context) {
    double currentWidth = MediaQuery.of(context).size.width;
    double currentHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Page"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(onPressed:() {
            setState(() {
              if(quarterTurns>3){
                quarterTurns=1;
              }
              else {
                quarterTurns++;
              }
            });

          }, 
          icon: const Icon(Icons.rotate_90_degrees_ccw)
          
          )
        ],
      ),
      body: Row(
        children: [
          Column(
            children: [
              Container(
                height: currentHeight*0.75,
                width: currentWidth*0.40,
                margin: EdgeInsets.only(top: currentHeight*0.015,left:currentWidth*0.015),
                child: SfMaps(
    layers: [
          MapTileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              initialZoomLevel: 15,
              initialFocalLatLng: const MapLatLng(40.989290, 29.051665),
              controller: _controller,
              zoomPanBehavior: _mapZoomPanBehavior,
              initialMarkersCount: 2,
                markerBuilder: (BuildContext context, int index) {
                  return MapMarker(
                    latitude: _data[index].latitude,
                    longitude: _data[index].longitude,
                    child: _iconsList[index],
                  );
                },
            ),
     ],
              )
                
              ),
              Container(
                margin:EdgeInsets.only(top: currentHeight*0.015,left: currentWidth*0.015), 
                decoration: BoxDecoration(
                  // ignore: use_full_hex_values_for_flutter_colors
                  color: const Color(0x030303).withOpacity(0.53),
                  borderRadius: BorderRadius.circular(20)
                ),
                height: currentHeight*0.12,
                width: currentWidth*0.4,
                child: Center(
                  child: Text(
                    "Selected Robot: $selectedRobot",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Satoshi",
                      fontSize: currentWidth*0.02
                    ),
                  ),
                ),
              ),
            ],
          ),

          Column(
            children: [
              Container(
                    height: currentHeight*0.75,
                    width: currentWidth*0.55,
                    
                    margin: EdgeInsets.only(top: currentHeight*0.015,left:currentWidth*0.02),
                    
                    child: FutureBuilder(
        future: cameraFunc(),
        builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
      // If we got an error
      if (snapshot.hasError) {
        return Center(
              child: Text(
                '${snapshot.error} occurred',
                style: const TextStyle(fontSize: 18),
              ),
        );
         
        // if we got our data
      } else if (snapshot.hasData) {

        final data = snapshot.data as String;
        return RotatedBox(
                  quarterTurns: quarterTurns,
                  child: Center(
                    child: CameraMacOSView(
                      
                      deviceId: data,
                      fit: BoxFit.fill,
                      cameraMode: CameraMacOSMode.video,
                      onCameraInizialized: (CameraMacOSController controller) {
                         
                      },
                              ),
                  ),
                );
              

      }
    }
    return const Center(child: CircularProgressIndicator());
        },
      ),
              ),
                            Container(
                margin:EdgeInsets.only(top: currentHeight*0.015,left: currentWidth*0.015), 
                decoration: BoxDecoration(
                  // ignore: use_full_hex_values_for_flutter_colors
                  color: const Color(0x030303).withOpacity(0.53),
                  borderRadius: BorderRadius.circular(20)
                ),
                height: currentHeight*0.12,
                width: currentWidth*0.55,
                child: Center(
                  child: Text(
                    "Robot CAM",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Satoshi",
                      fontSize: currentWidth*0.02
                    ),
                  ),
                ),
              ),

            ],
          )


        ],
      ),
      
  
    );
  }
}
class _CustomZoomPanBehavior extends MapZoomPanBehavior {
  _CustomZoomPanBehavior();
  late MapTapCallback onTap;

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent) {
      onTap(event.localPosition);
    }
    super.handleEvent(event);
  }
}
typedef MapTapCallback = void Function(Offset position);
class Model {
  Model(this.name,this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
}
