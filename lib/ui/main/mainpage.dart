import 'dart:collection';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/services/helper.dart';
import 'package:provauth/ui/auth/authscreen.dart';
import 'package:provauth/ui/main/home/homescreen.dart';
import 'package:provauth/ui/main/map/map.dart';
import 'package:provauth/ui/main/notifications/notifications.dart';
import 'package:provauth/ui/main/photo/photo.dart';
import 'package:provauth/ui/main/profile/profile.dart';

import '../../../constants.dart';
import '../../../main.dart';

MyUser current = MyUser();

class MainScreen extends StatefulWidget {
  final MyUser currentUser;
  late var screens = [];

  MainScreen({Key? key, required this.currentUser}) : super(key: key) {
    screens = [
      Timeline(currentUser: currentUser),
      Map(),
      Upload(currentUser: currentUser),
      Notifications(),
      Profile(profileId: currentUser.userID, currentUser: currentUser)
    ];
  }

  @override
  State createState() => _MainScreenState();
}

int currentIndex = 2;

class _MainScreenState extends State<MainScreen> {
  List friendsList = [];
  List pages = [
    'Drinkstagram',
    'Map',
    'Upload',
    'Notifications',
    'Profile'
  ];
  String appBarText = 'Upload';
  late MyUser user;
  late List screens = [];

  @override
  void initState() {
    super.initState();
    user = widget.currentUser;
    screens = widget.screens;
    current = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor:
              Colors.black, //This will change the drawer background to blue.
          //other styles
        ),
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text(
                  current.name,
                  style: const TextStyle(color: Colors.black),
                ),
                decoration: const BoxDecoration(
                  color: Color(COLOR_PRIMARY),
                ),
              ),
              ListTile(
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                ),
                leading: Transform.rotate(
                    angle: pi / 1,
                    child: const Icon(Icons.exit_to_app, color: Colors.red)),
                onTap: () async {
                  await auth.FirebaseAuth.instance.signOut();
                  MyAppState.currentUser = null;
                  pushAndRemoveUntil(context, AuthScreen(), false);
                },
              ),
              const Divider(color: Color(COLOR_PRIMARY))
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          appBarText,
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: const Color(COLOR_PRIMARY),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                friendsList = await FireStoreUtils.getFriendsAndPendingList(
                    current.userID); friendsList.add(current.userID);
                showSearch(
                    context: context,
                    delegate: DataSearch(
                        myUserID: user.userID, friendsList: friendsList));
              },
              icon: const Icon(Icons.person_add_rounded))
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: ConvexAppBar(
        activeColor: Colors.black,
        backgroundColor: Colors.amber,
        initialActiveIndex: 2,
        items: const [
          TabItem(icon: Icons.home),
          TabItem(icon: Icons.location_on),
          TabItem(
            icon: Icons.photo_camera_rounded,
          ),
          TabItem(icon: Icons.notifications),
          TabItem(icon: Icons.account_circle_rounded),
        ],
        onTap: (index) => setState(() {
          currentIndex = index;
          appBarText = pages[index];
        }),
      ),
    );
  }
}

class DataSearch extends SearchDelegate<String> {
  String myUserID;
  List friendsList;
  bool isFriend = false;

  DataSearch({required this.myUserID, required this.friendsList});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(COLOR_PRIMARY),
        ));
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
        color: Colors.black,
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, '');
        },
        icon: AnimatedIcon(
          progress: transitionAnimation,
          icon: AnimatedIcons.menu_arrow,
          color: Colors.black,
        ));
  }

  @override
  Widget buildResults(BuildContext context) {
    Future<QuerySnapshot> queryResults;
    queryResults = FireStoreUtils.getUserByUniqueName(query);
    return const Scaffold();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return Container(
        color: Colors.black,
        child: FutureBuilder<QuerySnapshot>(
          future: FireStoreUtils.getUserByUniqueName(query),
          builder: (context, snapshot) {
            if (query.isEmpty) return buildNoSuggestions();

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              default:
                if (snapshot.hasError || !snapshot.hasData) {
                  return buildNoSuggestions();
                } else {
                  List<MyUser>? suggestions = [];
                  snapshot.data!.docs.forEach((doc) {
                    MyUser user = MyUser.fromJsonDocument(doc);
                    suggestions.add(user);
                  });
                  return ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      final suggestionUniqueName = suggestion.uniqueName;
                      final queryText =
                          suggestionUniqueName.substring(0, query.length);
                      final remainingText =
                          suggestionUniqueName.substring(query.length);

                      return ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              query = suggestionUniqueName;
                              showProfile(context,
                                  profileId: suggestion.userID);
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.grey,
                              backgroundImage: CachedNetworkImageProvider(
                                  suggestion.profilePictureURL),
                            ),
                          ),
                          // title: Text(suggestion),
                          title: GestureDetector(
                            onTap: () {
                              query = suggestionUniqueName;
                              showProfile(context,
                                  profileId: suggestion.userID);
                            },
                            child: RichText(
                              text: TextSpan(
                                text: queryText,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                children: [
                                  TextSpan(
                                    text: remainingText,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          subtitle: GestureDetector(
                              onTap: () {
                                query = suggestionUniqueName;
                                showProfile(context,
                                    profileId: suggestion.userID);
                              },
                              child: Text(suggestion.name,
                                  style: const TextStyle(color: Colors.grey))),
                          trailing: !friendsList.contains(suggestion.userID)
                              ? IconButton(
                                  icon: const Icon(Icons.person_add_rounded,
                                      color: Colors.amber),
                                  onPressed: () {
                                    sendFriendRequest(
                                        myUserID, suggestion.userID);
                                    setState(() {
                                      friendsList.add(suggestion.userID);
                                    });
                                  },
                                )
                              : null);
                    },
                  );
                }
            }
          },
        ),
      );
    });
  }
}

sendFriendRequest(String myUserID, String userID) {
  FireStoreUtils.sendFriendRequest(sender: myUserID, receiver: userID);
}

Widget buildNoSuggestions() => const Center(
      child: Text(
        'No suggestions!',
        style: TextStyle(fontSize: 28, color: Colors.amber),
      ),
    );
