import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/post.dart';
import 'package:provauth/beans/timeline_item.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/ui/widgets/header.dart';
import 'package:provauth/ui/widgets/post_widget.dart';
import 'package:provauth/ui/widgets/progress.dart';

import '../../../constants.dart';

class Timeline extends StatefulWidget {
  final MyUser currentUser;

  Timeline({required this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<PostWidget> posts = [];
  List<String> followingList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getTimeline();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.userID)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();

    List<TimelineItem> timelineItems =
        snapshot.docs.map((doc) => TimelineItem.fromDocument(doc)).toList();
    List<PostWidget> postsTemp = [];

    for (var element in timelineItems) {
      DocumentSnapshot documentSnapshot = await postsRef
          .doc(element.ownerId)
          .collection('userPosts')
          .doc(element.postId)
          .get();

      postsTemp.add(PostWidget(Post.fromDocument(documentSnapshot)));
    }

    setState(() {
      posts = postsTemp;
      isLoading = false;
    });
  }

  buildTimeline() {
    if (isLoading) {
      return circularProgress();
    } else {
      return ListView(
        children: [
          ListView(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true, // <- added
            primary: false, // <- added
            children: posts,
          ),
          Container(
              color: Colors.black87,
              width: 400,
              height: 100,
              child: const Center(child: Text(
                "There are no more posts to see",
                style: TextStyle(color: Color(COLOR_PRIMARY)),
              ))),
        ],
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
