import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/friend_request.dart';
import 'package:provauth/constants.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/main/profile/profile.dart';
import 'package:provauth/ui/widgets/progress.dart';

class friendRequests extends StatefulWidget {
  const friendRequests({Key? key}) : super(key: key);

  @override
  _friendRequestsState createState() => _friendRequestsState();
}

class _friendRequestsState extends State<friendRequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Color(COLOR_PRIMARY),
        title: const Text(
          'Friend requests',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: FutureBuilder(
          future: FireStoreUtils.getFriendsRequests(id: current.userID),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(children: snapshot.data as List<Widget>);
          },
        ),
      ),
    );
  }
}

class friendRequestItem extends StatefulWidget {
  final FriendRequest friendReq;

  friendRequestItem({required this.friendReq});

  @override
  State<friendRequestItem> createState() => _friendRequestItemState();
}

class _friendRequestItemState extends State<friendRequestItem> {
  bool isVisible = true;
  Color tileColor = Colors.black87;
  Color borderColor = Colors.amber;

  @override
  Widget build(BuildContext context) {

    return (
      Container(
        decoration: BoxDecoration(
            color: tileColor,
            border: Border.all(color: borderColor,width: 1),
            borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        child: GestureDetector(
          onTap: () => showProfile(context, profileId: widget.friendReq.userID),
          child: ListTile(
            title: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(fontSize: 14.0, color: Colors.amber[700]),
                    children: [
                      TextSpan(
                        text: widget.friendReq.uniqueName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]),
              ),
            leading: CircleAvatar(
                radius: 40.0,
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(widget.friendReq.mediaURL),
              ),
            subtitle: Text(
                widget.friendReq.name,
              style: TextStyle(color: Colors.amber[200]),
              ),
            trailing: Visibility(
              visible: isVisible,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        acceptFriendRequest();
                        setState((){
                          isVisible = !isVisible;
                          tileColor = const Color(0xFFFCE4EC);
                          borderColor = const Color(0xFFF48FB1);
                        });
                    },
                      icon: const Icon(Icons.check,color: Colors.green,)),
                  IconButton(
                      onPressed: (){
                        declineFriendRequest();
                        setState((){
                          isVisible = !isVisible;
                          tileColor = const Color(0xFFFCE4EC);
                          borderColor = const Color(0xFFF48FB1);
                        });
                  },
                      icon: const Icon(Icons.close,color: Colors.red))
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  void acceptFriendRequest() async{
    FireStoreUtils.addMutualFriends(sender: widget.friendReq.userID, receiver: current.userID);

    //send a notification to the other user of the new friendship
    activityFeedRef
        .doc(widget.friendReq.userID)
        .collection('feedItems')
        .doc(current.userID)
        .set({
      "type": 'friend',
      "mediaUrl": '',
      "postId": '',
      "postOwnerId": '',
      "username": current.uniqueName,
      "userId": current.userID,
      "userProfileImg": current.profilePictureURL,
      "timestamp": DateTime.now()
    });

    //update timeline of current user
    QuerySnapshot snapshot = await postsRef.doc(widget.friendReq.userID).collection('userPosts')
        .orderBy('timestamp', descending: true).get();
    for(QueryDocumentSnapshot doc in snapshot.docs){
      timelineRef.doc(current.userID).collection('timelinePosts')
          .doc(doc.reference.id)
          .set({
        "postId": doc.get("postId"),
        "ownerId": doc.get("ownerId"),
        "timestamp": doc.get("timestamp"),
      });
    }

    //update timeline of the other user
    snapshot = await postsRef.doc(current.userID).collection('userPosts')
        .orderBy('timestamp', descending: true).get();
    for(QueryDocumentSnapshot doc in snapshot.docs){
      timelineRef.doc(widget.friendReq.userID).collection('timelinePosts')
          .doc(doc.reference.id)
          .set({
        "postId": doc.get("postId"),
        "ownerId": doc.get("ownerId"),
        "timestamp": doc.get("timestamp"),
      });
    }
  }

  void declineFriendRequest() {
    FireStoreUtils.declineFriendRequest(sender: widget.friendReq.userID, receiver: current.userID);
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
