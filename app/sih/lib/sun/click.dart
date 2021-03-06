import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:io';
import 'package:location/location.dart';
import 'package:sensors/sensors.dart';
import 'package:camera/camera.dart';
import 'package:sih/waterValue.dart';

List<CameraDescription> cameras;
CameraController controller;

class SunClick extends StatefulWidget {
  Map<dynamic, dynamic> temp;
  SunClick({Key key, @required this.temp}) : super(key: key);
  @override
  _SunClick createState() => _SunClick();
}

Location location = new Location();

class _SunClick extends State<SunClick> {
  AccelerometerEvent event;

  // Location
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  double lat, long;

  void checkLocationService() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    if (_serviceEnabled) {
      getLocation();
    }
  }

  void checkLocationpermission() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    if (_permissionGranted == PermissionStatus.granted) {
      checkLocationService();
    }
  }

  void getLocation() async {
    _locationData = await location.getLocation();
    setState(() {
      lat = _locationData.latitude;
      long = _locationData.longitude;
    });
  }

//Location

  String getY() {
    return ((event.y * 90) / 10).ceilToDouble().toString();
  }

  String getZ() {
    return ((event.z * 90) / 10).ceilToDouble().toString();
  }

  void cameraGet() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    cameraGet();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            !controller.value.isInitialized
                ? Container()
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      false
                          ? "press"
                          : "zenith: " +
                              widget.temp["zenith"].toString() +
                              "\nazimuth: " +
                              widget.temp["azimuth"].toString() +
                              "\nelevation: " +
                              widget.temp["altitude"].toString(),
                      style: TextStyle(color: Colors.black, fontSize: 15.0),
                    ),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  GestureDetector(
                      onTap: () {
                        accelerometerEvents.listen((AccelerometerEvent eve) {
                          // print(eve.y * 90 / 10);
                          setState(() {
                            event = eve;
                          });
                        });
                      },
                      child: Text(
                        event == null ? "Press" : "Y: " + getY(),
                        style: TextStyle(color: Colors.black, fontSize: 15.0),
                      )),
                  SizedBox(
                    height: 20.0,
                  ),
                  IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 40.0,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        _onCapturePressed(context);
                      }),
                  SizedBox(
                    height: 30.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCapturePressed(context) async {
    try {
      // 1
      final path = join(
        "/storage/emulated/0/",
        widget.temp["zenith"].toString() + ".png",
      );
      // 2
      await controller.takePicture(path);
      final bytes = File(path).readAsBytesSync();
      dynamic a = base64Encode(bytes);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaterValue(img: a),
        ),
      );
      // 3
    } catch (e) {
      print(e);
    }
  }
}
