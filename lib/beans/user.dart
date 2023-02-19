import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class MyUser {
  String email;

  String name;

  String uniqueName;

  String bio;

  String favouriteCocktail;

  String userID;

  String profilePictureURL;

  String appIdentifier;

  MyUser(
      {this.email = '',
      this.name = '',
      this.uniqueName = '',
      this.favouriteCocktail = '',
      this.userID = '',
      this.bio = '',
      this.profilePictureURL = ''})
      : this.appIdentifier = 'Flutter Login Screen ${Platform.operatingSystem}';

  factory MyUser.fromJson(Map<String, dynamic> parsedJson) {
    return MyUser(
        email: parsedJson['email'] ?? '',
        name: parsedJson['name'] ?? '',
        uniqueName: parsedJson['uniqueName'] ?? '',
        favouriteCocktail: parsedJson['favouriteCocktail'] ?? '',
        bio: parsedJson['bio'] ?? '',
        userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? '');
  }

  factory MyUser.fromJsonDocument(DocumentSnapshot parsedJson) {
    return MyUser(
        email: parsedJson['email'] ?? '',
        name: parsedJson['name'] ?? '',
        uniqueName: parsedJson['uniqueName'] ?? '',
        favouriteCocktail: parsedJson.data().toString().contains('favouriteCocktail') ? parsedJson['favouriteCocktail'] : '',
        bio: parsedJson['bio'] ?? '',
        userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'email': this.email,
      'name': this.name,
      'uniqueName': this.uniqueName,
      'favouriteCocktail': this.favouriteCocktail,
      'bio': this.bio,
      'id': this.userID,
      'profilePictureURL': this.profilePictureURL,
      'appIdentifier': this.appIdentifier
    };
  }
}
