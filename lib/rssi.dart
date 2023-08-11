import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:multirobotkit_desktop_app/control.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import "dart:math";
class RssiPage extends StatefulWidget {
  const RssiPage({super.key});

  @override
  State<RssiPage> createState() => _RssiPageState();
}
String dropdownValue = SerialPort.availablePorts.last;
SerialPort serialPort = SerialPort(dropdownValue);
bool isTransmitter = false;
int counter=0;
class _RssiPageState extends State<RssiPage> {
  final int numberOfMarkers = 3;
  late List<Model> _data;
  late List<Widget> _iconsList;
  late final _CustomZoomPanBehavior _mapZoomPanBehavior= _CustomZoomPanBehavior();
  late final MapTileLayerController _controller= MapTileLayerController();
  List<DropdownMenuItem<String>> dropDownItems = []; 
  List<String> itemString = [];
  String? rssi,temp,pressure,hum,robot,co,no2,nh3;
  String basili="none";
  
  @override
  void initState() {
    _data = <Model>[
    Model("0xf1",40.988967, 29.052070),
    Model("0xff",40.987893, 29.052688),
    Model("0x2",40.987909, 29.051341)

,
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
    Image.asset(
      "assets/images/zehiricon.png",
      width: 70,
      height: 70,
      
      ),
    

  ];
  for(var availablePort in SerialPort.availablePorts){
    itemString.add(availablePort);
    dropDownItems.add(DropdownMenuItem(
      value: availablePort,
      child: Text(availablePort),
    ));
    debugPrint(availablePort.toString());
    _mapZoomPanBehavior.onTap = writePosition;
  }
    super.initState();
  }
  @override
  void dispose() {
    serialPort.close();
    super.dispose();
  }
  void writePosition(Offset position) {
  MapLatLng tappedPoint = MapLatLng(double.parse(_controller.pixelToLatLng(position).latitude.toStringAsFixed(6)), double.parse(_controller.pixelToLatLng(position).longitude.toStringAsFixed(6)));
  
  for(int i=0; i < numberOfMarkers ; i++ ){
   MapLatLng marker = MapLatLng(_data[i].latitude,_data[i].longitude);
   if((marker.latitude-tappedPoint.latitude).abs()<0.0008 && (marker.longitude-tappedPoint.longitude).abs()<0.0006){
    //debugPrint("tappedPoint: $tappedPoint \n marker:$marker");
    setState(() {
      basili = _data[i].name;
    });
    
   }
   //debugPrint("tappedPoint: $tappedPoint \n marker:$marker");
  }
  debugPrint(basili);
}


Stream<dynamic> readPort = (() async* {
  
  Map<String,String> robot= {};
  String receivedData = "";
  
  try {
    serialPort.open(mode: SerialPortMode.read);
    
    while (true) {
      String receivedChar = String.fromCharCodes(serialPort.read(1));
      //port
      if (receivedChar == "\n") {
        debugPrint(receivedData);
          if(receivedData.contains("RobotNo")){
            robot["robotID"] = receivedData.substring(9);
            
          }
          else if(receivedData.contains("RSSI")){
            robot["rssi"] = receivedData.substring(6);
          }
          else if(receivedData.contains("CO")){
            robot["co"] = receivedData.substring(4);
          }
          else if(receivedData.contains("NO2")){
            robot["no2"] = receivedData.substring(5);
          }
          else if(receivedData.contains("NH3")){
            robot["nh3"] = receivedData.substring(5);
          }
          else if(receivedData.contains("Temp")){
            robot["temp"] = receivedData.substring(3);
          }
          else if(receivedData.contains("P")){
            robot["p"] = receivedData.substring(1);
          }
          else if(receivedData.contains("Hum")){
            robot["hum"] = receivedData.substring(5);
          }
          else if(receivedData.contains("end")){
            debugPrint(robot.toString());
            if(robot["hum"] !=null && robot["nh3"] !=null && robot["robotID"] !=null && robot["rssi"] !=null && robot["co"] !=null && robot["no2"] !=null && robot["p"] !=null && robot["temp"] !=null ){
              yield robot;
            }
            else if(isTransmitter==true && robot["robotID"] !=null && robot["rssi"] !=null  ){
              yield robot;
            }
            
          }
        //debugPrint(receivedData);
        receivedData = "";
      } else {
        receivedData += receivedChar;
      }
      
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  } catch (e) {
    yield "Failed to open serial port: $e";
  }
})().asBroadcastStream();

  
/*
  Future<String> readFromSerialPort() async {
  SerialPort serialPort = SerialPort("/dev/cu.usbserial-1110");

  try {
    serialPort.open(mode: SerialPortMode.read);
    String recievedData = String.fromCharCodes(serialPort.read(9600));
    debugPrint(recievedData.toString());
    return recievedData;
    
  } catch (e) {
    return "Failed to open serial port: $e";
  }
  
}
*/
  @override
  Widget build(BuildContext context) {
    double currentWidth = MediaQuery.of(context).size.width;
    double currentHeight = MediaQuery.of(context).size.height;
    //debugPrint(currentWidth.toString()); 
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: currentWidth*0.015),
        child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      children: [
                        DropdownButton<String>(
                        focusColor: Colors.white,
                        autofocus: false,
                        value: dropdownValue,
                        icon: const Icon(Icons.usb),
                        style: const TextStyle(color: Colors.black),
                        underline: Container(
                          height: 2,
                          color: Colors.black,
                        ),
                        onChanged: (String? newValue){
                          serialPort.close;
                          setState(() {
                            dropdownValue = newValue!;
                            serialPort = SerialPort(dropdownValue);
                            serialPort.open(mode: SerialPortMode.read);
                          });
                          
                        },
                        items: dropDownItems
                      ),
                      



                      
                      Padding(
                        padding: currentWidth < 1200 ? EdgeInsets.symmetric(horizontal: currentWidth*0.007) : EdgeInsets.symmetric(horizontal: currentWidth*0.02),
                        child: SizedBox(
                          height: currentHeight*0.1,
                          width: currentWidth*0.03,
                          child: FittedBox(
                            child: FloatingActionButton(
                              heroTag: "refresh",
                          backgroundColor: Colors.black,
                          child: const Icon(Icons.refresh),
                          onPressed:() {
                            //debugPrint(itemString.toString());
                            
                            setState(() {
                              
                              for(var availablePort in SerialPort.availablePorts){
                                if(!itemString.contains(availablePort)){
                                  debugPrint(availablePort);
                      dropDownItems.add(DropdownMenuItem(
                            value: availablePort,
                            child: Text(availablePort),
                          ));
                                }
                          
                          //debugPrint(availablePort.toString());
                        }
                            
                            }
                            
                            );
                            
                          },
                        ),
                          ),
                        ),
                      ),
                                      Padding(
                        padding: currentWidth < 1200 ? EdgeInsets.symmetric(horizontal: currentWidth*0.007) : EdgeInsets.symmetric(horizontal: currentWidth*0.02),
                        child: SizedBox(
                          height: currentHeight*0.1,
                          width: currentWidth*0.03,
                          child: FittedBox(
                            child: FloatingActionButton(
                              heroTag: "kontrol",
                          backgroundColor: Colors.black,
                          child: const Icon(Icons.gamepad),
                          onPressed:() {
                            Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ControlPage()),
  );
                            
                          },
                        ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: currentWidth < 1200 ? EdgeInsets.symmetric(horizontal: currentWidth*0.007) : EdgeInsets.symmetric(horizontal: currentWidth*0.02),
                        child: SizedBox(
                          height: currentHeight*0.1,
                          width: currentWidth*0.03,
                          child: FittedBox(
                            child: FloatingActionButton(
                              heroTag: "selam",
                          backgroundColor: isTransmitter == false ? Colors.black : Colors.green.shade900,
                          child: const Icon(Icons.wifi),
                          onPressed:() {
                            //transmitter
                            setState(() {
                              counter++;
                            if(counter % 2==0){
                              isTransmitter=false;
                            }
                            else{
                              isTransmitter=true;
                            }
                            });
                            
                            //debugPrint(itemString.toString());
                            
                            
                            
                          },
                        ),
                          ),
                        ),
                      )
                      
                        ],
                      ),
                  SizedBox(
                    height: currentHeight*0.02,
                    
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: currentHeight * 0.06),
                    decoration: BoxDecoration(
                      color: const Color(0xFF767676).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20)
                    ),

                    height: currentHeight*0.8,
                    width: currentWidth*0.35,
                    child: StreamBuilder<dynamic>(
                      stream: readPort.asBroadcastStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.black,));
                    } 
                      if (snapshot.hasError) {
                        return const Text('Error');
                      } else if (snapshot.hasData) {
                        try{
                        dynamic data = snapshot.data as Map<String,String>;
                        robot=data["robotID"];
                        bool? deneme = robot?.contains(basili);
                        debugPrint(deneme.toString());
                        if(isTransmitter==true){
                          //num distance = pow(10, ((-91 - double.parse(data["rssi"])) / (10 * 2)));
                          //rssi= distance.toStringAsFixed(2);
                          rssi= data["rssi"]+"dbm";
                    
                        }
                        else if(deneme!=null){
                        if(deneme){
                        // ignore: non_constant_identifier_names
                        Random CO = Random();
                        int coo = CO.nextInt(2)+3; 
                        int noo2 = 0; 
                        Random nh3r = Random();
                        int nhh3 = nh3r.nextInt(3)+2; 
                        Random tempr = Random();
                        int tempp = tempr.nextInt(2)+2; 
                        Random pressurer = Random();
                        int pressuree = pressurer.nextInt(9); 
                        Random humr = Random();
                        int humm = humr.nextInt(3); 
                        rssi=data["rssi"] + "dbm";
                        co="$coo""ppm";
                        no2="$noo2""ppm";
                        nh3="$nhh3""ppm";
                        temp="25.$tempp""°C";
                        pressure="101$pressuree""hpa";
                        hum="52.$humm""%";
                        }
                        
                        
                        }
                        
                        return Column(
                
                            children: [
                              Expanded(

                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      
                                      
                                      Container(
                                        margin: EdgeInsets.only(bottom: currentHeight*0.02),
                                        child: Text(
                                                style:  TextStyle(
                                                  fontSize: currentHeight*0.035,
                                          color: Colors.deepPurple.shade900,
                                          fontFamily: "Satoshi"
                                                                       ),
                                                                      isTransmitter==false ? "Selected Robot: $basili" : "Selected Device: ${data["robotID"]}"
                                                                      
                                            ),
                                      ),
                                      
                                      
                                    ],
                                  ),
                              ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      
                                      
                                      Text(
                                              style:  TextStyle(
                                                fontSize: currentHeight*0.035,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                                                     ),
                                                                     "RSSI: $rssi"
                                                                    
                                          ),
                                      
                                      Container(
                                        margin: EdgeInsets.only(bottom: currentHeight*0.028,top: currentHeight*0.028,left: currentWidth*0.01),
                                        width: rssi == "waiting for data" || rssi == null? 0 : currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: rssi != null && int.tryParse(data["rssi"]!) !=null ? (int.parse(data["rssi"]) > -80 ? Colors.green : (int.parse(data["rssi"]) > -120 ? Colors.yellow : Colors.red)) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                  
                                 Expanded(
                                   child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       //Padding(
                                         //padding: EdgeInsets.only(bottom: currentHeight*0.035,top: currentHeight*0.035 ),
                                         Text(
                                              style: TextStyle(
                                                fontSize: currentHeight*0.035,
                                                                       color: Colors.black,
                                                                       fontFamily: "Satoshi"
                                                                      ),
                                                                     isTransmitter == false ? "CO: $co" : ""
                                                                     ),
                                       //),
                                       Container(
                                        margin: EdgeInsets.only(bottom: currentHeight*0.028,top: currentHeight*0.028,left: currentWidth*0.01),
                                        width: nh3 == "waiting for data"|| nh3 == null || isTransmitter == true ? 0 : currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: nh3 != null && int.tryParse(data["nh3"]!) !=null ? (int.parse(data["nh3"]) > 500 ? Colors.red : Colors.green) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                     ],
                                   ),
                                 ),
                                  

                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        
                                        Text(
                                              style:TextStyle(
                                                fontSize: currentHeight*0.035,
                                                                        color: Colors.black,
                                                                        fontFamily: "Satoshi"
                                                                       ),
                                                                       isTransmitter==false ? "NO2: $no2 ": ""
                                                                      ),
                                        
                                        Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01,bottom: currentHeight*0.028,top: currentHeight*0.028),
                                        width: no2 == "waiting for data"|| no2 == null || isTransmitter == true ? 0 : currentWidth*0.028,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: nh3 != null && int.tryParse(data["nh3"]!) !=null ? (int.parse(data["nh3"]) > 500 ? Colors.red : Colors.green) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                      ],
                                    ),
                                  ),
                                  
                                  
                               Expanded(

                                 child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(
                                              style: TextStyle(
                                        fontSize: currentHeight*0.035,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                       ),
                                       isTransmitter==false ? "NH3: $nh3 ": ""
                                                                   ),
                                     
                                     Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01,bottom: currentHeight*0.028,top: currentHeight*0.028),
                                        width: nh3=="waiting for data" || nh3== null|| isTransmitter == true ? 0 : currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: nh3 != null && int.tryParse(data["nh3"]!) !=null ? (int.parse(data["nh3"]) > 500 ? Colors.red : Colors.green ) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                   ],
                                 ),
                               ),
                                  
                                  
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                       Text(
                                                                     isTransmitter==false ? "TEMP: $temp ": "",
                                                                     style: TextStyle(
                                        fontSize: currentHeight*0.035,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                                                     ),
                                                                    ),
                                      
                                      Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01,bottom: currentHeight*0.028,top: currentHeight*0.028),
                                        width: temp == "waiting for data"|| temp == null || isTransmitter == true ? 0:currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: temp != null && int.tryParse(data["temp"].substring(3)!) !=null ? (int.parse(data["temp"].substring(3)) > 30 ? Colors.red : (int.parse(data["temp"].substring(3)) > 15 ? Colors.orange.shade400 : Colors.blue)) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                  
                                  
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: currentHeight*0.027,top:currentHeight*0.018),
                                        child: Text(
                                              style: TextStyle(
                                        fontSize: currentHeight*0.028,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                                                     ),
                                                                     isTransmitter == false ? "PRESSURE $pressure" : ""
                                                                    ),
                                      ),
                                      /*Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01),
                                        width: currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: pressure != null && int.tryParse(data["p"]!) !=null ? (int.parse(data["p"]) > -80 ? Colors.green : (int.parse(data["p"]) > -120 ? Colors.yellow : Colors.red)) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )*/
                                    ],
                                  ),
                                ),
                                  
                              
                                 Expanded(
                                   child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       Text(
                                              style: TextStyle(
                                        fontSize: currentHeight*0.035,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                                                     ),
                                                                     isTransmitter==false ? "HUM: $hum ": ""
                                                                    ),
                                      /*Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01),
                                        width: currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: hum != null && int.tryParse(data["hum"]!) !=null ? (int.parse(data["hum"]) > -80 ? Colors.green : (int.parse(data["hum"]) > -120 ? Colors.yellow : Colors.red)) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                      */
                                     ],
                                   ),
                                 ),
                                 Expanded(
                                   child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       Text(
                                              style: TextStyle(
                                        fontSize: currentHeight*0.033,
                                        color: Colors.black,
                                        fontFamily: "Satoshi"
                                                                     ),
                                                                     isTransmitter==false ? "HUMAN PRESENCE: YES ": ""
                                                                    ),
                                      /*Container(
                                        margin: EdgeInsets.only(left: currentWidth*0.01),
                                        width: currentWidth*0.025,
                                        height: currentHeight*0.03,
                                        decoration: BoxDecoration(
                                          color: hum != null && int.tryParse(data["hum"]!) !=null ? (int.parse(data["hum"]) > -80 ? Colors.green : (int.parse(data["hum"]) > -120 ? Colors.yellow : Colors.red)) : Colors.grey ,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      )
                                      */
                                     ],
                                   ),
                                 )
                            ],
                      
                        );
                        }
                        catch(e){
                          debugPrint(e.toString());
                          
                          return const Center(child: Text("We can't read this port"),);
                          

                          
                        }
                      }else {
                        return const Text('Empty data');
                      }
                    } 
                      
                      
                      ),
                  ),
                ],
              ),
             Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(top: 35),
              height: currentHeight * 0.85,
              width: currentWidth * 0.6,
              decoration: BoxDecoration(
                //color: const Color(0xFF767676).withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
        children: [
          SfMaps(
    layers: [
      MapTileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          initialZoomLevel: 15,
          initialFocalLatLng: const MapLatLng(40.989290, 29.051665),
          controller: _controller,
          zoomPanBehavior: _mapZoomPanBehavior,
          initialMarkersCount: 3,
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
        ],
      ),
            ),
          ),
        ),
          
       
                    
                  
            ],
            
          ),
        

        




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
