import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/constants.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/notifications/friend_requests.dart';
import 'package:provauth/ui/widgets/progress.dart';

class Likes extends StatefulWidget {
  String ownerId;
  String postId;

  Likes({required this.ownerId,required this.postId});

  @override
  _LikesState createState() => _LikesState();
}

class _LikesState extends State<Likes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(COLOR_PRIMARY),
        title: const Text(
          'Likes',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: FutureBuilder<dynamic>(
          future: FireStoreUtils.getLikesList(widget.ownerId, widget.postId),
          builder: (context,snapshot){
            if(snapshot.hasError || !snapshot.hasData){
              return Container();
            }
            else{
              var likesId = snapshot.data['likes'];
              List<String>? suggestions = [];
              likesId.forEach((key,value) {
                if(value) {
                  suggestions.add(key);
                }
              });
              return ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context,index){
                    return Material(
                      child: FutureBuilder<QuerySnapshot>(
                        future: FireStoreUtils.getUserByUserID(suggestions[index]),
                        builder: (builder, result){
                          MyUser resUser = MyUser();
                          if(result.hasData){
                            result.data!.docs.forEach((element) { resUser = MyUser.fromJsonDocument(element);});
                          }
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => showProfile(context, profileId: resUser.userID),
                                child: ListTile(
                                  tileColor: Colors.black,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    backgroundImage: CachedNetworkImageProvider(
                                        resUser.profilePictureURL),
                                  ),
                                  title: Text(
                                    resUser.uniqueName,
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    resUser.name,
                                    style: TextStyle(
                                      color: Colors.amber[200],
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Divider(color: Colors.amber,height: 0,)
                            ],
                          );
                        },
                      ),
                    );
                  }
              );
            }
          }
      ),
    );
  }
}

