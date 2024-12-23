import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui; // Import dart:ui for custom drawing
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../configuration/config.dart';
import '../components/addressWidget.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  List<Marker> _markers = []; // List to hold markers
  List<Map<String, dynamic>> cities = []; // Cities data

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(31.9730, 35.2164), // Approximate center of Palestine
    zoom: 9, // Zoom level to fit the entire area
  );

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      var url = Uri.parse(getAllCities);
      var response = await http.get(url);

      if (response.statusCode == 200 && response.body.contains('cities')) {
        final List<dynamic> cityList = jsonDecode(response.body)['cities'];
        setState(() {
          cities = cityList.map((city) {
            return {
              'id': city['_id'].toString(),
              'name': city['name'],
              'latitude': city['coordinates']['latitude'],
              'longitude': city['coordinates']['longitude'],
              'storesCount': city['storesCount'],
            };
          }).toList();

          // Add markers for cities with storesCount > 0
          _createMarkers();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cities: $e')),
      );
    }
  }

  Future<void> _createMarkers() async {
    for (var city in cities.where((city) => city['storesCount'] > 0)) {
      final BitmapDescriptor customIcon =
          await _createCustomCircularMarker('assets/images/logo.png');
      _markers.add(
        Marker(
          markerId: MarkerId(city['id']),
          position: LatLng(city['latitude'], city['longitude']),
          infoWindow: InfoWindow(
            title: city['name'],
            snippet: '${city['storesCount']} stores',
          ),
          icon: customIcon,
          onTap: () async {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible:
                  false, // Prevent dismissing by tapping outside
              builder: (BuildContext context) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );

            // Simulate a short delay (e.g., 1 second) to show loading
            await Future.delayed(const Duration(seconds: 1));

            // Save selected location
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('selectedLocation', city['name']);

            // Dismiss the loading dialog
            Navigator.pop(context); // Close the loading dialog
            Navigator.pop(context); // Navigate back to the main page
          },
        ),
      );
    }
    setState(() {});
  }

  Future<BitmapDescriptor> _createCustomCircularMarker(String assetPath) async {
    final ByteData data = await DefaultAssetBundle.of(context).load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 100, targetHeight: 100);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final double size = 120.0; // Total size of the circular marker
    final double imageSize = 100.0; // Size of the inner image

    final Paint backgroundPaint = Paint()..color = myColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, backgroundPaint);

    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2), radius: imageSize / 2));
    canvas.clipPath(clipPath);

    final Rect imageRect = Rect.fromLTWH(
      (size - imageSize) / 2,
      (size - imageSize) / 2,
      imageSize,
      imageSize,
    );
    canvas.drawImageRect(
      frameInfo.image,
      Rect.fromLTWH(0, 0, frameInfo.image.width.toDouble(),
          frameInfo.image.height.toDouble()),
      imageRect,
      Paint(),
    );

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List markerBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(markerBytes);
  }

  void _showUnavailableLocationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We do not operate in this location yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // Show back button
        centerTitle: true,
        backgroundColor: myColor,
        title: AddressWidget(
          firstLineText: 'Choose Location',
          onTap: () {
            print("AddressWidget tapped in MapPage");
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _setMapStyle();
        },
        markers: Set.from(_markers),
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        minMaxZoomPreference:
            const MinMaxZoomPreference(8, 16), // Restrict zoom levels
        onTap: (LatLng position) {
          _showUnavailableLocationMessage();
        },
      ),
    );
  }

  void _setMapStyle() async {
    try {
      String mapStyle = await DefaultAssetBundle.of(context)
          .loadString('assets/json/map_style.json');
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
