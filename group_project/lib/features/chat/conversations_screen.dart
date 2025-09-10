import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/conversation_preview.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
import '../../../widgets/profile_avatar.dart';
import '../profile/view_profile_screen.dart';

/// Screen displaying list of user's chat conversations.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, String> _userNamesCache = {};

  @override
  void initState() {
    super.initState();
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  Future<void> _deleteConversation(String convoId) async {
    final confirm = await _showConfirmationDialog(
      'Delete Conversation',
      'Are you sure you want to delete this conversation?',
    );
    if (confirm != true || !mounted) return;

    try {
      await _chatService.deleteConversation(convoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete conversation: $e')),
      );
    }
  }

  Future<void> _archiveConversation(String convoId) async {
    try {
      await _chatService.archiveConversation(convoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation archived')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to archive conversation: $e')),
      );
    }
  }


  Future<String> _getUserName(String userId) async {
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    final mockUsers = ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'];
    if (mockUsers.contains(userId)) {
      _userNamesCache[userId] = userId;
      return userId;
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
            tooltip: 'Add/Restore Mock Conversations',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _chatService.createAllMockConversations();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Created/restored all mock conversations')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to create mock conversations: $e')),
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
                orElse: () => '',
              );
              
              if (chatPartnerId.isEmpty || chatPartnerId == 'Unknown') {
                return const SizedBox.shrink();
              }

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
                child: FutureBuilder<String>(
                  future: _getUserName(chatPartnerId),
                  builder: (context, userNameSnapshot) {
                    final userName = userNameSnapshot.data ?? chatPartnerId;
                    
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          final mockUsers = ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'];
                          if (mockUsers.contains(chatPartnerId)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$userName is a mock user - no profile available')),
                            );
                            return;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProfileScreen(userId: chatPartnerId),
                            ),
                          );
                        },
                        child: ProfileAvatar(
                          displayName: userName,
                        ),
                      ),
                      title: Text('Chat with $userName'),
                      subtitle: Text(
                        (convo.status == 'deleted' || convo.lastMessage.isEmpty)
                            ? 'message was deleted'
                            : convo.lastMessage,
                        style: TextStyle(
                          fontStyle: (convo.status == 'deleted' || convo.lastMessage == 'message was deleted' || convo.lastMessage.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: (convo.status == 'deleted' || convo.lastMessage == 'message was deleted' || convo.lastMessage.isEmpty)
                              ? Colors.grey[600]
                              : null,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTimestamp(convo.lastMessageTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (convo.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${convo.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convo.id,
                              isArchived: false,
                            ),
                          ),
                        );
                      },
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

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
  }
}
