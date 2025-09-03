import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  final String matchId;
  final String matchName;

  const SessionsScreen({
    super.key,
    required this.matchId,
    required this.matchName,
  });

  Future<List<Map<String, dynamic>>> _generateMockSessions(String userId, String userName) async {
    try {
      // Get user data to generate relevant session content
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        return [];
      }

      // Extract user's skills to generate realistic session content
      final skillsHave = userData['skillsHave'] is List 
          ? List<String>.from(userData['skillsHave'] ?? [])
          : userData['skillsHave'] is String 
              ? [userData['skillsHave']] 
              : <String>[];
      
      final skillsWant = userData['skillsWant'] is List 
          ? List<String>.from(userData['skillsWant'] ?? [])
          : userData['skillsWant'] is String 
              ? [userData['skillsWant']] 
              : <String>[];

      // Generate sessions based on user data
      final List<Map<String, dynamic>> sessions = [];
      final statuses = ['completed', 'completed', 'completed', 'scheduled'];
      final locations = [
        'Coffee Corner, Main St',
        '$userName\'s Home',
        'Community Center',
        'Online (Zoom)',
        'Central Library',
        'Local Park Pavilion',
      ];
      final times = ['14:30', '15:00', '16:00', '19:00', '18:30', '10:00'];
      final durations = ['2 hours', '2.5 hours', '3 hours', '1.5 hours'];
      
      // Create 3-5 sessions
      final sessionCount = 3 + (userId.hashCode.abs() % 3);
      
      for (int i = 0; i < sessionCount; i++) {
        final sessionSkills = <String>[];
        
        // Add some of their offered skills
        if (skillsHave.isNotEmpty) {
          sessionSkills.add(skillsHave[i % skillsHave.length]);
        }
        
        // Add some skills they want to learn
        if (skillsWant.isNotEmpty && sessionSkills.length < 2) {
          sessionSkills.add(skillsWant[i % skillsWant.length]);
        }
        
        // Fallback skills if no skills in profile
        if (sessionSkills.isEmpty) {
          final fallbackSkills = ['General Discussion', 'Knowledge Exchange', 'Practice Session'];
          sessionSkills.add(fallbackSkills[i % fallbackSkills.length]);
        }
        
        final isVirtual = (i == 1 || i == 3); // Make some sessions virtual
        final status = i < sessionCount - 1 ? 'completed' : statuses[i % statuses.length];
        
        // Generate session date (going backwards from recent)
        final daysAgo = 10 + (i * 15) + (userId.hashCode.abs() % 10);
        final sessionDate = DateTime.now().subtract(Duration(days: daysAgo));
        
        sessions.add({
          'id': 'session_${userId}_$i',
          'title': _generateSessionTitle(sessionSkills, i + 1),
          'date': sessionDate.toIso8601String().split('T')[0],
          'time': times[i % times.length],
          'duration': durations[i % durations.length],
          'location': isVirtual ? 'Online (${["Zoom", "Google Meet", "Discord"][i % 3]})' : locations[i % locations.length],
          'skills': sessionSkills,
          'status': status,
          'notes': status == 'completed' ? _generateNotes(userName, sessionSkills, i + 1) : '',
          'rating': status == 'completed' ? (4 + (i % 2)) : 0,
          'type': isVirtual ? 'virtual' : 'in-person',
        });
      }
      
      // Sort by date (most recent first)
      sessions.sort((a, b) => b['date'].compareTo(a['date']));
      
      return sessions;
    } catch (e) {
      return [];
    }
  }

  String _generateSessionTitle(List<String> skills, int sessionNumber) {
    if (skills.isEmpty) return 'Session $sessionNumber';
    
    final titlePrefixes = [
      'Introduction to',
      'Deep Dive into',
      'Advanced',
      'Practical',
      'Hands-on',
      'Workshop on',
    ];
    
    final prefix = titlePrefixes[(sessionNumber - 1) % titlePrefixes.length];
    final mainSkill = skills.first;
    
    return '$prefix $mainSkill';
  }

  String _generateNotes(String userName, List<String> skills, int sessionNumber) {
    final noteTemplates = [
      'Great session with $userName! Made excellent progress with ${skills.join(" and ")}.',
      'Really enjoyed working with $userName on ${skills.join(" and ")}. Very knowledgeable!',
      '$userName is an amazing teacher! Learned so much about ${skills.join(" and ")}.',
      'Productive session focused on ${skills.join(" and ")}. Both of us improved significantly.',
      'Fantastic exchange with $userName. The skills sharing in ${skills.join(" and ")} was very effective.',
    ];
    
    return noteTemplates[(sessionNumber - 1) % noteTemplates.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions with $matchName'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _generateMockSessions(matchId, matchName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading sessions: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }
          
          final sessions = snapshot.data ?? [];
          
          if (sessions.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skill exchange sessions',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _buildSessionCard(context, session, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule your first session with $matchName',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final status = session['status'] as String;
    
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final isVirtual = session['type'] == 'virtual';

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
              builder: (context) => SessionDetailScreen(session: session),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(session['date'])} at ${session['time']}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session['duration'],
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Location with type indicator
              Row(
                children: [
                  Icon(
                    isVirtual ? Icons.videocam : Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session['location'],
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ),
                  if (isVirtual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Virtual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Skills
              Text(
                'Skills: ${_formatSkills(session['skills'])}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
              ),
              
              // Rating for completed sessions
              if (status == 'completed' && session['rating'] > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < session['rating'] ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${session['rating']}/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSkills(dynamic skills) {
    if (skills == null) return '';
    if (skills is List) {
      return skills.map((skill) => skill.toString()).join(', ');
    }
    return skills.toString();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}