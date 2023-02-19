import 'package:cloud_firestore/cloud_firestore.dart';

class Feed {
  String username;
  final String userId;
  final String type; // like, follow, comment
  final String mediaUrl;
  final String postId;
  String userProfileImg;
  final String commentData;
  final String postOwnerId;
  final Timestamp timestamp;

  Feed({
    required this.username,
    required this.userId,
    required this.postOwnerId,
    required this.type,
    required this.mediaUrl,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.timestamp,
  });

  factory Feed.fromDocument(DocumentSnapshot doc) {
    String comment;
    if(doc['type']=='comment'){comment = doc['commentData'];}
    else{comment = '';}
    if(doc['type']=='comment' || doc['type']=='like'||doc['type']=='tagged'){
      return Feed(
        username: doc['username'],
        userId: doc['userId'],
        postOwnerId: doc['postOwnerId'],
        type: doc['type'],
        mediaUrl: doc['mediaUrl'],
        postId: doc['postId'],
        userProfileImg: doc['userProfileImg'],
        commentData: comment,
        timestamp: doc['timestamp'],
      );
    }
    else{
      return Feed(
        username: doc['username'],
        userId: doc['userId'],
        type: doc['type'],
        postOwnerId: doc['postOwnerId'],
        mediaUrl: '',
        postId: '',
        userProfileImg: doc['userProfileImg'],
        commentData: comment,
        timestamp: doc['timestamp'],
      );
    }
  }
}