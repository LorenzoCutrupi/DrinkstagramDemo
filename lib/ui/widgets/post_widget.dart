import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/post.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/main/notifications/friend_requests.dart';
import 'package:provauth/ui/main/profile/comments.dart';
import 'package:provauth/ui/main/profile/likes.dart';
import 'package:video_player/video_player.dart';
import '../../constants.dart';
import 'custom_image.dart';
import 'progress.dart';

class PostWidget extends StatefulWidget {
  final Post post;

  PostWidget(this.post);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  String currentUserId = current.userID;
  String subtitle = '';
  int likeCount = 0;
  bool isLiked = false;
  Map likes = {};
  bool showHeart = false;

  void initState() {
    super.initState();
    if (widget.post.cocktail != '') {
      subtitle += 'is drinking ' + widget.post.cocktail + ' ';
    }
    if (widget.post.location != '') {
      subtitle += 'in ' + widget.post.location;
    }
    likeCount = widget.post.getLikeCount(widget.post.likes);
    likes = widget.post.likes;
    isLiked = (likes[currentUserId] == true);
  }

  bool isVideo(){
    String url = widget.post.mediaUrl;
    if(url.contains('.mp4')||url.contains('.mov')||url.contains('.avi')){
      return true;
    }
    return false;
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef
          .doc(widget.post.ownerId)
          .collection('userPosts')
          .doc(widget.post.postId)
          .update({
        'likes.$currentUserId': false,
      });
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
      removeLikeToActivityFeed();
    } else if (!isLiked) {
      postsRef
          .doc(widget.post.ownerId)
          .collection('userPosts')
          .doc(widget.post.postId)
          .update({
        'likes.$currentUserId': true,
      });
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() async {
    QuerySnapshot snapshot =
        await FireStoreUtils.getUserByUserID(current.userID);
    current = MyUser.fromJsonDocument(snapshot.docs.first);

    if (currentUserId != widget.post.ownerId) {
      activityFeedRef
          .doc(widget.post.ownerId)
          .collection('feedItems')
          .doc(widget.post.postId)
          .set({
        "type": 'like',
        "username": current.uniqueName,
        "userId": current.userID,
        "postOwnerId": widget.post.ownerId,
        "userProfileImg": current.profilePictureURL,
        "postId": widget.post.postId,
        "mediaUrl": widget.post.mediaUrl,
        "timestamp": DateTime.now()
      });
    }
  }

  removeLikeToActivityFeed() {
    bool isNotPostOwner = (currentUserId != widget.post.ownerId);
    if (isNotPostOwner) {
      activityFeedRef
          .doc(widget.post.ownerId)
          .collection('feedItems')
          .doc(widget.post.postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostHeader() {
    return FutureBuilder(
        future: usersRef.doc(widget.post.ownerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          MyUser user =
              MyUser.fromJsonDocument(snapshot.data as DocumentSnapshot);
          bool isPostOwner = currentUserId == widget.post.ownerId;
          return ListTile(
            leading: GestureDetector(
              onTap: () => showProfile(context, profileId: widget.post.ownerId),
              child: CircleAvatar(
                backgroundImage:
                    CachedNetworkImageProvider(user.profilePictureURL),
                backgroundColor: Colors.grey,
              ),
            ),
            title: GestureDetector(
              onTap: () => showProfile(context, profileId: widget.post.ownerId),
              child: Text(
                user.uniqueName,
                style: TextStyle(
                    color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: subtitle,
                    style:
                        TextStyle(color: Color(COLOR_PRIMARY), fontSize: 12.5),
                  ),
                  WidgetSpan(
                    child: (widget.post.cocktail != '' &&
                            drinkNameToImage[widget.post.cocktail] != null)
                        ? Image(
                            image: AssetImage(
                                drinkNameToImage[widget.post.cocktail]
                                    as String),
                            width: 20,
                            height: 20,
                          )
                        : Text(''),
                  )
                ],
              ),
            ),
            trailing: isPostOwner
                ? IconButton(
                    onPressed: () => handleDeletePost(context),
                    icon: Icon(Icons.more_vert, color: Color(COLOR_PRIMARY)),
                  )
                : Text(''),
          );
        });
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) => SimpleDialog(
        title: Text("Remove this post ?"),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              deletePost();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  // To delete a post, ownerId and currentUserId must be equal.
  deletePost() async {
    // delete post itself
    postsRef
        .doc(widget.post.ownerId)
        .collection('userPosts')
        .doc(widget.post.postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete uploaded image from the post
    storageRef.child('post_${widget.post.postId}.jpg').delete();

    // delete all activity field notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(widget.post.ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: widget.post.postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete all comments
    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(widget.post.postId).collection('comments').get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    //delete from timeline
    List<MyUser> friendsList = [];
    QuerySnapshot snapshot =
        await friendsRef.doc(current.userID).collection('mutual').get();
    for (var doc in snapshot.docs) {
      QuerySnapshot boh =
          await FireStoreUtils.getUserByUserID(doc.reference.id);
      friendsList.add(MyUser.fromJsonDocument(boh.docs.first));
    }
    for (var friend in friendsList) {
      QuerySnapshot timelineSnapshot = await timelineRef
          .doc(friend.userID)
          .collection('timelinePosts')
          .where('postId', isEqualTo: widget.post.postId)
          .get();
      timelineSnapshot.docs.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(widget.post.mediaUrl),
          showHeart
              ? const Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.red,
                )
              : const Text('')
        ],
      ),
    );
  }

  buildPostVideo() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            child: AspectRatio(
              aspectRatio: 1,
              child: Chewie(
                controller: ChewieController(
                  showControls: false,
                    autoPlay: true,
                    looping: true,
                    videoPlayerController: VideoPlayerController.network(widget.post.mediaUrl)),
              ),
            ),
          ),
          showHeart
              ? const Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.red,
                )
              : const Text('')
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0, color: isLiked ? Colors.pink : Colors.grey[700]),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
            ),
            GestureDetector(
              onTap: () => showComments(context,
                  postId: widget.post.postId,
                  ownerId: widget.post.ownerId,
                  mediaUrl: widget.post.mediaUrl),
              child: Icon(Icons.chat, size: 28.0, color: Colors.grey[600]),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: GestureDetector(
                onTap: () => showLikes(context,
                    postId: widget.post.postId, ownerId: widget.post.ownerId),
                child: Text(
                  '$likeCount  likes',
                  style: TextStyle(
                      color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 20.0),
                child: GestureDetector(
                  onTap: () =>
                      showProfile(context, profileId: widget.post.ownerId),
                  child: Text(
                    '${widget.post.uniqueName} ',
                    style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.post.description,
                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                ),
              )
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.only(top: 4),
            child: const Divider(
              color: Color(COLOR_PRIMARY),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildPostHeader(),
          isVideo()? buildPostVideo() : buildPostImage(),
          buildPostFooter(),
        ],
      ),
    );
  }
}

showComments(BuildContext context,
    {required String postId,
    required String ownerId,
    required String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
        postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl);
  }));
}

showLikes(BuildContext context,
    {required String postId, required String ownerId}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Likes(postId: postId, ownerId: ownerId);
  }));
}
