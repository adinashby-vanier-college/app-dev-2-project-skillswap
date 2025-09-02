import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/chat_bubble.dart';
import '../../../utils/loading_spinner.dart';
import 'models/message.dart';
import 'models/session_proposal.dart';
import 'chat_service.dart';
import 'session_service.dart';
import 'widgets/session_proposal_dialog.dart';
import 'widgets/session_proposal_widget.dart';

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
  final SessionService _sessionService = SessionService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _canSend = false;
  bool _showScrollToLatest = false;
  String? _otherUserId;
  String _otherUserName = 'SkillSwap Chat';

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

    _scrollController.addListener(_handleScroll);

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
      
      // Get the other user's ID from the conversation
      await _getOtherUserId();
    }

    // Add a small delay to ensure everything is loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Get the other user's ID and name from conversation participants
  Future<void> _getOtherUserId() async {
    try {
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
      
      if (conversationDoc.exists) {
        final data = conversationDoc.data();
        final participants = List<String>.from(data?['participants'] ?? []);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        
        _otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        if (_otherUserId != null && _otherUserId!.isNotEmpty) {
          _otherUserName = await _getUserName(_otherUserId!);
          if (mounted) {
            setState(() {}); // Trigger rebuild to show the name in AppBar
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get other user ID: $e');
    }
  }

  // Get user name with mock user support
  Future<String> _getUserName(String userId) async {
    // Handle mock/debug users
    final mockUsers = ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'];
    if (mockUsers.contains(userId)) {
      return userId;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data();
      return userData?['name']?.toString() ?? userId;
    } catch (e) {
      return userId;
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
      _scrollToLatestAfterMessage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    // Show FAB when scrolled UP towards older messages (away from top/newest)
    // Since newest messages are at position 0 (top), show FAB when scrolled down from top
    final shouldShowFAB = position.pixels > 100;
    
    if (shouldShowFAB != _showScrollToLatest) {
      setState(() {
        _showScrollToLatest = shouldShowFAB;
      });
    }
  }

  void _scrollToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Scroll to top where newest messages are
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToLatestAfterMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
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

  void _showSessionProposalDialog() {
    if (_otherUserId == null || _otherUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to propose session at this time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SessionProposalDialog(
        conversationId: widget.conversationId,
        recipientId: _otherUserId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.isArchived;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserName),
        actions: [
          if (!isArchived)
            IconButton(
              icon: const Icon(Icons.event_note),
              tooltip: 'Propose Session',
              onPressed: _showSessionProposalDialog,
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
                : StreamBuilder<List<SessionProposal>>(
                    stream: _sessionService.getSessionProposals(widget.conversationId),
                    builder: (context, proposalSnapshot) {
                      return StreamBuilder<List<Message>>(
                        stream: _chatService.getMessages(widget.conversationId),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.hasError) {
                            return Center(
                              child: Text('Error loading messages: ${messageSnapshot.error}'),
                            );
                          }

                          if (!messageSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messages = messageSnapshot.data!;
                          final proposals = proposalSnapshot.data ?? [];
                          
                          if (messages.isEmpty && proposals.isEmpty) {
                            return const Center(child: Text('No messages yet'));
                          }

                          // Combine messages and proposals, sorted by timestamp
                          final allItems = <dynamic>[...messages, ...proposals];
                          allItems.sort((a, b) {
                            final aTime = a is Message ? a.timestamp : (a as SessionProposal).createdAt;
                            final bTime = b is Message ? b.timestamp : (b as SessionProposal).createdAt;
                            return bTime.compareTo(aTime); // Reverse order for ListView reverse: true
                          });

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              
                              if (item is SessionProposal) {
                                return SessionProposalWidget(
                                  proposal: item,
                                  currentUserId: _chatService.currentUserId,
                                );
                              } else if (item is Message) {
                                final message = item;
                                final isSystemMessage = message.senderId == 'system';
                                
                                // Handle system messages differently
                                if (isSystemMessage) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            message.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Handle regular user messages
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
                              }
                              
                              return const SizedBox.shrink();
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
      floatingActionButton: _showScrollToLatest
          ? Padding(
              padding: const EdgeInsets.only(bottom: 45.0),
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToLatest,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            )
          : null,
    );
  }
}