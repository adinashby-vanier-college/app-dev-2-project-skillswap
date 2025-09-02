import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/view_profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(45.5019, -73.5674); // Default: Montreal
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserMarkers();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );
  }

  Future<void> _loadUserMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Try both formats - old format (lat/lng) and new format (location object)
      double? lat, lng;
      
      if (data['lat'] != null && data['lng'] != null) {
        // Old format
        lat = data['lat']?.toDouble();
        lng = data['lng']?.toDouble();
      } else if (data['location'] != null) {
        // New format 
        final location = data['location'] as Map<String, dynamic>;
        lat = location['latitude']?.toDouble();
        lng = location['longitude']?.toDouble();
      }

      // Skip if no valid coordinates
      if (lat == null || lng == null) continue;

      final userId = doc.id;
      final userName = data['name'] ?? "Unknown";
      
      // Handle both old format (string) and new format (array) for skills
      String teaches = "";
      String wants = "";
      
      final skillsHaveData = data['skillsHave'];
      final skillsWantData = data['skillsWant'];
      
      if (skillsHaveData is List) {
        teaches = skillsHaveData.join(", ");
      } else if (skillsHaveData is String) {
        teaches = skillsHaveData;
      }
      
      if (skillsWantData is List) {
        wants = skillsWantData.join(", ");
      } else if (skillsWantData is String) {
        wants = skillsWantData;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(userId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: userName,
            snippet: "Teaches: $teaches | Wants: $wants",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(userId: userId),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Filter by Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 12,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
