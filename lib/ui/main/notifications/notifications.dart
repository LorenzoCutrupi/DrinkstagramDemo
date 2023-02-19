import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/feed.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/notifications/friend_requests.dart';
import 'package:provauth/ui/main/profile/post_screen.dart';
import 'package:provauth/ui/main/profile/profile.dart';
import 'package:provauth/ui/widgets/header.dart';
import 'package:provauth/ui/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../constants.dart';
import '../mainpage.dart';

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .doc(current.userID)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    List<ActivityFeedItem> feedItems = [];
    for (var doc in snapshot.docs) {
      Feed tempFeed = Feed.fromDocument(doc);
      QuerySnapshot snapshotTemp = await FireStoreUtils.getUserByUserID(tempFeed.userId);
      MyUser tempUser = MyUser.fromJsonDocument(snapshotTemp.docs.first);
      tempFeed.username = tempUser.name; tempFeed.userProfileImg = tempUser.profilePictureURL;
      feedItems.add(ActivityFeedItem(tempFeed));
    }
    return feedItems;
  }

  getReceivedFriendRequestsSize() async{
    QuerySnapshot snapshot = await friendsRef
        .doc(current.userID)
        .collection('received')
        .get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FutureBuilder(
            future: getReceivedFriendRequestsSize(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }
              return TextButton(
                  onPressed: goToFriendsPage, 
                  child: Text(
                    "You received "+snapshot.data.toString()+" friends requests",
                    style: const TextStyle(color: Color(COLOR_PRIMARY)),));
            },
          ),
          Flexible(
            child: FutureBuilder(
              future: getActivityFeed(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return circularProgress();
                }
                return ListView(children: snapshot.data as List<Widget>);
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
  

  void goToFriendsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => friendRequests(),
      ),
    ).then((_) => setState(() {}));
  }
}

String activityItemText = '';
Widget mediaPreview = Widget as Widget;

class ActivityFeedItem extends StatelessWidget {
  final Feed feed;

  ActivityFeedItem(this.feed);

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
              postId: feed.postId,
              userId: feed.postOwnerId,
            )));
  }

  configureMediaPreview(context) {
    if (feed.type == 'like' || feed.type == 'comment' || feed.type == 'tagged') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(
          context,
        ),
        child: Container(
          width: 50.0,
          height: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(feed.mediaUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (feed.type == 'like') {
      activityItemText = 'liked your post';
    } else if (feed.type == 'tagged') {
      activityItemText = 'tagged you in a post';
    } else if (feed.type == 'friend') {
      activityItemText = 'accepted your friend request';
    } else if (feed.type == 'comment') {
      activityItemText = 'replied: "${feed.commentData}"';
    } else {
      activityItemText = "Error: Unknown type ${feed.type}";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.amber,width: 1),
          borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        child: GestureDetector(
          onTap: () => showPost(context),
          child: ListTile(
            visualDensity: VisualDensity(vertical: -2),
            contentPadding: EdgeInsets.symmetric(horizontal: 12,vertical: 0),
            title: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                      style: TextStyle(fontSize: 14.0, color: Colors.amber[700]),
                      children: [
                        TextSpan(
                          text: feed.username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = () => showProfile(context, profileId: feed.userId),
                        ),
                        TextSpan(text: ' $activityItemText'),
                      ]),
                ),
              ),
            leading: GestureDetector(
              onTap: () => showProfile(context, profileId: feed.userId),
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(feed.userProfileImg),
              ),
            ),
            subtitle: Text(
              timeago.format(feed.timestamp.toDate()),
              style: TextStyle(color: Colors.amber[200]),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: mediaPreview,
          ),
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {required String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId, currentUser: current,
      ),
    ),
  );
}