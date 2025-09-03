import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'models/conversation_preview.dart';
import 'models/message.dart';
import 'mock/mock_conversations.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  // -------------------------
  // SEND MESSAGE
  // -------------------------
  Future<void> sendMessage(String conversationId, String text) async {
    final convoRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = convoRef.collection('messages').doc();
    final now = DateTime.now();

    final participants = conversationId.split('_');
    if (!participants.contains(currentUserId)) {
      throw Exception('Current user is not part of this conversation');
    }
    final chatPartnerId = participants.firstWhere((id) => id != currentUserId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(messagesRef, {
        'senderId': currentUserId,
        'receiverId': chatPartnerId,
        'text': text,
        'timestamp': now,
        'isRead': false,
      });

      transaction.set(convoRef, {
        'participants': participants,
        'lastMessage': text,
        'lastMessageTime': now,
        'unreadCounts': {
          chatPartnerId: FieldValue.increment(1),
          currentUserId: 0,
        },
        'status': {
          currentUserId: 'active',
          chatPartnerId: 'active',
        },
        'lastMessageDeleted': false, // Reset deletion flag on new message
      }, SetOptions(merge: true));
    });

    // Add dummy auto-response for testing
    _sendDummyResponse(conversationId, chatPartnerId);
  }

  // Dummy auto-response system for testing
  void _sendDummyResponse(String conversationId, String chatPartnerId) async {
    // Wait 2-5 seconds before responding
    await Future.delayed(Duration(seconds: 2 + (DateTime.now().millisecond % 4)));
    
    final responses = [
      "That sounds interesting! Tell me more.",
      "I'd love to learn that skill from you.",
      "When would be a good time to practice together?",
      "I can help you with that in exchange!",
      "Great idea! Let's set up a time to meet.",
      "I have some experience with that. Happy to share!",
      "That would be really helpful. Thank you!",
      "I'm free this weekend if you want to practice.",
      "Do you have any specific questions about it?",
      "I've been wanting to learn that for a while!",
      "Perfect! I can teach you what I know about that.",
      "Sounds like a great skill exchange opportunity!"
    ];
    
    final randomResponse = responses[DateTime.now().millisecond % responses.length];
    
    try {
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      final responseMessageRef = convoRef.collection('messages').doc();
      final responseTime = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        transaction.set(responseMessageRef, {
          'senderId': chatPartnerId,
          'receiverId': currentUserId,
          'text': randomResponse,
          'timestamp': responseTime,
          'isRead': false,
        });

        transaction.set(convoRef, {
          'lastMessage': randomResponse,
          'lastMessageTime': responseTime,
          'unreadCounts': {
            currentUserId: FieldValue.increment(1),
            chatPartnerId: 0,
          },
        }, SetOptions(merge: true));
      });
    } catch (e) {
      // Ignore errors in dummy responses
      debugPrint('Dummy response failed: $e');
    }
  }

  // -------------------------
  // GET CONVERSATIONS
  // -------------------------
  Stream<List<ConversationPreview>> getConversations({bool includeArchived = false}) {
    Query q = _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true);

    if (!includeArchived) q = q.where('archived', isEqualTo: false);

    return q.snapshots().map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) return null;

      // Validate participants
      final participantsList = data['participants'] as List<dynamic>?;
      if (participantsList == null || participantsList.isEmpty) return null;
      
      final participants = List<String>.from(participantsList);
      
      // Must have exactly 2 participants and current user must be one of them
      if (participants.length != 2 || !participants.contains(currentUserId)) return null;
      
      // Get the other participant
      final otherParticipant = participants.firstWhere((id) => id != currentUserId);
      
      // Skip conversations with invalid participant IDs
      if (otherParticipant.isEmpty || otherParticipant == 'Unknown') return null;

      final unreadCountsMap = data['unreadCounts'] as Map<String, dynamic>?;

      // Get last message
      String lastMessage = data['lastMessage'] ?? '';
      // Check if last message is deleted
      if (data['lastMessageDeleted'] == true) {
        lastMessage = 'message was deleted';
      }

      return ConversationPreview(
        id: doc.id,
        lastMessage: lastMessage,
        lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        participants: participants,
        unreadCount: unreadCountsMap?[currentUserId] as int? ?? 0,
        status: (data['status'] as Map<String, dynamic>?)?[currentUserId] ?? 'active',
        isArchived: data['archived'] as bool? ?? false,
      );
    }).where((conv) => conv != null).cast<ConversationPreview>().toList());
  }

  // -------------------------
  // GET MESSAGES
  // -------------------------
  Stream<List<Message>> getMessages(String conversationId) {
    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true);  // Changed to descending order

    return messagesRef.snapshots().map((snapshot) {
      final messages = <Message>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          debugPrint('Processing message doc ${doc.id}: $data');
          
          final message = Message.fromMap(data, doc.id, conversationId);
          messages.add(message);
        } catch (e) {
          debugPrint('Error processing message ${doc.id}: $e');
          debugPrint('Message data: ${doc.data()}');
          // Skip this message and continue with others
        }
      }
      
      return messages;
    });
  }

  Future<void> markMessagesRead(String conversationId) async {
    final convoRef = _firestore.collection('conversations').doc(conversationId);
    await convoRef.set({'unreadCounts': {currentUserId: 0}}, SetOptions(merge: true));
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final convoRef = _firestore.collection('conversations').doc(conversationId);
    final messageRef = convoRef.collection('messages').doc(messageId);

    // Get the message to be deleted
    final messageSnap = await messageRef.get();
    if (!messageSnap.exists) {
      await messageRef.delete();
      return;
    }
    final messageData = messageSnap.data() as Map<String, dynamic>;
    final deletedTimestamp = messageData['timestamp'];

    // Get the last message in the conversation
    final messagesSnap = await convoRef.collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

    bool isLastMessage = false;
    if (messagesSnap.docs.isNotEmpty) {
      final lastMsgDoc = messagesSnap.docs.first;
      isLastMessage = lastMsgDoc.id == messageId;
    }

    // Soft delete: set isDeleted and text to ''
    await messageRef.update({
      'isDeleted': true,
      'text': '',
    });

    // If this is the last message, update conversation metadata
    if (isLastMessage) {
      await convoRef.set({
        'lastMessageDeleted': true,
        'lastMessage': '',
        'lastMessageTime': deletedTimestamp,
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteConversation(String convoId) async {
    final convoRef = _firestore.collection('conversations').doc(convoId);
    final messagesSnapshot = await convoRef.collection('messages').get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(convoRef);
    await batch.commit();
  }

  Future<void> archiveConversation(String convoId, {bool archive = true}) async {
    final convoRef = _firestore.collection('conversations').doc(convoId);
    await convoRef.set({'archived': archive}, SetOptions(merge: true));
  }

  // -------------------------
  // INITIALIZE CONVERSATION
  // -------------------------
  Future<void> initializeConversation(String conversationId) async {
    final convoRef = _firestore.collection('conversations').doc(conversationId);
    
    // Check if conversation already exists
    final doc = await convoRef.get();
    if (doc.exists) return; // Conversation already exists
    
    final participants = conversationId.split('_');
    if (!participants.contains(currentUserId)) {
      throw Exception('Current user is not part of this conversation');
    }
    
    // Create empty conversation document
    await convoRef.set({
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': DateTime.now(),
      'unreadCounts': {
        for (var p in participants) p: 0
      },
      'status': {
        for (var p in participants) p: 'active'
      },
      'archived': false,
      'lastMessageDeleted': false,
    });
  }

  // -------------------------
  // CREATE MOCK CONVERSATIONS
  // -------------------------
  Future<void> createAllMockConversations() async {
    // Start from 2 hours ago to ensure mock chats appear earlier
    final baseTime = DateTime.now().subtract(const Duration(hours: 2));

    // First, delete all existing conversations
    final existingConvos = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingConvos.docs) {
      await deleteConversation(doc.id);
    }

    // Process each mock conversation
    for (int i = 0; i < mockConversations.length; i++) {
      final convo = mockConversations[i];

      // Replace "You" with current user ID in participants
      final participants = (convo['participants'] as List<dynamic>)
          .map((p) => p == 'You' ? currentUserId : p)
          .toList();
      participants.sort();
      final conversationId = participants.join('_');
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      final messagesRef = convoRef.collection('messages');
      final messages = List<Map<String, String>>.from(convo['messages']);

      // Create messages with timestamps 5 minutes apart for each conversation
      // Each conversation starts 10 minutes after the previous one
      final convoStartTime = baseTime.add(Duration(minutes: i * 10));

      for (int j = 0; j < messages.length; j++) {
        final msg = messages[j];
        final senderId = msg['sender'] == 'You' ? currentUserId : msg['sender']!;
        final receiverId = participants.firstWhere((p) => p != senderId);

        await messagesRef.add({
          'senderId': senderId,
          'receiverId': receiverId,
          'text': msg['text'],
          'timestamp': convoStartTime.add(Duration(minutes: j * 5)),
          'isRead': senderId == currentUserId,
        });
      }

      // Set conversation metadata
      await convoRef.set({
        'participants': participants,
        'lastMessage': messages.last['text'],
        'lastMessageTime': convoStartTime.add(Duration(minutes: (messages.length - 1) * 5)),
        'unreadCounts': {
          for (var p in participants) p: p == currentUserId ? 0 : 1
        },
        'status': {for (var p in participants) p: 'active'},
        'archived': false,
      });
    }
  }

  // Remove unused methods
  Future<void> createFixedMockConversations() async {
    await createAllMockConversations();
  }

  Future<void> createSingleMockConversation(Map<String, dynamic> convo) async {
    await createAllMockConversations();
  }

  Map<String, dynamic>? getNextMockConversation() {
    return mockConversations[0];  // Just return any conversation, we'll create them all anyway
  }
}
