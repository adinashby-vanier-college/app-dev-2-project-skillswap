import 'package:flutter/material.dart';
import 'sessions_screen.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  // Mock data based on existing conversation users
  static final List<Map<String, dynamic>> _mockMatches = [
    {
      'id': 'match1',
      'name': 'Alice',
      'avatar': 'A',
      'skillsExchanged': ['Guitar', 'Piano'],
      'totalSessions': 4,
      'lastSessionDate': '2024-01-15',
      'status': 'active',
      'matchDate': '2023-12-01',
    },
    {
      'id': 'match2', 
      'name': 'Bob',
      'avatar': 'B',
      'skillsExchanged': ['Python', 'JavaScript'],
      'totalSessions': 6,
      'lastSessionDate': '2024-01-10',
      'status': 'active',
      'matchDate': '2023-11-15',
    },
    {
      'id': 'match3',
      'name': 'Carol',
      'avatar': 'C', 
      'skillsExchanged': ['Calligraphy', 'Typography'],
      'totalSessions': 3,
      'lastSessionDate': '2023-12-20',
      'status': 'completed',
      'matchDate': '2023-10-10',
    },
    {
      'id': 'match4',
      'name': 'Dave',
      'avatar': 'D',
      'skillsExchanged': ['Italian Cooking', 'Baking'],
      'totalSessions': 5,
      'lastSessionDate': '2024-01-08',
      'status': 'active',
      'matchDate': '2023-11-20',
    },
    {
      'id': 'match5',
      'name': 'Eve',
      'avatar': 'E',
      'skillsExchanged': ['Watercolor', 'Sketching'],
      'totalSessions': 2,
      'lastSessionDate': '2023-11-25',
      'status': 'paused',
      'matchDate': '2023-10-05',
    },
    {
      'id': 'match6',
      'name': 'Frank',
      'avatar': 'F',
      'skillsExchanged': ['Juggling', 'Magic Tricks'],
      'totalSessions': 3,
      'lastSessionDate': '2024-01-12',
      'status': 'active',
      'matchDate': '2023-12-10',
    },
  ];

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
                color: colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _mockMatches.length,
                itemBuilder: (context, index) {
                  final match = _mockMatches[index];
                  return _buildMatchCard(context, match, theme);
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
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withAlpha(50),
                child: Text(
                  match['avatar'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
                        color: colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${match['totalSessions']} sessions',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Last: ${_formatDate(match['lastSessionDate'])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withAlpha(153),
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
                color: colorScheme.onSurface.withAlpha(100),
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