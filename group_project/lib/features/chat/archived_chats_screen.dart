import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/conversation_preview.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
import '../../../widgets/profile_avatar.dart';

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, String> _userNamesCache = {};

  Future<void> _unarchiveConversation(String convoId) async {
    try {
      await _chatService.archiveConversation(convoId, archive: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation unarchived')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unarchive conversation: $e')),
        );
      }
    }
  }

  Future<void> _deleteConversation(String convoId) async {
    try {
      await _chatService.deleteConversation(convoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete conversation: $e')),
        );
      }
    }
  }

  Future<String> _getUserName(String userId) async {
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data();
      final name = userData?['name']?.toString() ?? userId;
      _userNamesCache[userId] = name;
      return name;
    } catch (e) {
      _userNamesCache[userId] = userId;
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Chats'),
      ),
      body: StreamBuilder<List<ConversationPreview>>(
        stream: _chatService.getConversations(includeArchived: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Filter only archived conversations
          final archivedConvos = snapshot.data
              ?.where((conv) => conv.isArchived == true)
              .toList() ??
              [];

          if (archivedConvos.isEmpty) {
            return const Center(child: Text('No archived chats found.'));
          }

          return ListView.builder(
            itemCount: archivedConvos.length,
            itemBuilder: (context, index) {
              final convo = archivedConvos[index];
              final chatPartnerId = convo.participants.firstWhere(
                      (id) => id != _chatService.currentUserId,
                  orElse: () => 'Unknown');

              return Dismissible(
                key: Key(convo.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (direction) async {
                  await _deleteConversation(convo.id);
                  return false;
                },
                child: FutureBuilder<String>(
                  future: _getUserName(chatPartnerId),
                  builder: (context, userNameSnapshot) {
                    final userName = userNameSnapshot.data ?? chatPartnerId;
                    
                    return ListTile(
                      leading: ProfileAvatar(
                        displayName: userName,
                        // imageUrl: null, // If you have a photo URL, pass it here
                      ),
                      title: Text('Chat with $userName'),
                      subtitle: Text(
                        (convo.lastMessage == 'message was deleted' || convo.lastMessage.isEmpty)
                            ? 'message was deleted'
                            : convo.lastMessage,
                        style: TextStyle(
                          fontStyle: (convo.lastMessage == 'message was deleted' || convo.lastMessage.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: (convo.lastMessage == 'message was deleted' || convo.lastMessage.isEmpty)
                              ? Colors.grey[600]
                              : null,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convo.id,
                              isArchived: true,  // Archived chat
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.unarchive),
                        tooltip: 'Unarchive',
                        onPressed: () => _unarchiveConversation(convo.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
