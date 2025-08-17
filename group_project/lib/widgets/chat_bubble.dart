import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'profile_avatar.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final VoidCallback? onDelete;
  final bool isDeleted;
  final String? senderName;       // Sender's display name
  final String? senderPhotoUrl;   // Sender's profile photo URL

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.onDelete,
    this.isDeleted = false,
    this.senderName,
    this.senderPhotoUrl,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showDelete = false;

  void _showDeleteIcon() {
    setState(() {
      _showDelete = true;
    });
  }

  void _hideDeleteIcon() {
    setState(() {
      _showDelete = false;
    });
  }

  void _onDelete() {
    widget.onDelete?.call();
    _hideDeleteIcon();
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('hh:mm a').format(widget.timestamp);

    Widget bubbleContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12).copyWith(right: 40),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.blue[300] : Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
          bottomRight: Radius.circular(widget.isMe ? 0 : 12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          widget.isDeleted
              ? Text(
            'message was deleted',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
              fontSize: 16,
            ),
          )
              : Text(
            widget.message,
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeString,
            style: TextStyle(
              color: widget.isMe ? Colors.white70 : Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    Widget deleteButton = Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: _onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(1, 2),
                blurRadius: 3,
              )
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(
            Icons.delete,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Build the complete message row with avatar
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users (left side)
          if (!widget.isMe) ...[
            ProfileAvatar(
              size: 32.0,
              imageUrl: widget.senderPhotoUrl,
              displayName: widget.senderName,
            ),
            const SizedBox(width: 8.0),
          ],

          // Message bubble (flexible to take remaining space)
          Flexible(
            child: Align(
              alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onLongPress: _showDeleteIcon,
                  onTap: () {
                    if (_showDelete) _hideDeleteIcon();
                  },
                  onSecondaryTapDown: (details) {
                    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

                    showMenu(
                      context: context,
                      position: RelativeRect.fromRect(
                        details.globalPosition & const Size(40, 40),
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        PopupMenuItem(
                          onTap: _onDelete,
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      bubbleContent,
                      if (_showDelete && !widget.isDeleted) deleteButton,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Avatar for current user (right side)
          if (widget.isMe) ...[
            const SizedBox(width: 8.0),
            ProfileAvatar(
              size: 32.0,
              imageUrl: widget.senderPhotoUrl,
              displayName: widget.senderName,
            ),
          ],
        ],
      ),
    );
  }
}