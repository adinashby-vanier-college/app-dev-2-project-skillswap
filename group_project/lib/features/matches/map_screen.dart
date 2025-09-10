import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../profile/view_profile_screen.dart';

/// Screen displaying users on a map based on their location.
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

  // Create custom marker with profile photo
  Future<BitmapDescriptor> _createProfileMarker(String? photoUrl, String userName) async {
    try {
      // Create a custom painter for the circular profile marker
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 60.0;
      
      // Draw the outer circle (border)
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);
      
      // Draw the inner circle for the photo
      final Paint photoPaint = Paint()
        ..color = Colors.blue.shade300
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), (size / 2) - 4, photoPaint);
      
      // If no photo URL, draw initials
      if (photoUrl == null || photoUrl.isEmpty) {
        final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: initial,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (size - textPainter.width) / 2,
            (size - textPainter.height) / 2,
          ),
        );
      }
      
      // Add a small shadow/border effect
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 51/255)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, shadowPaint);
      
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      return BitmapDescriptor.bytes(pngBytes);
    } catch (e) {
      debugPrint('Error creating profile marker: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
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
        // New format with location object containing latitude/longitude
        try {
          final location = data['location'] as Map<String, dynamic>;
          lat = location['latitude']?.toDouble();
          lng = location['longitude']?.toDouble();
        } catch (e) {
          // Silently handle parsing errors
        }
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

      // Apply matching logic - use same logic as MatchesScreen (mutual matches)
      bool iCanLearn = myWanted.any((skill) => otherOffered.contains(skill));
      bool iCanTeach = myOffered.any((skill) => otherWanted.contains(skill));

      // Only show users who are mutual matches (same as MatchesScreen)
      if (iCanLearn && iCanTeach) {
        final userId = doc.id;
        final userName = data['name'] ?? "Unknown";
        final photoUrl = data['photoUrl'] as String?;
        
        String teaches = otherOffered.join(", ");
        String wants = otherWanted.join(", ");

        // Create custom profile marker
        final customMarker = await _createProfileMarker(photoUrl, userName);

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
            icon: customMarker,
            onTap: () {
              // Optional: Show a bottom sheet with more details when marker is tapped
              _showUserBottomSheet(context, userId, userName, teaches, wants);
            },
          ),
        );
      }
    }

    setState(() {});
  }

  void _showUserBottomSheet(BuildContext context, String userId, String userName, String teaches, String wants) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 51/255),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withValues(alpha: 51/255),
                      child: Text(
                        userName[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkillSection(context, 'Teaches', teaches, Icons.school, Colors.green),
                const SizedBox(height: 12),
                _buildSkillSection(context, 'Wants to Learn', wants, Icons.lightbulb, Colors.orange),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewProfileScreen(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('View Full Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillSection(BuildContext context, String title, String skills, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 25/255),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 102/255)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skills.isNotEmpty ? skills : 'No skills listed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
