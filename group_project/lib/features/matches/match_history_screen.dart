import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sessions_screen.dart';
import '../profile/view_profile_screen.dart';

/// Screen displaying user's match history.
class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  Future<List<Map<String, dynamic>>> _loadMockMatches() async {
    try {
      // Get all users from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('users').limit(6).get();
      
      final List<Map<String, dynamic>> matches = [];
      final statuses = ['active', 'completed', 'paused'];
      final skillExamples = [
        ['Guitar', 'Piano'],
        ['Python', 'JavaScript'],
        ['Calligraphy', 'Typography'],
        ['Italian Cooking', 'Baking'],
        ['Watercolor', 'Sketching'],
        ['Juggling', 'Magic Tricks'],
      ];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final userData = doc.data();
        final name = userData['name'] ?? 'Unknown User';
        
        matches.add({
          'id': doc.id, // Use real Firestore document ID
          'name': name,
          'avatar': name.isNotEmpty ? name[0].toUpperCase() : '?',
          'skillsExchanged': skillExamples[i % skillExamples.length],
          'totalSessions': (i + 1) * 2 + (i % 3),
          'lastSessionDate': _generateRandomDate(),
          'status': statuses[i % statuses.length],
          'matchDate': _generateRandomMatchDate(),
        });
      }
      
      return matches;
    } catch (e) {
      // Fallback to empty list if Firestore fails
      return [];
    }
  }

  String _generateRandomDate() {
    final now = DateTime.now();
    final daysAgo = [1, 5, 12, 20, 35, 45][DateTime.now().millisecond % 6];
    final date = now.subtract(Duration(days: daysAgo));
    return date.toIso8601String().split('T')[0];
  }

  String _generateRandomMatchDate() {
    final now = DateTime.now();
    final daysAgo = [30, 45, 60, 80, 100, 120][DateTime.now().millisecond % 6];
    final date = now.subtract(Duration(days: daysAgo));
    return date.toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your skill exchange partners',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 153/255),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadMockMatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading matches: ${snapshot.error}',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    );
                  }
                  
                  final matches = snapshot.data ?? [];
                  
                  if (matches.isEmpty) {
                    return Center(
                      child: Text(
                        'No matches found. Create some users first!',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 153/255),
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _buildMatchCard(context, match, theme);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final status = match['status'] as String;
    
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.play_circle_outline;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'paused':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionsScreen(
                matchId: match['id'],
                matchName: match['name'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar - clickable to view profile
              GestureDetector(
                onTap: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(userId: match['id']),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening profile: $e')),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary.withValues(alpha: 50/255),
                  child: Text(
                    match['avatar'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Match details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          statusIcon,
                          size: 18,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Skills: ${match['skillsExchanged'].join(', ')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 178/255),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${match['totalSessions']} sessions',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 153/255),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Last: ${_formatDate(match['lastSessionDate'])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 153/255),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 100/255),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference < 30) return '${difference}d ago';
      if (difference < 365) return '${(difference / 30).round()}mo ago';
      return '${(difference / 365).round()}y ago';
    } catch (e) {
      return dateStr;
    }
  }
}