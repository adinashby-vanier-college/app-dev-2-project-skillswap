import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a session proposal.
enum SessionProposalStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
}

/// Model representing a skill-sharing session proposal.
class SessionProposal {
  final String id;
  final String conversationId;
  final String proposerId;
  final String recipientId;
  final String title;
  final List<String> skills;
  final DateTime proposedDate;
  final String proposedTime;
  final String duration;
  final String location;
  final String type;
  final String? notes;
  final SessionProposalStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  SessionProposal({
    required this.id,
    required this.conversationId,
    required this.proposerId,
    required this.recipientId,
    required this.title,
    required this.skills,
    required this.proposedDate,
    required this.proposedTime,
    required this.duration,
    required this.location,
    required this.type,
    this.notes,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Creates a SessionProposal from Firestore data.
  factory SessionProposal.fromMap(Map<String, dynamic> data, String id) {
    return SessionProposal(
      id: id,
      conversationId: data['conversationId'] ?? '',
      proposerId: data['proposerId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      title: data['title'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      proposedDate: (data['proposedDate'] as Timestamp).toDate(),
      proposedTime: data['proposedTime'] ?? '',
      duration: data['duration'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? 'in-person',
      notes: data['notes'],
      status: SessionProposalStatus.values.firstWhere(
        (e) => e.toString() == 'SessionProposalStatus.${data['status']}',
        orElse: () => SessionProposalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts the SessionProposal to a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'proposerId': proposerId,
      'recipientId': recipientId,
      'title': title,
      'skills': skills,
      'proposedDate': Timestamp.fromDate(proposedDate),
      'proposedTime': proposedTime,
      'duration': duration,
      'location': location,
      'type': type,
      'notes': notes,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Creates a copy with updated properties.
  SessionProposal copyWith({
    String? id,
    String? conversationId,
    String? proposerId,
    String? recipientId,
    String? title,
    List<String>? skills,
    DateTime? proposedDate,
    String? proposedTime,
    String? duration,
    String? location,
    String? type,
    String? notes,
    SessionProposalStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return SessionProposal(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      proposerId: proposerId ?? this.proposerId,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      skills: skills ?? this.skills,
      proposedDate: proposedDate ?? this.proposedDate,
      proposedTime: proposedTime ?? this.proposedTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}