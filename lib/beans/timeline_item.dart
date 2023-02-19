import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineItem {
  final String ownerId;
  final String postId;
  final Timestamp timestamp;

  TimelineItem({
    required this.ownerId,
    required this.postId,
    required this.timestamp,
  });

  factory TimelineItem.fromDocument(DocumentSnapshot doc) {
    return TimelineItem(
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      timestamp: doc['timestamp'],
    );
  }
}