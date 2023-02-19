import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/post.dart';
import 'package:provauth/ui/widgets/header.dart';
import 'package:provauth/ui/widgets/post_widget.dart';
import 'package:provauth/ui/widgets/progress.dart';

import '../../../constants.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({required this.postId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: postsRef
            .doc(userId)
            .collection('userPosts')
            .doc(postId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          Post post = Post.fromDocument(snapshot.data as DocumentSnapshot);
          return Center(
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: header(context, titleText: 'Drinkstagram'),
              body: ListView(
                children: <Widget>[
                  Container(
                    child: PostWidget(post),
                  )
                ],
              ),
            ),
          );
        },
      );
  }
}
