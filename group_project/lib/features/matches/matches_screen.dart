import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile/view_profile_screen.dart';
import '../chat/chat_screen.dart';
import 'map_screen.dart';

// Utility to generate a stable conversation ID between two users
String generateConversationId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return "${sorted[0]}_${sorted[1]}";
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> _getMatches() async {
    if (currentUser == null) return [];

    final usersRef = FirebaseFirestore.instance.collection('users');
    final snapshot = await usersRef.get();

    // Current user data
    final currentData =
    snapshot.docs.firstWhere((d) => d.id == currentUser!.uid).data();

    final myOffered = currentData['skillsHave'] != null
        ? [currentData['skillsHave'].toString()]
        : [];
    final myWanted = currentData['skillsWant'] != null
        ? [currentData['skillsWant'].toString()]
        : [];

    List<Map<String, dynamic>> matches = [];

    for (var doc in snapshot.docs) {
      if (doc.id == currentUser!.uid) continue;
      final other = doc.data();

      final otherOffered =
      other['skillsHave'] != null ? [other['skillsHave'].toString()] : [];
      final otherWanted =
      other['skillsWant'] != null ? [other['skillsWant'].toString()] : [];

      bool iCanLearn = myWanted.any((skill) => otherOffered.contains(skill));
      bool iCanTeach = myOffered.any((skill) => otherWanted.contains(skill));

      if (iCanLearn && iCanTeach) {
        matches.add({
          "uid": doc.id,
          "name": other["name"] ?? "Unknown",
          "skillsHave": otherOffered,
          "skillsWant": otherWanted,
        });
      }
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommended Matches"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Center(child: Text("No matches found yet."));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Here are your recommended matches:",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match["name"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Teaches: ${match["skillsHave"].join(", ")}"),
                              Text(
                                  "Wants to Learn: ${match["skillsWant"].join(", ")}"),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ViewProfileScreen(
                                              userId: match["uid"],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text("View Profile"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final myUid = FirebaseAuth
                                            .instance.currentUser!.uid;
                                        final otherUid = match["uid"];

                                        final convoId =
                                        generateConversationId(
                                            myUid, otherUid);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                                conversationId: convoId),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text("Start Chat"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Load more matches...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("View More Matches"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MapScreen()), // <-- Go to map
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Filter by Location"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
