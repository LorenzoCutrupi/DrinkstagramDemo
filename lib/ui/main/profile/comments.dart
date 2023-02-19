import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/widgets/header.dart';
import 'package:provauth/ui/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../constants.dart';
import '../mainpage.dart';


class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({required this.postId, required this.postMediaUrl, required this.postOwnerId});

  @override
  CommentsState createState() => CommentsState();
}

class CommentsState extends State<Comments> {
  late final String postId;
  late final String postOwnerId;
  late final String postMediaUrl;
  TextEditingController commentController = TextEditingController();


  @override
  initState() {
    postId = widget.postId;
    postMediaUrl = widget.postMediaUrl;
    postOwnerId = widget.postOwnerId;
  }

  buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data!.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(children: comments);
      },
    );
  }

  addComment() async{
    QuerySnapshot snapshot = await FireStoreUtils.getUserByUserID(current.userID);
    current = MyUser.fromJsonDocument(snapshot.docs.first);

    commentsRef.doc(postId).collection('comments').add({
      'username': current.uniqueName,
      'comment': commentController.text,
      'timestamp': DateTime.now(),
      'avatarUrl': current.profilePictureURL,
      'userId': current.userID
    });

    //sends notification to the post owner
    if (postOwnerId != current.userID) {
      activityFeedRef
          .doc(postOwnerId)
          .collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text,
        'timestamp': DateTime.now(),
        'postId': postId,
        'postOwnerId': postOwnerId,
        'username': current.uniqueName,
        'userId': current.userID,
        'userProfileImg': current.profilePictureURL,
        "mediaUrl": postMediaUrl,
      });
    }

    List<String> ids = [];
    snapshot = await commentsRef.doc(postId).collection('comments').get();
    for (var doc in snapshot.docs) {
      ids.add(doc['userId']);
    }
    List<String> usersWhoCommented = ids.toSet().toList();

    for (var user in usersWhoCommented) {
      if(user != postOwnerId && user!=current.userID){
        activityFeedRef
            .doc(user)
            .collection('feedItems').add({
          'type': 'comment',
          'commentData': commentController.text,
          'timestamp': DateTime.now(),
          'postId': postId,
          'postOwnerId': postOwnerId,
          'username': current.uniqueName,
          'userId': current.userID,
          'userProfileImg': current.profilePictureURL,
          "mediaUrl": postMediaUrl,
        });
      }
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: header(context, titleText: 'Comments'),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(color: Colors.amber),
          ListTile(
            title: TextFormField(
              cursorColor: Colors.amber[700],
              style: TextStyle(color: Color(COLOR_PRIMARY)),
              controller: commentController,
              decoration: InputDecoration(
                  labelText: 'Write a comment',
              labelStyle: TextStyle(color: Colors.grey[400]),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      style: BorderStyle.none, color: Color(0xFFFFE082)),
                ),),

            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              child: Text('Post',style: TextStyle(color: Colors.amber)),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment(
      {required this.username,
        required this.userId,
        required this.avatarUrl,
        required this.comment,
        required this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment,style: TextStyle(color: Color(COLOR_PRIMARY)),),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate()),style: TextStyle(color: Colors.amber[200]),),
        ),
        Divider(color: Colors.amber,height: 0,),
      ],
    );
  }
}
