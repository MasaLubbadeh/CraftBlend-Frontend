import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Initial Camera Position for Palestine
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(31.9522, 35.2332), // Coordinates of Palestine
    zoom: 8.0, // Adjust zoom level as needed
  );

  late GoogleMapController _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CraftBlend Map"),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        myLocationEnabled: false,
      ),
    );
  }
}
