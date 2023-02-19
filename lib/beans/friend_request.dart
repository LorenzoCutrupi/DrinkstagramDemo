import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provauth/beans/user.dart';

class FriendRequest {

  final String uniqueName,userID,name,mediaURL;

  FriendRequest({required this.userID,required this.uniqueName, required this.name, required this.mediaURL});

}