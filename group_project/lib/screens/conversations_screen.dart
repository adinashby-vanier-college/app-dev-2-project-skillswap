import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/conversation_preview.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

const Map<String, String> mockUserNames = {
  'user1': 'You',
  'user2': 'Bob',
  'user3': 'Charlie',
  'user4': 'Dave',
};

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(String convoId) async {
    final confirm = await _showConfirmationDialog(
      'Delete Conversation',
      'Are you sure you want to delete this conversation?',
    );
    if (confirm != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _chatService.deleteConversation(convoId);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Conversation deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete conversation: $e')),
      );
    }
  }

  Future<void> _archiveConversation(String convoId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _chatService.archiveConversation(convoId);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Conversation archived')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to archive conversation: $e')),
      );
    }
  }

  void _startNewConversation() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Start new conversation tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'View Archived Chats',
            onPressed: () {
              if (!mounted) return;
              Navigator.pushNamed(context, '/archivedChats');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Add Mock Conversation',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _createMockConversation();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Mock conversation created')),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Failed to create mock: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationPreview>>(
        stream: _chatService.getConversations(includeArchived: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading conversations: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(child: Text('No conversations found.'));
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final chatPartnerId = convo.participants.firstWhere(
                    (id) => id != _chatService.currentUserId,
                orElse: () => 'Unknown',
              );
              final chatPartnerName =
                  mockUserNames[chatPartnerId] ?? chatPartnerId;

              return Dismissible(
                key: Key(convo.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.blueGrey,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.archive, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _deleteConversation(convo.id);
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    await _archiveConversation(convo.id);
                    return false;
                  }
                  return false;
                },
                child: ListTile(
                  title: Text('Chat with $chatPartnerName'),
                  subtitle: Text(convo.lastMessage),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTimestamp(convo.lastMessageTime),
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (convo.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${convo.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    if (!mounted) return;
                    final convoId = generateConversationId(
                      _chatService.currentUserId,
                      chatPartnerId,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: convoId,
                          isArchived: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        tooltip: 'Start New Conversation',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
  }

  Future<void> _createMockConversation() async {
    final firestore = FirebaseFirestore.instance;
    const currentUserId = 'user1';
    const chatPartnerId = 'user2';

    final ids = [currentUserId, chatPartnerId]..sort();
    final convoId = ids.join('_');

    final convoRef = firestore.collection('conversations').doc(convoId);
    final messagesRef = convoRef.collection('messages');
    final now = DateTime.now();

    await convoRef.set({
      'participants': [currentUserId, chatPartnerId],
      'lastMessage': 'Great talking with you!',
      'lastMessageTime': now,
      'unreadCounts': {
        chatPartnerId: 1,
        currentUserId: 0,
      },
      'status': {
        currentUserId: 'active',
        chatPartnerId: 'active',
      },
      'archived': false,
    });

    await messagesRef.add({
      'senderId': currentUserId,
      'receiverId': chatPartnerId,
      'text': 'Hey, this is a mock message from you!',
      'timestamp': now.subtract(const Duration(minutes: 2)),
      'isRead': true,
    });

    await messagesRef.add({
      'senderId': chatPartnerId,
      'receiverId': currentUserId,
      'text': 'Hi! Thanks for the message :)',
      'timestamp': now.subtract(const Duration(minutes: 1)),
      'isRead': false,
    });
  }

  String generateConversationId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }
}
