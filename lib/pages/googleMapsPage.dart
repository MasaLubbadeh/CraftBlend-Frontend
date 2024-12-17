import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;

  // Initial Camera Position to show the entire Palestine map
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(31.9730, 35.2164), // Approximate center of Palestine
    zoom: 9, // Zoom level to fit the entire area
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palestine Map'),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;

          // Apply the custom map style
          _setMapStyle();
        },
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        minMaxZoomPreference:
            const MinMaxZoomPreference(8, 16), // Restrict zoom levels
      ),
    );
  }

  void _setMapStyle() async {
    try {
      // Load the JSON string from the assets folder
      String mapStyle =
          await rootBundle.loadString('assets/json/map_style.json');

      // Set the custom map style
      _mapController?.setMapStyle(mapStyle);
    } catch (e) {
      print('Error loading map style: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
