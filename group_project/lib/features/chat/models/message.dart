import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model representing a chat message.
class Message {
  final String id;
  final String senderId;
  final String? receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String conversationId;
  final bool isDeleted;

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

  /// Creates a Message from Firestore data.
  factory Message.fromMap(Map<String, dynamic> data, String documentId, String convoId) {
    try {
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
        receiverId: data['receiverId']?.toString(),
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

  /// Converts the Message to a map for Firestore.
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
