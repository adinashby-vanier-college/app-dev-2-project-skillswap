import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/session_proposal.dart';
import '../../utils/app_logger.dart';

/// Service for managing skill-sharing session proposals and bookings.
class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static const List<String> mockUsers = [
    'Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'
  ];

  /// Creates a new session proposal.
  Future<String> createSessionProposal({
    required String conversationId,
    required String recipientId,
    required String title,
    required List<String> skills,
    required DateTime proposedDate,
    required String proposedTime,
    required String duration,
    required String location,
    required String type,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Validate that the proposed date is not in the past
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sessionDate = DateTime(proposedDate.year, proposedDate.month, proposedDate.day);
      
      if (sessionDate.isBefore(today)) {
        throw Exception('Cannot create sessions for past dates. Please select a future date.');
      }

      AppLogger.debug('Creating session proposal for user: $currentUserId', tag: 'SESSION');
      AppLogger.debug('Conversation ID: $conversationId', tag: 'SESSION');
      AppLogger.debug('Recipient ID: $recipientId', tag: 'SESSION');

      final proposal = SessionProposal(
        id: '', // Will be set by Firestore
        conversationId: conversationId,
        proposerId: currentUserId!,
        recipientId: recipientId,
        title: title,
        skills: skills,
        proposedDate: proposedDate,
        proposedTime: proposedTime,
        duration: duration,
        location: location,
        type: type,
        notes: notes,
        status: SessionProposalStatus.pending,
        createdAt: DateTime.now(),
      );

      AppLogger.debug('Proposal data: ${proposal.toMap()}', tag: 'SESSION');

      final docRef = await _firestore
          .collection('session_proposals')
          .add(proposal.toMap());

      AppLogger.debug('Proposal created with ID: ${docRef.id}', tag: 'SESSION');

      try {
        await _sendProposalMessage(
          conversationId: conversationId,
          proposalId: docRef.id,
          proposerName: await _getUserName(currentUserId!),
        );
        AppLogger.debug('Proposal message sent successfully', tag: 'SESSION');
      } catch (e) {
        AppLogger.error('Failed to send proposal message', tag: 'SESSION', error: e);
      }

      AppLogger.debug('Checking recipient ID: $recipientId against mock users: $mockUsers', tag: 'SESSION');
      if (mockUsers.contains(recipientId)) {
        AppLogger.debug('Auto-accepting proposal for mock user: $recipientId', tag: 'SESSION');
        await _autoAcceptProposal(docRef.id, recipientId);
      } else {
        AppLogger.debug('Recipient $recipientId is not a mock user, no auto-accept', tag: 'SESSION');
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating session proposal', tag: 'SESSION', error: e);
      rethrow;
    }
  }

  /// Gets session proposals for a conversation.
  Stream<List<SessionProposal>> getSessionProposals(String conversationId) {
    return _firestore
        .collection('session_proposals')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
      final proposals = snapshot.docs
          .map((doc) => SessionProposal.fromMap(doc.data(), doc.id))
          .toList();
      
      proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return proposals;
    });
  }

  /// Responds to a session proposal.
  Future<void> respondToProposal(String proposalId, bool accept) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final status = accept ? SessionProposalStatus.accepted : SessionProposalStatus.declined;
    
    await _firestore
        .collection('session_proposals')
        .doc(proposalId)
        .update({
      'status': status.toString().split('.').last,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    if (accept) {
      final proposalDoc = await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .get();
      
      if (proposalDoc.exists) {
        final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
        await _createBookedSession(proposal);
        
        await _sendResponseMessage(
          conversationId: proposal.conversationId,
          proposalId: proposalId,
          accepted: true,
          responderName: await _getUserName(currentUserId!),
        );
      }
    } else {
      final proposalDoc = await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .get();
      
      if (proposalDoc.exists) {
        final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
        await _sendResponseMessage(
          conversationId: proposal.conversationId,
          proposalId: proposalId,
          accepted: false,
          responderName: await _getUserName(currentUserId!),
        );
      }
    }
  }

  /// Cancels a session proposal (only by proposer).
  Future<void> cancelProposal(String proposalId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final proposalDoc = await _firestore
        .collection('session_proposals')
        .doc(proposalId)
        .get();
    
    if (!proposalDoc.exists) {
      throw Exception('Proposal not found');
    }

    final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
    
    if (proposal.proposerId != currentUserId) {
      throw Exception('Only the proposer can cancel a proposal');
    }

    if (proposal.status != SessionProposalStatus.pending) {
      throw Exception('Can only cancel pending proposals');
    }

    await _firestore
        .collection('session_proposals')
        .doc(proposalId)
        .update({
      'status': SessionProposalStatus.cancelled.toString().split('.').last,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _sendCancellationMessage(
      conversationId: proposal.conversationId,
      proposalId: proposalId,
      proposerName: await _getUserName(currentUserId!),
    );
  }

  /// Creates a booked session from an accepted proposal.
  Future<void> _createBookedSession(SessionProposal proposal) async {
    final sessionId = _firestore.collection('booked_sessions').doc().id;
    final session = {
      'id': sessionId,
      'title': proposal.title,
      'participants': [proposal.proposerId, proposal.recipientId],
      'skills': proposal.skills,
      'date': proposal.proposedDate.toIso8601String(),
      'time': proposal.proposedTime,
      'duration': proposal.duration,
      'location': proposal.location,
      'type': proposal.type,
      'notes': proposal.notes ?? '',
      'status': 'scheduled',
      'rating': 0,
      'proposalId': proposal.id,
      'conversationId': proposal.conversationId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    await _firestore
        .collection('booked_sessions')
        .doc(sessionId)
        .set(session);
  }

  /// Sends a system message about the proposal.
  Future<void> _sendProposalMessage({
    required String conversationId,
    required String proposalId,
    required String proposerName,
  }) async {
    try {
      AppLogger.debug('Sending proposal message to conversation: $conversationId', tag: 'SESSION');
      
      final now = DateTime.now();
      final messageText = '📅 $proposerName proposed a session';
      final messageData = {
        'text': messageText,
        'senderId': 'system',
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'type': 'session_proposal',
        'proposalId': proposalId,
      };
      
      AppLogger.debug('Message data: $messageData', tag: 'SESSION');
      
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      
      // Update both message and conversation metadata in a transaction
      await _firestore.runTransaction((transaction) async {
        final messageRef = convoRef.collection('messages').doc();
        transaction.set(messageRef, messageData);
        
        transaction.update(convoRef, {
          'lastMessage': messageText,
          'lastMessageTime': Timestamp.fromDate(now),
          'lastMessageDeleted': false,
        });
      });
          
      AppLogger.debug('Message sent successfully', tag: 'SESSION');
    } catch (e) {
      AppLogger.error('Error sending proposal message', tag: 'SESSION', error: e);
      rethrow;
    }
  }

  /// Sends a response message.
  Future<void> _sendResponseMessage({
    required String conversationId,
    required String proposalId,
    required bool accepted,
    required String responderName,
  }) async {
    final now = DateTime.now();
    final messageText = accepted
        ? '✅ $responderName accepted the session proposal'
        : '❌ $responderName declined the session proposal';

    final convoRef = _firestore.collection('conversations').doc(conversationId);
    
    await _firestore.runTransaction((transaction) async {
      final messageRef = convoRef.collection('messages').doc();
      transaction.set(messageRef, {
        'text': messageText,
        'senderId': 'system',
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'type': 'session_response',
        'proposalId': proposalId,
        'accepted': accepted,
      });
      
      transaction.update(convoRef, {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageDeleted': false,
      });
    });
  }

  /// Sends a cancellation message.
  Future<void> _sendCancellationMessage({
    required String conversationId,
    required String proposalId,
    required String proposerName,
  }) async {
    final now = DateTime.now();
    final messageText = '🚫 $proposerName cancelled the session proposal';

    final convoRef = _firestore.collection('conversations').doc(conversationId);
    
    await _firestore.runTransaction((transaction) async {
      final messageRef = convoRef.collection('messages').doc();
      transaction.set(messageRef, {
        'text': messageText,
        'senderId': 'system',
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'type': 'session_cancelled',
        'proposalId': proposalId,
      });
      
      transaction.update(convoRef, {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageDeleted': false,
      });
    });
  }

  /// Gets booked sessions for the current user.
  Stream<List<Map<String, dynamic>>> getBookedSessions({bool includeOldSessions = false}) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('booked_sessions')
        .where('participants', arrayContains: currentUserId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        _autoCompleteOldSessions(doc.id, data);
        
        return data;
      }).where((sessionData) {
        // Filter out old sessions unless explicitly requested
        if (includeOldSessions) return true;
        
        try {
          final sessionDate = DateTime.parse(sessionData['date']);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final sessionDateOnly = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
          
          // Only show sessions from today onwards
          return !sessionDateOnly.isBefore(today);
        } catch (e) {
          AppLogger.error('Error parsing session date', tag: 'SESSION', error: e);
          // Keep the session if date parsing fails
          return true;
        }
      }).toList();
      
      return sessions;
    });
  }
  
  /// Auto-completes old sessions for debugging purposes.
  void _autoCompleteOldSessions(String sessionId, Map<String, dynamic> sessionData) async {
    if (sessionData['status'] != 'scheduled') return;
    
    try {
      final sessionDate = DateTime.parse(sessionData['date']);
      final now = DateTime.now();
      
      if (now.difference(sessionDate).inDays > 1) {
        await _firestore
            .collection('booked_sessions')
            .doc(sessionId)
            .update({
          'status': 'completed',
          'rating': 4 + (DateTime.now().millisecond % 2),
          'notes': 'Session completed successfully!',
        });
        
        AppLogger.debug('Auto-completed old session: $sessionId', tag: 'SESSION');
      }
    } catch (e) {
      AppLogger.error('Error auto-completing session', tag: 'SESSION', error: e);
    }
  }

  /// Auto-accepts proposal for mock users.
  Future<void> _autoAcceptProposal(String proposalId, String mockUserId) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final proposalDoc = await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .get();
      
      if (!proposalDoc.exists) {
        AppLogger.debug('Proposal $proposalId no longer exists', tag: 'SESSION');
        return;
      }

      final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
      
      if (proposal.status != SessionProposalStatus.pending) {
        AppLogger.debug('Proposal $proposalId is no longer pending (status: ${proposal.status}), skipping auto-accept', tag: 'SESSION');
        return;
      }

      await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .update({
        'status': SessionProposalStatus.accepted.toString().split('.').last,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _createBookedSession(proposal);
      
      await _sendResponseMessage(
        conversationId: proposal.conversationId,
        proposalId: proposalId,
        accepted: true,
        responderName: mockUserId,
      );
      
      AppLogger.debug('Auto-accepted proposal $proposalId for mock user $mockUserId', tag: 'SESSION');
    } catch (e) {
      AppLogger.error('Error auto-accepting proposal', tag: 'SESSION', error: e);
    }
  }

  /// Cancels a booked session.
  Future<void> cancelBookedSession(String sessionId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('booked_sessions')
          .doc(sessionId)
          .update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'cancelledBy': currentUserId,
      });
    } catch (e) {
      AppLogger.error('Error cancelling session', tag: 'SESSION', error: e);
      rethrow;
    }
  }

  /// Updates all old sessions to have future dates.
  /// This is a one-time cleanup method for development.
  Future<void> updateOldSessionsToFuture() async {
    if (currentUserId == null) return;
    
    try {
      AppLogger.debug('Starting cleanup of old sessions', tag: 'SESSION');
      
      final sessionsSnapshot = await _firestore
          .collection('booked_sessions')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      final batch = _firestore.batch();
      int updatedCount = 0;
      final now = DateTime.now();
      
      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        try {
          final sessionDate = DateTime.parse(data['date']);
          final today = DateTime(now.year, now.month, now.day);
          final sessionDateOnly = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
          
          // If session is in the past, update it to a future date
          if (sessionDateOnly.isBefore(today)) {
            // Update to a random date in the next 30 days
            final daysToAdd = 1 + (now.millisecond % 30);
            final newDate = today.add(Duration(days: daysToAdd));
            final newDateString = newDate.toIso8601String();
            
            batch.update(doc.reference, {
              'date': newDateString,
              'status': 'scheduled', // Reset status if it was completed
            });
            
            updatedCount++;
            AppLogger.debug('Updated session ${doc.id} from ${sessionDate.toIso8601String()} to $newDateString', tag: 'SESSION');
          }
        } catch (e) {
          AppLogger.error('Error processing session ${doc.id}', tag: 'SESSION', error: e);
        }
      }
      
      if (updatedCount > 0) {
        await batch.commit();
        AppLogger.debug('Updated $updatedCount old sessions to future dates', tag: 'SESSION');
      } else {
        AppLogger.debug('No old sessions found to update', tag: 'SESSION');
      }
    } catch (e) {
      AppLogger.error('Error updating old sessions', tag: 'SESSION', error: e);
    }
  }

  /// Gets user name helper.
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return userDoc.data()?['name']?.toString() ?? 'User';
    } catch (e) {
      return 'User';
    }
  }
}