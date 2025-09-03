import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'models/session_proposal.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // List of mock users for auto-acceptance
  static const List<String> mockUsers = [
    'Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'
  ];

  // Create a new session proposal
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

      debugPrint('Creating session proposal for user: $currentUserId');
      debugPrint('Conversation ID: $conversationId');
      debugPrint('Recipient ID: $recipientId');

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

      debugPrint('Proposal data: ${proposal.toMap()}');

      final docRef = await _firestore
          .collection('session_proposals')
          .add(proposal.toMap());

      debugPrint('Proposal created with ID: ${docRef.id}');

      // Send a system message to the chat about the proposal
      try {
        await _sendProposalMessage(
          conversationId: conversationId,
          proposalId: docRef.id,
          proposerName: await _getUserName(currentUserId!),
        );
        debugPrint('Proposal message sent successfully');
      } catch (e) {
        debugPrint('Failed to send proposal message: $e');
        // Don't throw here, the proposal was still created
      }

      // Auto-accept for mock users (for debugging purposes)
      debugPrint('Checking recipient ID: $recipientId against mock users: $mockUsers');
      if (mockUsers.contains(recipientId)) {
        debugPrint('Auto-accepting proposal for mock user: $recipientId');
        await _autoAcceptProposal(docRef.id, recipientId);
      } else {
        debugPrint('Recipient $recipientId is not a mock user, no auto-accept');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating session proposal: $e');
      rethrow;
    }
  }

  // Get session proposals for a conversation
  Stream<List<SessionProposal>> getSessionProposals(String conversationId) {
    return _firestore
        .collection('session_proposals')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
      final proposals = snapshot.docs
          .map((doc) => SessionProposal.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return proposals;
    });
  }

  // Respond to a session proposal
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

    // If accepted, create a booked session
    if (accept) {
      final proposalDoc = await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .get();
      
      if (proposalDoc.exists) {
        final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
        await _createBookedSession(proposal);
        
        // Send acceptance message
        await _sendResponseMessage(
          conversationId: proposal.conversationId,
          proposalId: proposalId,
          accepted: true,
          responderName: await _getUserName(currentUserId!),
        );
      }
    } else {
      // Send decline message
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

  // Cancel a session proposal (only by proposer)
  Future<void> cancelProposal(String proposalId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Get the proposal to verify the current user is the proposer
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

    // Update proposal status to cancelled
    await _firestore
        .collection('session_proposals')
        .doc(proposalId)
        .update({
      'status': SessionProposalStatus.cancelled.toString().split('.').last,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Send cancellation message
    await _sendCancellationMessage(
      conversationId: proposal.conversationId,
      proposalId: proposalId,
      proposerName: await _getUserName(currentUserId!),
    );
  }

  // Create a booked session from an accepted proposal
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

  // Send a system message about the proposal
  Future<void> _sendProposalMessage({
    required String conversationId,
    required String proposalId,
    required String proposerName,
  }) async {
    try {
      debugPrint('Sending proposal message to conversation: $conversationId');
      
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
      
      debugPrint('Message data: $messageData');
      
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      
      // Update both message and conversation metadata in a transaction
      await _firestore.runTransaction((transaction) async {
        // Add the message
        final messageRef = convoRef.collection('messages').doc();
        transaction.set(messageRef, messageData);
        
        // Update conversation metadata
        transaction.update(convoRef, {
          'lastMessage': messageText,
          'lastMessageTime': Timestamp.fromDate(now),
          'lastMessageDeleted': false,
        });
      });
          
      debugPrint('Message sent successfully');
    } catch (e) {
      debugPrint('Error sending proposal message: $e');
      rethrow;
    }
  }

  // Send a response message
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
    
    // Update both message and conversation metadata in a transaction
    await _firestore.runTransaction((transaction) async {
      // Add the message
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
      
      // Update conversation metadata
      transaction.update(convoRef, {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageDeleted': false,
      });
    });
  }

  // Send a cancellation message
  Future<void> _sendCancellationMessage({
    required String conversationId,
    required String proposalId,
    required String proposerName,
  }) async {
    final now = DateTime.now();
    final messageText = '🚫 $proposerName cancelled the session proposal';

    final convoRef = _firestore.collection('conversations').doc(conversationId);
    
    // Update both message and conversation metadata in a transaction
    await _firestore.runTransaction((transaction) async {
      // Add the message
      final messageRef = convoRef.collection('messages').doc();
      transaction.set(messageRef, {
        'text': messageText,
        'senderId': 'system',
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'type': 'session_cancelled',
        'proposalId': proposalId,
      });
      
      // Update conversation metadata
      transaction.update(convoRef, {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageDeleted': false,
      });
    });
  }

  // Get booked sessions for a user
  Stream<List<Map<String, dynamic>>> getBookedSessions() {
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
        
        // Auto-update past scheduled sessions to completed for debugging
        _autoCompleteOldSessions(doc.id, data);
        
        return data;
      }).toList();
      
      return sessions;
    });
  }
  
  // Auto-complete old sessions for debugging purposes
  void _autoCompleteOldSessions(String sessionId, Map<String, dynamic> sessionData) async {
    if (sessionData['status'] != 'scheduled') return;
    
    try {
      final sessionDate = DateTime.parse(sessionData['date']);
      final now = DateTime.now();
      
      // If session is more than 1 day old, mark as completed
      if (now.difference(sessionDate).inDays > 1) {
        await _firestore
            .collection('booked_sessions')
            .doc(sessionId)
            .update({
          'status': 'completed',
          'rating': 4 + (DateTime.now().millisecond % 2), // Random rating 4-5
          'notes': 'Session completed successfully!',
        });
        
        debugPrint('Auto-completed old session: $sessionId');
      }
    } catch (e) {
      // Ignore date parsing errors
    }
  }

  // Auto-accept proposal for mock users
  Future<void> _autoAcceptProposal(String proposalId, String mockUserId) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate thinking time
    
    try {
      // First check if proposal is still pending (might have been cancelled)
      final proposalDoc = await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .get();
      
      if (!proposalDoc.exists) {
        debugPrint('Proposal $proposalId no longer exists');
        return;
      }

      final proposal = SessionProposal.fromMap(proposalDoc.data()!, proposalId);
      
      // Only auto-accept if still pending
      if (proposal.status != SessionProposalStatus.pending) {
        debugPrint('Proposal $proposalId is no longer pending (status: ${proposal.status}), skipping auto-accept');
        return;
      }

      await _firestore
          .collection('session_proposals')
          .doc(proposalId)
          .update({
        'status': SessionProposalStatus.accepted.toString().split('.').last,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create a booked session
      await _createBookedSession(proposal);
      
      // Send acceptance message
      await _sendResponseMessage(
        conversationId: proposal.conversationId,
        proposalId: proposalId,
        accepted: true,
        responderName: mockUserId,
      );
      
      debugPrint('Auto-accepted proposal $proposalId for mock user $mockUserId');
    } catch (e) {
      debugPrint('Error auto-accepting proposal: $e');
    }
  }

  // Cancel a booked session
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
      debugPrint('Error cancelling session: $e');
      rethrow;
    }
  }

  // Get user name helper
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