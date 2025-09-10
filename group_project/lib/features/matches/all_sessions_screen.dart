import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_detail_screen.dart';
import '../chat/session_service.dart';

/// Screen displaying all booked sessions for the user.
class AllSessionsScreen extends StatelessWidget {
  const AllSessionsScreen({super.key});

  static final SessionService _sessionService = SessionService();

  // Keep some mock data as fallback, but will primarily use real data
  static final List<Map<String, dynamic>> _fallbackMockSessions = [
    // Recent/Upcoming sessions first
    {
      'id': 'session2_6',
      'title': 'Machine Learning Introduction',
      'partner': 'Bob',
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
    {
      'id': 'session1_4',
      'title': 'Advanced Techniques',
      'partner': 'Alice',
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
    {
      'id': 'session1_6',
      'title': 'Juggling Workshop',
      'partner': 'Frank',
      'date': '2024-01-12',
      'time': '15:30',
      'duration': '1.5 hours',
      'location': 'City Park',
      'skills': ['Basic Juggling', 'Hand-Eye Coordination'],
      'status': 'completed',
      'notes': 'Fun outdoor session! Frank is a great teacher.',
      'rating': 5,
      'type': 'in-person',
    },
    {
      'id': 'session2_5',
      'title': 'Code Review & Best Practices',
      'partner': 'Bob',
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
      'id': 'session1_3',
      'title': 'Song Practice Session',
      'partner': 'Alice',
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
      'id': 'session2_4',
      'title': 'Advanced Debugging Techniques',
      'partner': 'Bob',
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
    // Older sessions
    {
      'id': 'session3_3',
      'title': 'Final Project Presentation',
      'partner': 'Carol',
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
    {
      'id': 'session2_3',
      'title': 'API Development Workshop',
      'partner': 'Bob',
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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sessions'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _sessionService.getBookedSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading sessions: ${snapshot.error}'),
            );
          }

          // Combine real booked sessions with mock data for demonstration
          final bookedSessions = snapshot.data ?? [];
          final allSessions = [...bookedSessions, ..._fallbackMockSessions];
          
          // Group sessions by status (exclude cancelled sessions)
          final scheduledSessions = allSessions.where((s) => s['status'] == 'scheduled').toList();
          final completedSessions = allSessions.where((s) => s['status'] == 'completed').toList();
          // Note: cancelled sessions are intentionally excluded from both lists

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: theme.cardColor,
                  child: TabBar(
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 153/255),
                    indicatorColor: colorScheme.primary,
                    tabs: [
                      Tab(
                        text: 'Upcoming (${scheduledSessions.length})',
                      ),
                      Tab(
                        text: 'Past (${completedSessions.length})',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSessionsList(context, scheduledSessions, theme),
                      _buildSessionsList(context, completedSessions, theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, List<Map<String, dynamic>> sessions, ThemeData theme) {
    if (sessions.isEmpty) {
      return _buildEmptyState(context, theme, 'No sessions found');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(context, session, theme);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 100/255),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 153/255),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start matching with people to schedule sessions',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 128/255),
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
              // Header row with title, partner, and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<String>(
                          future: _getPartnerName(session),
                          builder: (context, snapshot) {
                            final partnerName = snapshot.data ?? session['partner'] ?? 'Unknown Partner';
                            return Text(
                              'with $partnerName',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
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
                    color: colorScheme.onSurface.withValues(alpha: 153/255),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(session['date'])} at ${session['time']}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 178/255),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 153/255),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session['duration'],
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 178/255),
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
                    color: colorScheme.onSurface.withValues(alpha: 153/255),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session['location'],
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 178/255),
                      ),
                    ),
                  ),
                  if (isVirtual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 51/255),
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
                  color: colorScheme.onSurface.withValues(alpha: 153/255),
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
                        color: colorScheme.onSurface.withValues(alpha: 153/255),
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

  Future<String> _getPartnerName(Map<String, dynamic> session) async {
    // If it's mock data with a 'partner' field, use that
    if (session.containsKey('partner')) {
      return session['partner'];
    }

    // For real booked sessions, get partner from participants list
    final participants = session['participants'] as List<dynamic>?;
    if (participants != null) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final partnerId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => null,
      );

      if (partnerId != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(partnerId)
              .get();
          
          return userDoc.data()?['name']?.toString() ?? 'Unknown Partner';
        } catch (e) {
          return 'Unknown Partner';
        }
      }
    }

    return 'Unknown Partner';
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
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference == -1) return 'Tomorrow';
      if (difference < 0 && difference > -7) return 'In ${(-difference)} days';
      
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateStr;
    }
  }
}