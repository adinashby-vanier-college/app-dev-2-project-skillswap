import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewProfileScreen extends StatelessWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final userData = snapshot.data;
          if (userData == null) {
            return const Center(child: Text("User not found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData["name"] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Email: ${userData["email"] ?? "N/A"}"),
                Text("Location: ${userData["location"] ?? "N/A"}"),
                const SizedBox(height: 16),
                Text("Skills Have: ${userData["skillsHave"] ?? "None"}"),
                Text("Skills Want: ${userData["skillsWant"] ?? "None"}"),
                const SizedBox(height: 20),
                Text("Bio: ${userData["bio"] ?? "No bio"}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
