import 'package:flutter/material.dart';
import '../models/session_proposal.dart';
import '../session_service.dart';

/// Widget for displaying session proposals in chat.
class SessionProposalWidget extends StatelessWidget {
  final SessionProposal proposal;
  final String currentUserId;

  const SessionProposalWidget({
    super.key,
    required this.proposal,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isProposer = proposal.proposerId == currentUserId;
    final isVirtual = proposal.type == 'virtual';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (proposal.status) {
      case SessionProposalStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending Response';
        break;
      case SessionProposalStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        break;
      case SessionProposalStatus.declined:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Declined';
        break;
      case SessionProposalStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = 'Cancelled';
        break;
      case SessionProposalStatus.expired:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        statusText = 'Expired';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 100/255),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 20/255),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_note,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isProposer ? 'Session Proposal Sent' : 'Session Proposal Received',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 51/255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            proposal.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skills: ${proposal.skills.join(', ')}',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 178/255),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurface.withValues(alpha: 153/255)),
              const SizedBox(width: 6),
              Text(
                _formatDate(proposal.proposedDate),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 178/255),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: colorScheme.onSurface.withValues(alpha: 153/255)),
              const SizedBox(width: 6),
              Text(
                proposal.proposedTime,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 178/255),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer, size: 16, color: colorScheme.onSurface.withValues(alpha: 153/255)),
              const SizedBox(width: 6),
              Text(
                proposal.duration,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 178/255),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                isVirtual ? Icons.videocam : Icons.location_on,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 153/255),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  proposal.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 178/255),
                  ),
                ),
              ),
              if (isVirtual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 51/255),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Virtual',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          if (proposal.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                proposal.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 153/255),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          if (proposal.status == SessionProposalStatus.pending) ...[
            const SizedBox(height: 16),
            if (!isProposer) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToProposal(context, false),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToProposal(context, true),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelProposal(context),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Cancel Proposal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          
          const SizedBox(height: 8),
          Text(
            'Proposed ${_formatTimestamp(proposal.createdAt)}',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 128/255),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday, $month ${date.day}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _respondToProposal(BuildContext context, bool accept) async {
    try {
      final sessionService = SessionService();
      await sessionService.respondToProposal(proposal.id, accept);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Session proposal accepted!' : 'Session proposal declined',
            ),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to proposal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelProposal(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Proposal'),
          content: const Text('Are you sure you want to cancel this session proposal? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Proposal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Proposal'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && context.mounted) {
      try {
        final sessionService = SessionService();
        await sessionService.cancelProposal(proposal.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session proposal cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel proposal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}