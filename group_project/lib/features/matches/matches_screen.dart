import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile/view_profile_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_service.dart';
import 'map_screen.dart';

// Utility to generate a stable conversation ID between two users
String generateConversationId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return "${sorted[0]}_${sorted[1]}";
}

class MatchesScreen extends StatefulWidget {
  final String? searchQuery;
  
  const MatchesScreen({super.key, this.searchQuery});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final ChatService _chatService = ChatService();

  Future<List<Map<String, dynamic>>> _getMatches() async {
    if (currentUser == null) return [];

    final usersRef = FirebaseFirestore.instance.collection('users');
    final snapshot = await usersRef.get();
    
    debugPrint('Debug: Total users in database: ${snapshot.docs.length}');

    // Current user data
    final currentData =
    snapshot.docs.firstWhere((d) => d.id == currentUser!.uid).data();

    // Handle both old format (string) and new format (array)
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

    debugPrint('Debug: My skills - Have: $myOffered, Want: $myWanted');

    List<Map<String, dynamic>> matches = [];

    for (var doc in snapshot.docs) {
      if (doc.id == currentUser!.uid) continue;
      final other = doc.data();

      // Handle both old format (string) and new format (array) for other users
      List<String> otherOffered = [];
      List<String> otherWanted = [];
      
      final otherSkillsHaveData = other['skillsHave'];
      final otherSkillsWantData = other['skillsWant'];
      
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

      final matchData = {
        "uid": doc.id,
        "name": other["name"] ?? "Unknown",
        "skillsHave": otherOffered,
        "skillsWant": otherWanted,
      };

      // If search query provided, search all users (bypass matching logic)
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final query = widget.searchQuery!.toLowerCase();
        final name = matchData["name"].toString().toLowerCase();
        final skillsHave = otherOffered.join(" ").toLowerCase();
        final skillsWant = otherWanted.join(" ").toLowerCase();
        
        if (name.contains(query) || 
            skillsHave.contains(query) || 
            skillsWant.contains(query)) {
          matches.add(matchData);
        }
      } else {
        // No search query - use normal matching logic
        bool iCanLearn = myWanted.any((skill) => otherOffered.contains(skill));
        bool iCanTeach = myOffered.any((skill) => otherWanted.contains(skill));

        debugPrint('Debug: Checking ${other["name"]} - Can Learn: $iCanLearn, Can Teach: $iCanTeach');
        debugPrint('  Their skills: Have: $otherOffered, Want: $otherWanted');

        if (iCanLearn && iCanTeach) {
          matches.add(matchData);
        }
      }
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
            ? "Everyone with '${widget.searchQuery}'" 
            : "Recommended Matches"),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No matches found yet."),
                  const SizedBox(height: 20),
                  Text("Debug: Found ${matches.length} matches"),
                  const Text("Make sure you have skills added in Edit Skills!"),
                ],
              ),
            );
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
                                      onPressed: () async {
                                        final myUid = FirebaseAuth
                                            .instance.currentUser!.uid;
                                        final otherUid = match["uid"];

                                        final convoId =
                                        generateConversationId(
                                            myUid, otherUid);

                                        try {
                                          // Initialize the conversation first
                                          await _chatService.initializeConversation(convoId);
                                          
                                          if (!mounted) return;
                                          if (!context.mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                  conversationId: convoId),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to start chat: $e')),
                                          );
                                        }
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
                // Enhanced Map Button with better visibility
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 76/255),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MapScreen()),
                      );
                    },
                    icon: const Icon(Icons.map, size: 24),
                    label: const Text(
                      "View on Map",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("View More Matches"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
