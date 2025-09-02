import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Message {
  final String id;             // Firestore doc ID (auto-generated)
  final String senderId;       // ID of the message sender
  final String? receiverId;     // ID of the message receiver (null for system messages)
  final String text;           // Message text content
  final DateTime timestamp;    // When the message was sent
  final bool isRead;           // Has the receiver read this message?
  final String conversationId; // ID of the conversation this message belongs to (not stored in Firestore)
  final bool isDeleted;        // Is the message deleted?

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.conversationId,
    this.isDeleted = false,
  });

  factory Message.fromMap(Map<String, dynamic> data, String documentId, String convoId) {
    try {
      // Debug print to see what data we're getting
      debugPrint('Message.fromMap - data keys: ${data.keys.toList()}');
      debugPrint('Message.fromMap - senderId: ${data['senderId']}');
      debugPrint('Message.fromMap - receiverId: ${data['receiverId']}');
      debugPrint('Message.fromMap - text: ${data['text']}');
      debugPrint('Message.fromMap - timestamp: ${data['timestamp']}');
      
      // Validate required fields
      final senderId = data['senderId'];
      if (senderId == null) {
        throw Exception('Message missing senderId field');
      }
      
      final text = data['text'];
      if (text == null) {
        throw Exception('Message missing text field');
      }
      
      final timestampData = data['timestamp'];
      if (timestampData == null) {
        throw Exception('Message missing timestamp field');
      }
      
      DateTime timestamp;
      if (timestampData is Timestamp) {
        timestamp = timestampData.toDate();
      } else if (timestampData is DateTime) {
        timestamp = timestampData;
      } else {
        throw Exception('Invalid timestamp type: ${timestampData.runtimeType}');
      }
      
      return Message(
        id: documentId,
        senderId: senderId.toString(),
        receiverId: data['receiverId']?.toString(), // Can be null for system messages
        text: text.toString(),
        timestamp: timestamp,
        isRead: data['isRead'] ?? false,
        conversationId: convoId,
        isDeleted: data['isDeleted'] ?? false,
      );
    } catch (e) {
      debugPrint('Error in Message.fromMap: $e');
      debugPrint('Full data: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
    
    if (receiverId != null) {
      map['receiverId'] = receiverId!;
    }
    
    return map;
  }
}
