import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';
import '../../widgets/profile_avatar.dart';

/// Screen for viewing another user's profile.
class ViewProfileScreen extends StatelessWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  /// Generates stable conversation ID from two user IDs.
  String generateConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          }
          final userData = snapshot.data;
          if (userData == null) {
            return _buildErrorState(context, "User not found");
          }

          final name = userData["name"] ?? "Unknown User";
          final bio = userData["bio"] ?? "No bio available";
          final location = _formatLocation(userData["location"]);
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(alpha: 100/255),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          ProfileAvatar(
                            size: 100,
                            displayName: name,
                            backgroundColor: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(alpha: 153/255),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 153/255),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(
                        context,
                        title: "About",
                        icon: Icons.person,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bio,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSkillsCard(
                        context,
                        title: "Skills I Can Teach",
                        icon: Icons.school,
                        skills: _formatSkills(userData["skillsHave"]),
                        color: Colors.green,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSkillsCard(
                        context,
                        title: "Skills I Want to Learn",
                        icon: Icons.lightbulb,
                        skills: _formatSkills(userData["skillsWant"]),
                        color: Colors.blue,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 51/255),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _startChat(context),
                          icon: const Icon(Icons.chat),
                          label: const Text(
                            "Start Conversation",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 100/255),
            ),
            const SizedBox(height: 16),
            Text(
              "Profile Unavailable",
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 153/255),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 128/255),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> skills,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Text(
                "No skills listed",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 128/255),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) => _buildSkillChip(context, skill, color)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 51/255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 128/255)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: color.withValues(alpha: 204/255),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<String> _formatSkills(dynamic skills) {
    if (skills == null) return [];
    
    if (skills is List) {
      return skills.map((skill) => skill.toString()).toList();
    } else if (skills is String && skills.isNotEmpty) {
      return [skills];
    }
    
    return [];
  }

  String _formatLocation(dynamic location) {
    if (location == null) return "";
    
    if (location is Map) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      if (lat != null && lng != null) {
        return "Montreal Area";
      }
    }
    
    return location.toString();
  }

  void _startChat(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final convoId = generateConversationId(myUid, userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: convoId),
      ),
    );
  }
}
