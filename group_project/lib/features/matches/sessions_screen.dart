import 'package:flutter/material.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  final String matchId;
  final String matchName;

  const SessionsScreen({
    super.key,
    required this.matchId,
    required this.matchName,
  });

  // Mock sessions data based on matchId
  List<Map<String, dynamic>> _getMockSessions(String matchId) {
    final Map<String, List<Map<String, dynamic>>> sessionsByMatch = {
      'match1': [ // Alice
        {
          'id': 'session1_1',
          'title': 'Guitar Basics Introduction',
          'date': '2023-12-05',
          'time': '14:30',
          'duration': '2 hours',
          'location': 'Coffee Corner, Main St',
          'skills': ['Guitar Chords', 'Basic Strumming'],
          'status': 'completed',
          'notes': 'Great first session! Alice taught me basic chords (G, C, D). I helped her with piano scales.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session1_2', 
          'title': 'Chord Progressions & Piano Techniques',
          'date': '2023-12-12',
          'time': '15:00',
          'duration': '2.5 hours',
          'location': 'Alice\'s Home Studio',
          'skills': ['Chord Progressions', 'Piano Dynamics'],
          'status': 'completed',
          'notes': 'Learned common progressions (vi-IV-I-V). Alice improved her pedal technique on piano.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session1_3',
          'title': 'Song Practice Session',
          'date': '2024-01-08',
          'time': '16:00', 
          'duration': '3 hours',
          'location': 'Music Room, Community Center',
          'skills': ['Song Performance', 'Rhythm Coordination'],
          'status': 'completed',
          'notes': 'Practiced "Wonderwall" together. Great progress on both instruments!',
          'rating': 4,
          'type': 'in-person',
        },
        {
          'id': 'session1_4',
          'title': 'Advanced Techniques',
          'date': '2024-01-15',
          'time': '14:00',
          'duration': '2 hours',
          'location': 'Online (Zoom)',
          'skills': ['Fingerpicking', 'Advanced Piano Chords'],
          'status': 'completed',
          'notes': 'Virtual session worked well. Focused on more complex techniques.',
          'rating': 4,
          'type': 'virtual',
        },
      ],
      'match2': [ // Bob
        {
          'id': 'session2_1',
          'title': 'Python Fundamentals',
          'date': '2023-11-18',
          'time': '19:00',
          'duration': '2 hours',
          'location': 'Central Library, Study Room B',
          'skills': ['Python Basics', 'JavaScript ES6'],
          'status': 'completed',
          'notes': 'Bob explained Python data structures. I showed him modern JavaScript features.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session2_2',
          'title': 'Web Development Deep Dive',
          'date': '2023-11-25',
          'time': '18:30',
          'duration': '3 hours',
          'location': 'Bob\'s Office',
          'skills': ['Django Framework', 'React Hooks'],
          'status': 'completed',
          'notes': 'Hands-on coding session. Built small projects together.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session2_3',
          'title': 'API Development Workshop',
          'date': '2023-12-15',
          'time': '20:00',
          'duration': '2.5 hours',
          'location': 'Online (Discord)',
          'skills': ['REST APIs', 'Database Integration'],
          'status': 'completed',
          'notes': 'Virtual coding session. Screen sharing made it easy to collaborate.',
          'rating': 4,
          'type': 'virtual',
        },
        {
          'id': 'session2_4',
          'title': 'Advanced Debugging Techniques',
          'date': '2024-01-05',
          'time': '19:30',
          'duration': '2 hours',
          'location': 'TechHub Coworking Space',
          'skills': ['Python Debugging', 'Chrome DevTools'],
          'status': 'completed',
          'notes': 'Learned professional debugging workflows. Very practical session.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session2_5',
          'title': 'Code Review & Best Practices',
          'date': '2024-01-10',
          'time': '18:00',
          'duration': '2 hours',
          'location': 'Coffee Bean Cafe',
          'skills': ['Code Quality', 'Git Workflows'],
          'status': 'completed',
          'notes': 'Reviewed each other\'s projects. Great feedback and learning experience.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session2_6',
          'title': 'Machine Learning Introduction',
          'date': '2024-01-18',
          'time': '19:00',
          'duration': '2.5 hours',
          'location': 'Online (Google Meet)',
          'skills': ['Scikit-learn', 'Data Visualization'],
          'status': 'scheduled',
          'notes': '',
          'rating': 0,
          'type': 'virtual',
        },
      ],
      'match3': [ // Carol - completed match
        {
          'id': 'session3_1',
          'title': 'Calligraphy Basics',
          'date': '2023-10-15',
          'time': '10:00',
          'duration': '2 hours',
          'location': 'Art Studio Downtown',
          'skills': ['Basic Strokes', 'Typography Principles'],
          'status': 'completed',
          'notes': 'Beautiful introduction to calligraphy. Carol is a natural teacher.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session3_2',
          'title': 'Advanced Lettering',
          'date': '2023-11-10',
          'time': '14:00',
          'duration': '3 hours',
          'location': 'Carol\'s Art Room',
          'skills': ['Modern Calligraphy', 'Digital Typography'],
          'status': 'completed',
          'notes': 'Combined traditional and digital techniques. Amazing progress made.',
          'rating': 5,
          'type': 'in-person',
        },
        {
          'id': 'session3_3',
          'title': 'Final Project Presentation',
          'date': '2023-12-20',
          'time': '16:00',
          'duration': '2 hours',
          'location': 'Community Art Gallery',
          'skills': ['Project Showcase', 'Peer Review'],
          'status': 'completed',
          'notes': 'Showcased our final pieces. Both learned so much throughout this exchange!',
          'rating': 5,
          'type': 'in-person',
        },
      ],
    };

    return sessionsByMatch[matchId] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessions = _getMockSessions(matchId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions with $matchName'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: sessions.isEmpty
          ? _buildEmptyState(context, theme)
          : Padding(
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