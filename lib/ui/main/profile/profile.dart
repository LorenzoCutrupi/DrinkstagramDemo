import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provauth/beans/post.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/widgets/drink_choicebox.dart';
import 'package:provauth/ui/widgets/header.dart';
import 'package:provauth/ui/widgets/post_tile.dart';
import 'package:provauth/ui/widgets/post_widget.dart';
import 'package:provauth/ui/widgets/progress.dart';

import '../../../constants.dart';
import 'edit_profile.dart';
import 'friends_list.dart';

class Profile extends StatefulWidget {
  final String profileId;
  final MyUser currentUser;

  Profile({required this.profileId, required this.currentUser});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late String currentUserId = widget.currentUser.userID;
  bool isLoading = false;
  int postCount = 0;
  List<Post> posts = [];
  String postOrientation = "grid";
  bool isFollowing = false, requestSent = false;
  int friendsCount = 0;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFriends();
    checkIfFriends();
  }

  getFriends() async {
    QuerySnapshot snapshot =
        await friendsRef.doc(widget.profileId).collection('mutual').get();
    setState(() {
      friendsCount = snapshot.docs.length;
    });
  }

  checkIfFriends() async {
    DocumentSnapshot doc = await friendsRef
        .doc(widget.profileId)
        .collection('mutual')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(COLOR_PRIMARY)),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400),
          ),
        )
      ],
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(currentUserId: currentUserId),
      ),
    ).then((_) => setState(() {}));
  }

  friendsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsList(currentUserId: widget.profileId),
      ),
    ).then((_) => setState(() {}));
  }

  buildProfileButton() {
    // Viewing own profile ? Should show EditProfile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: 'Edit Profile', function: editProfile);
    } else if (isFollowing && !requestSent) {
      return buildButton(text: "Remove friend", function: handleUnfollowUser);
    } else if (isFollowing && requestSent) {
      return buildButton(text: "Remove request", function: removeRequest);
    } else if (!isFollowing) {
      return buildButton(text: "Add friend", function: handleFollowUser);
    }
  }

  removeRequest() async {
    setState(() {
      isFollowing = false;
      requestSent = false;
    });

    FireStoreUtils.removeSentFriendRequest(
        sender: current.userID, receiver: widget.profileId);
  }

  handleUnfollowUser() async {
    setState(() {
      isFollowing = false;
    });
    FireStoreUtils.removeFriend(
        sender: current.userID, receiver: widget.profileId);

    //delete from timeline of current user
    QuerySnapshot timelineSnapshot = await timelineRef
        .doc(current.userID)
        .collection('timelinePosts')
        .where('ownerId', isEqualTo: widget.profileId)
        .get();
    timelineSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    //delete from timeline of other user
    timelineSnapshot = await timelineRef
        .doc(widget.profileId)
        .collection('timelinePosts')
        .where('ownerId', isEqualTo: current.userID)
        .get();
    timelineSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
      requestSent = true;
    });

    FireStoreUtils.sendFriendRequest(
        sender: current.userID, receiver: widget.profileId);
  }

  Container buildButton({required String text, required Function() function}) {
    return Container(
        padding: const EdgeInsets.only(top: 2.0),
        child: TextButton(
          onPressed: function,
          child: Container(
            width: 250.0,
            height: 27.0,
            decoration: BoxDecoration(
              color:
                  isFollowing ? Colors.amber[200] : const Color(COLOR_PRIMARY),
              border: Border.all(
                  color:
                      isFollowing ? Colors.grey : const Color(COLOR_PRIMARY)),
              borderRadius: BorderRadius.circular(5.0),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                  color: isFollowing ? Colors.black : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        DocumentSnapshot? doc = snapshot.data as DocumentSnapshot<Object?>?;
        MyUser user = MyUser.fromJsonDocument(doc!);
        return Container(
          color: Colors.black,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.profilePictureURL),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              buildCountColumn("drinks", postCount),
                              GestureDetector(
                                  onTap: friendsList,
                                  child:
                                      buildCountColumn("friends", friendsCount))
                            ],
                          ),
                          Row(
                            children: <Widget>[buildProfileButton()],
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 12.0),
                          child: Text(
                            user.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.amber[600]),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            user.uniqueName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(COLOR_PRIMARY)),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 2),
                          child: Text(user.bio,
                              style: TextStyle(color: Colors.amber[200])),
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    Container(
                      child: (user.favouriteCocktail != '' &&
                              drinkNameToImage[user.favouriteCocktail] !=
                                  null)
                          ? Column(
                            children: [
                              Image(
                                  image: AssetImage(
                                      drinkNameToImage[user.favouriteCocktail]
                                          as String),
                                  width: 60,
                                  height: 60,
                                ),
                              Text('Favourite cocktail',style: TextStyle(color: Color(COLOR_PRIMARY),fontSize: 11),)
                            ],
                          )
                          : Text(''),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if ((!isFollowing && (currentUserId != widget.profileId)) ||
        (requestSent)) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'You can\'t see any post of the user until he accepts your friend request',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            SvgPicture.asset('assets/images/no_content.svg', height: 260),
          ],
        ),
      );
    } else if (posts.isEmpty) {
      return Container(
        color: Colors.black,
        padding: EdgeInsets.only(top: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg', height: 260),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No Posts',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      return Container(
        color: Colors.black,
        child: StaggeredGridView.countBuilder(
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 3,
          itemCount: posts.length,
          itemBuilder: (context, index) => PostTile(posts[index]),
          staggeredTileBuilder: (index) => StaggeredTile.count(
              (index % 7 == 0) ? 2 : 1, (index % 7 == 0) ? 2 : 1),
          mainAxisSpacing: 6.0,
          crossAxisSpacing: 6.0,
        ),
      );
    } else if (postOrientation == 'list') {
      List<PostWidget> postsW = [];
      posts.forEach((post) {
        postsW.add(PostWidget(post));
      });

      return Container(color: Colors.black, child: Column(children: postsW));
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              onPressed: () => setPostOrientation('grid'),
              icon: Icon(Icons.grid_on),
              color: postOrientation == 'grid'
                  ? const Color(COLOR_PRIMARY)
                  : Colors.grey,
            ),
            IconButton(
              onPressed: () => setPostOrientation('list'),
              icon: Icon(Icons.list),
              color: postOrientation == 'list'
                  ? const Color(COLOR_PRIMARY)
                  : Colors.grey,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: usersRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          DocumentSnapshot? doc = snapshot.data as DocumentSnapshot<Object?>?;
          MyUser user = MyUser.fromJsonDocument(doc!);
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: currentUserId == widget.profileId
                ? null
                : header(context, titleText: user.uniqueName),
            body: ListView(
              children: <Widget>[
                buildProfileHeader(),
                const Divider(
                  color: Color(COLOR_PRIMARY),
                  height: 0.0,
                ),
                buildTogglePostOrientation(),
                const Divider(
                  color: Color(COLOR_PRIMARY),
                  height: 0.0,
                ),
                buildProfilePosts(),
              ],
            ),
          );
        });
  }

  doNothing() {}
}
