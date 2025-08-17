import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;             // Firestore doc ID (auto-generated)
  final String senderId;       // ID of the message sender
  final String receiverId;     // ID of the message receiver
  final String text;           // Message text content
  final DateTime timestamp;    // When the message was sent
  final bool isRead;           // Has the receiver read this message?
  final String conversationId; // ID of the conversation this message belongs to (not stored in Firestore)
  final bool isDeleted;        // Is the message deleted?

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.conversationId,
    this.isDeleted = false,
  });

  factory Message.fromMap(Map<String, dynamic> data, String documentId, String convoId) {
    return Message(
      id: documentId,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      text: data['text'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      conversationId: convoId,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }
}
