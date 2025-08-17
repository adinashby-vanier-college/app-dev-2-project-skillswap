class ConversationPreview {
  final String id;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;
  final int unreadCount;
  final String status;
  final bool isArchived;

  ConversationPreview({
    required this.id,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.participants,
    required this.unreadCount,
    required this.status,
    required this.isArchived,
  });
}
