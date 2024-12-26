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
  String selectedCity = "Choose city"; // Default value for AddressWidget

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(31.9730, 35.2164), // Approximate center of Palestine
    zoom: 9, // Zoom level to fit the entire area
  );

  @override
  void initState() {
    super.initState();
    _fetchCities();

    // Automatically show location options when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationOptions();
    });
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
        _showSnackBar('Failed to load cities: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error fetching cities: $e');
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
            _onCityTap(city);
          },
        ),
      );
    }
    setState(() {});
  }

  Future<void> _onCityTap(Map<String, dynamic> city) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Save selected location
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLocation', city['name']);
    await prefs.setString('selectedLocationID', city['id']);

    // Close the loading dialog
    Navigator.pop(context); // Close loading dialog

    // Navigate to the User Navigation Bar Page
    Navigator.pushReplacementNamed(context, '/userNavBar');
  }

  Future<BitmapDescriptor> _createCustomCircularMarker(String assetPath) async {
    final ByteData data = await DefaultAssetBundle.of(context).load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 100, targetHeight: 100);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final double size = 120.0;
    final double imageSize = 100.0;

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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the Image
              /* Image.asset(
                'assets/images/location_icon.png', // Replace with your image path
                height: 100,
              ),
              const SizedBox(height: 20),
*/
              // Title
              const Text(
                "Choose your location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Share Location Option
              ListTile(
                leading: const Icon(Icons.my_location, color: myColor),
                title: const Text("Share location"),
                subtitle: const Text("Allow access to your current location"),
                onTap: () async {
                  bool permissionGranted = await _requestLocationPermission();
                  if (permissionGranted) {
                    // Fetch and handle location logic
                    _showSnackBar("Fetching current location...");
                  } else {
                    _showSnackBar(
                        "Location permission is required to proceed.");
                  }
                },
              ),
              const Divider(),

              // Choose Location Manually Option
              ListTile(
                leading: const Icon(Icons.location_city, color: myColor),
                title: const Text("Choose location manually"),
                subtitle: const Text("Select your location from the map"),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _requestLocationPermission() async {
    // Add location permission request logic here
    return true; // Placeholder for permission granted
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.08;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: myColor,
        title: AddressWidget(
          firstLineText: 'Palestine,',
          secondLineText: selectedCity,
          onTap: _showLocationOptions, // Pass the method to handle tap
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
        minMaxZoomPreference: const MinMaxZoomPreference(8, 16),
        onTap: (LatLng position) {
          _showSnackBar('We do not operate in this location yet.');
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
