import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final currentUser = FirebaseAuth.instance.currentUser;

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
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
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    // Get current user's skills for matching
    final currentData = snapshot.docs.firstWhere((d) => d.id == currentUser!.uid).data();
    
    // Handle both old format (string) and new format (array) for current user
    List<String> myOffered = [];
    List<String> myWanted = [];
    
    final skillsHaveData = currentData['skillsHave'];
    final skillsWantData = currentData['skillsWant'];
    
    if (skillsHaveData is List) {
      myOffered = List<String>.from(skillsHaveData);
    } else if (skillsHaveData is String && skillsHaveData.isNotEmpty) {
      myOffered = [skillsHaveData];
    }
    
    if (skillsWantData is List) {
      myWanted = List<String>.from(skillsWantData);
    } else if (skillsWantData is String && skillsWantData.isNotEmpty) {
      myWanted = [skillsWantData];
    }

    for (var doc in snapshot.docs) {
      // Skip current user
      if (doc.id == currentUser!.uid) continue;
      
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

      // Handle both old format (string) and new format (array) for other users
      List<String> otherOffered = [];
      List<String> otherWanted = [];
      
      final otherSkillsHaveData = data['skillsHave'];
      final otherSkillsWantData = data['skillsWant'];
      
      if (otherSkillsHaveData is List) {
        otherOffered = List<String>.from(otherSkillsHaveData);
      } else if (otherSkillsHaveData is String && otherSkillsHaveData.isNotEmpty) {
        otherOffered = [otherSkillsHaveData];
      }
      
      if (otherSkillsWantData is List) {
        otherWanted = List<String>.from(otherSkillsWantData);
      } else if (otherSkillsWantData is String && otherSkillsWantData.isNotEmpty) {
        otherWanted = [otherSkillsWantData];
      }

      // Apply matching logic - only show users who are mutual matches
      bool iCanLearn = myWanted.any((skill) => otherOffered.contains(skill));
      bool iCanTeach = myOffered.any((skill) => otherWanted.contains(skill));

      // Only add marker if both conditions are met (mutual match)
      if (iCanLearn && iCanTeach) {
        final userId = doc.id;
        final userName = data['name'] ?? "Unknown";
        
        String teaches = otherOffered.join(", ");
        String wants = otherWanted.join(", ");

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
