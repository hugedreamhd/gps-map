import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GpsMapApp(),
    );
  }
}

class GpsMapApp extends StatefulWidget {
  const GpsMapApp({super.key});

  @override
  State<GpsMapApp> createState() => GpsMapAppState();
}

class GpsMapAppState extends State<GpsMapApp> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    //initstate는 async, await를 사용할 수 없다
    super.initState();

    init();
  }

  Future<void> init() async {
    final position = await _determinePosition(); //포지션이 포지션 객체로 얻어진다

    _initialCameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
    ); //에뮬 실행시 초기 gps 위치 변경코도

    setState(() {});// 위 값을 가지고 새로  UI를 호출한다

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialCameraPosition == null
      ? const Center(child: CircularProgressIndicator())
      : GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition!,//처음에는 null이다. null일때는
        //그릴 수가 없으니까 null 인 동안에는 로딩을 하겠다 - 삼항연산일때는 null 체크를 하더라도
        //null 이라고 인식을 할 수 없다. 임의로 느낌표로 알려줘야한다(!)
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 18,
    );

    // setState(() {
    //   _initialCameraPosition = cameraPosition;// chatgpt가 알려준 초기 카메라 위치 업데이트
    // });

    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<Position> _determinePosition() async {
    //현재 위치 정보 접속시 필요한 코드
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled(); //위치 정보기능이 켜있나
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission(); //현재 위치 정보 사용자 동의(권한)
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      //거부 2번하면 다시 물어보지 않음
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(); //현재 위치를 얻는다
  }
}
