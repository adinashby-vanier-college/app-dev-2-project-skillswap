import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
import '../utils/loading_spinner.dart';
import '../mock/mock_user.dart';
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

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final textNotEmpty = _controller.text.trim().isNotEmpty;
      if (textNotEmpty != _canSend) {
        setState(() => _canSend = textNotEmpty);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });

    _chatService.markMessagesRead(widget.conversationId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
      body: _isLoading
          ? const LoadingSpinner()
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingSpinner();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,      // Handles scrolling programmatically
                  itemCount: messages.length,         // Number of chat messages
                  itemBuilder: (ctx, index) {
                    final msg = messages[index];      // Get current message
                    final isMe = msg.senderId == mockCurrentUserId; // Check if I sent it

                    return ChatBubble(
                      key: ValueKey(msg.id),          // Unique key for efficient rebuilds
                      message: msg.text,              // Message text
                      isMe: isMe,                     // Styles bubble as mine or theirs
                      timestamp: msg.timestamp,       // When the message was sent
                      onDelete: () async {            // Delete message handler
                        try {
                          await _chatService.deleteMessage(widget.conversationId, msg.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message deleted')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete message: $e')),
                            );
                          }
                        }
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
