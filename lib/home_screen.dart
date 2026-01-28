import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoogleMapController _mapController;
  Position? _currentPosition;

  StreamSubscription? _positionSubscriber;

  Timer? _timer;

  final List<LatLng> _latLngList = [];


  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(23.6850, 90.3563), // Bangladesh center
    zoom: 14,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkLocationPermissionAndService(onSuccess: () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      body: GoogleMap(
        initialCameraPosition: _defaultCamera,
        onMapCreated: (controller) {
          _mapController = controller;
          _getAndMoveToCurrentLocation(); // auto move
          _listenCurrentLocation();
        },
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        trafficEnabled: true,
        onTap: (LatLng latLng) {
          print(latLng);
        },
        onLongPress: (LatLng latLng) {
          print('Long pressed on $latLng');
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,

        markers: _currentPosition == null
            ? {}
            : {
          Marker(
            markerId: const MarkerId('my-location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRose,
            ),
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet:
              'Lat: ${_currentPosition!.latitude}, '
                  'Lng: ${_currentPosition!.longitude}',
            ),
          ),
        },

        polylines: <Polyline>{
          Polyline(
            polylineId: PolylineId('route'),
            points: _latLngList,
            color: Colors.blue,
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        },

      ),

    );
  }

  Future<void> _onTapGetMyLocation() async {
    //Locatiton permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (_isLocationPermissionGranded(permission)) {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (isLocationEnabled) {
        Position position = await Geolocator.getCurrentPosition();
        print(position);
        _currentPosition = position;
        setState(() {});
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      //if not, then request permission
      LocationPermission requestedPermission =
          await Geolocator.requestPermission();
      if (!_isLocationPermissionGranded(requestedPermission)) {
        _onTapGetMyLocation();
        return;
      }
    }
    //check if location service enabled
    //in not then request to enable service
    // Get current location
    Position? position = await Geolocator.getCurrentPosition();
  }

  Future<void> _listenCurrentLocation() async {

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;


      if (_latLngList.isEmpty ||
          _latLngList.last.latitude != position.latitude ||
          _latLngList.last.longitude != position.longitude) {
        _latLngList.add(LatLng(position.latitude, position.longitude));
      }


      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );

      setState(() {});
    });
  }

  Future<void> _checkLocationPermissionAndService({
    required VoidCallback onSuccess,
  }) async {
    //Locatiton permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (_isLocationPermissionGranded(permission)) {
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnabled) {
        //do your operation
        onSuccess();
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      //if not, then request permission
      LocationPermission requestedPermission =
          await Geolocator.requestPermission();
      if (!_isLocationPermissionGranded(requestedPermission)) {
        _onTapGetMyLocation();
        return;
      }
    }
    //check if location service enabled
    //in not then request to enable service
    // Get current location
    Position? position = await Geolocator.getCurrentPosition();
  }

  bool _isLocationPermissionGranded(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _getAndMoveToCurrentLocation() async {
    await _checkLocationPermissionAndService(
      onSuccess: () async {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _currentPosition = position;

        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _positionSubscriber?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
