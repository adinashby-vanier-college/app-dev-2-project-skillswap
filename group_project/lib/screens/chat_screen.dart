import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/chat_bubble.dart';
import '../utils/loading_spinner.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final bool isArchived;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.isArchived = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _canSend = false;

  // Cache for user data
  final Map<String, Map<String, String?>> _userCache = {};

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final textNotEmpty = _controller.text.trim().isNotEmpty;
      if (textNotEmpty != _canSend) {
        setState(() => _canSend = textNotEmpty);
      }
    });

    _chatService.markMessagesRead(widget.conversationId);

    // Load current user data first, then set loading to false
    _initializeUserData();
  }

  // Initialize user data and then set loading to false
  Future<void> _initializeUserData() async {
    // Load current user data
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      await _loadUserData(currentUserId);
    }

    // Add a small delay to ensure everything is loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load user data for a specific user ID
  Future<Map<String, String?>> _loadUserData(String userId) async {
    // Return cached data if available
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data();

      // For current user, also try Firebase Auth as fallback
      final currentUser = FirebaseAuth.instance.currentUser;
      final isCurrentUser = currentUser?.uid == userId;

      String name = 'User';
      String? photoUrl;

      if (userData?['name'] != null) {
        name = userData!['name'].toString();
      } else if (isCurrentUser && currentUser != null) {
        // Fallback to Firebase Auth data for current user
        name = currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'You';
      }

      if (userData?['photoUrl'] != null) {
        photoUrl = userData!['photoUrl'].toString();
      } else if (isCurrentUser && currentUser != null) {
        photoUrl = currentUser.photoURL;
      }

      final result = <String, String?>{
        'name': name,
        'photoUrl': photoUrl,
      };

      _userCache[userId] = result;

      if (isCurrentUser) {
        debugPrint('Loaded current user data: name=${result['name']}, photoUrl=${result['photoUrl']}');
      }

      return result;
    } catch (e) {
      debugPrint('Failed to load user data for $userId: $e');
      final fallback = <String, String?>{'name': 'User', 'photoUrl': null};
      _userCache[userId] = fallback;
      return fallback;
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _controller.clear();
      _canSend = false;
    });

    try {
      await _chatService.sendMessage(widget.conversationId, text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleArchiveStatus() async {
    try {
      final newArchiveState = !widget.isArchived;
      await _chatService.archiveConversation(widget.conversationId, archive: newArchiveState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newArchiveState ? 'Conversation archived' : 'Conversation unarchived'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update archive status: $e')),
        );
      }
    }
  }

  void _deleteMessage(String messageId) async {
    await _chatService.deleteMessage(widget.conversationId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.isArchived;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            tooltip: 'Scroll to top',
            onPressed: _scrollToTop,
          ),
          IconButton(
            icon: const Icon(Icons.vertical_align_bottom),
            tooltip: 'Scroll to bottom',
            onPressed: _scrollToBottom,
          ),
          IconButton(
            icon: Icon(isArchived ? Icons.unarchive : Icons.archive),
            tooltip: isArchived ? 'Unarchive Chat' : 'Archive Chat',
            onPressed: _toggleArchiveStatus,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const LoadingSpinner()
                : StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(widget.conversationId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading messages: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages yet'));
                      }

                      // Messages are already in reverse chronological order from the stream
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,  // Add this to show messages from bottom to top
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _chatService.currentUserId;

                          return FutureBuilder<Map<String, String?>>(
                            future: _loadUserData(message.senderId),
                            builder: (context, userSnapshot) {
                              final userData = userSnapshot.data;
                              return ChatBubble(
                                message: message.text,
                                isMe: isMe,
                                timestamp: message.timestamp,
                                onDelete: isMe ? () => _deleteMessage(message.id) : null,
                                isDeleted: message.isDeleted,
                                senderName: (userData?['name'] == 'User') ? message.senderId : userData?['name'],
                                senderPhotoUrl: userData?['photoUrl'],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Type a message...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: _canSend ? Theme.of(context).primaryColor : Colors.grey,
                  onPressed: _canSend ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}