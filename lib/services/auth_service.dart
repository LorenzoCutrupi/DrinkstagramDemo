import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provauth/beans/friend_request.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/main/notifications/friend_requests.dart';

import '../constants.dart';
import 'helper.dart';

class FireStoreUtils {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static Reference storage = FirebaseStorage.instance.ref();

  static Future<MyUser?> getCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument =
        await firestore.collection(USERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return MyUser.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static getFriendsRequests({required id}) async {
    QuerySnapshot snapshot =
        await friendsRef.doc(id).collection('received').get();
    List<friendRequestItem> feedItems = [];

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      DocumentSnapshot extracted = await usersRef.doc(doc.reference.id).get();
      MyUser tempUser = MyUser.fromJsonDocument(extracted);
      String url = '';
      tempUser.profilePictureURL == ''
          ? null
          : url = tempUser.profilePictureURL;
      FriendRequest fr = FriendRequest(
          userID: tempUser.userID,
          uniqueName: tempUser.uniqueName,
          name: tempUser.name,
          mediaURL: url);
      feedItems.add(friendRequestItem(friendReq: fr));
    }

    return feedItems;
  }

  static removeFriend({required sender, required receiver}) {
    friendsRef.doc(sender).collection('mutual').doc(receiver).delete();
    friendsRef.doc(receiver).collection('mutual').doc(sender).delete();
  }

  static sendFriendRequest({required sender, required receiver}) {
    friendsRef
        .doc(sender)
        .collection('pending')
        .doc(receiver)
        .set(HashMap<String, Object>());
    friendsRef
        .doc(receiver)
        .collection('received')
        .doc(sender)
        .set(HashMap<String, Object>());
  }

  static removeSentFriendRequest({required sender, required receiver}) {
    friendsRef.doc(sender).collection('pending').doc(receiver).delete();
    friendsRef.doc(receiver).collection('received').doc(sender).delete();
  }

  static addMutualFriends({required sender, required receiver}) {
    friendsRef
        .doc(sender)
        .collection('mutual')
        .doc(receiver)
        .set(HashMap<String, Object>());
    friendsRef
        .doc(receiver)
        .collection('mutual')
        .doc(sender)
        .set(HashMap<String, Object>());
    friendsRef.doc(sender).collection('pending').doc(receiver).delete();
    friendsRef.doc(receiver).collection('received').doc(sender).delete();
  }

  static declineFriendRequest({required sender, required receiver}) {
    friendsRef.doc(receiver).collection('received').doc(sender).delete();
    friendsRef.doc(sender).collection('pending').doc(receiver).delete();
  }

  static Future<QuerySnapshot> getUserByUniqueName(String name) async {
    Future<QuerySnapshot> users = firestore
        .collection(USERS)
        .where(
          "uniqueName",
          isGreaterThanOrEqualTo: name,
          isLessThan: name.substring(0, name.length - 1) +
              String.fromCharCode(name.codeUnitAt(name.length - 1) + 1),
        )
        .get();

    return users;
  }

  static Future<QuerySnapshot> getUserByUserID(String userID) async {
    Future<QuerySnapshot> users =
        firestore.collection(USERS).where("id", isEqualTo: userID).get();
    return users;
  }

  static updateCurrentPosition(Position position) async {
    return await locationRef
        .doc(current.userID)
        .set({"latitude": position.latitude,"longitude": position.longitude, "timestamp": DateTime.now()});
  }

  static Future<MyUser> updateCurrentUser(MyUser user) async {
    return await firestore
        .collection(USERS)
        .doc(user.userID)
        .set(user.toJson())
        .then((document) {
      return user;
    });
  }

  static Future<String> uploadUserImageToFireStorage(
      File image, String userID) async {
    Reference upload = storage.child("images/$userID.png");
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  /// login with email and password with firebase
  /// @param email user email
  /// @param password user password
  static Future<dynamic> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await firestore.collection(USERS).doc(result.user?.uid ?? '').get();
      MyUser? user;
      if (documentSnapshot.exists) {
        user = MyUser.fromJson(documentSnapshot.data() ?? {});
      }
      return user;
    } on auth.FirebaseAuthException catch (exception, s) {
      print(exception.toString() + '$s');
      switch ((exception).code) {
        case 'invalid-email':
          return 'Email address is malformed.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'user-not-found':
          return 'No user corresponding to the given email address.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts to sign in as this user.';
      }
      return 'Unexpected firebase error, Please try again.';
    } catch (e, s) {
      print(e.toString() + '$s');
      return 'Login failed, Please try again.';
    }
  }

  // this function checks if uniqueName already exists
  Future<bool> isDuplicateUniqueName(String uniqueName) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection(USERS)
        .where('uniqueName', isEqualTo: uniqueName)
        .get();
    return query.docs.isNotEmpty;
  }

  static loginWithFacebook() async {
    FacebookAuth facebookAuth = FacebookAuth.instance;
    bool isLogged = await facebookAuth.accessToken != null;
    if (!isLogged) {
      LoginResult result = await facebookAuth
          .login(); // by default we request the email and the public profile
      if (result.status == LoginStatus.success) {
        // you are logged
        AccessToken? token = await facebookAuth.accessToken;
        return await handleFacebookLogin(
            await facebookAuth.getUserData(), token!);
      }
    } else {
      AccessToken? token = await facebookAuth.accessToken;
      return await handleFacebookLogin(
          await facebookAuth.getUserData(), token!);
    }
  }

  static handleFacebookLogin(
      Map<String, dynamic> userData, AccessToken token) async {
    auth.UserCredential authResult = await auth.FirebaseAuth.instance
        .signInWithCredential(
            auth.FacebookAuthProvider.credential(token.token));
    MyUser? user = await getCurrentUser(authResult.user?.uid ?? '');
    if (user != null) {
      user.profilePictureURL = userData['picture']['data']['url'];
      user.name = userData['name'];
      user.email = userData['email'];
      user.bio = userData['bio'];
      dynamic result = await updateCurrentUser(user);
      return result;
    } else {
      user = MyUser(
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          bio: userData['bio'] ?? '',
          profilePictureURL: userData['picture']['data']['url'] ?? '',
          userID: authResult.user?.uid ?? '');
      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return errorMessage;
      }
    }
  }

  /// save a new user document in the USERS table in firebase firestore
  /// returns an error message on failure or null on success
  static Future<String?> firebaseCreateNewUser(MyUser user) async =>
      await firestore
          .collection(USERS)
          .doc(user.userID)
          .set(user.toJson())
          .then((value) => null, onError: (e) => e);

  firebaseSignUpWithEmailAndPassword(String emailAddress, String password,
      File? image, String name, String uniqueName) async {
    if (await isDuplicateUniqueName(uniqueName)) {
      // UniqueName is duplicate
      return 'Unique name already exists';
    }

    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailAddress, password: password);
      String profilePicUrl = '';
      if (image != null) {
        await updateProgress('Uploading image, Please wait...');
        profilePicUrl =
            await uploadUserImageToFireStorage(image, result.user?.uid ?? '');
      }

      MyUser user = MyUser(
          email: emailAddress,
          name: name,
          uniqueName: uniqueName,
          bio: '',
          favouriteCocktail: '',
          userID: result.user?.uid ?? '',
          profilePictureURL: profilePicUrl);

      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return 'Couldn\'t sign up for firebase, Please try again.';
      }
    } on auth.FirebaseAuthException catch (error) {
      print(error.toString() + '${error.stackTrace}');
      String message = 'Couldn\'t sign up';
      switch (error.code) {
        case 'email-already-in-use':
          message = 'Email already in use, Please pick another email!';
          break;
        case 'invalid-email':
          message = 'Enter valid e-mail';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password must be more than 5 characters';
          break;
        case 'too-many-requests':
          message = 'Too many requests, Please try again later.';
          break;
      }
      return message;
    } catch (e) {
      return 'Couldn\'t sign up';
    }
  }

  static getFriendsAndPendingList(String id) async {
    QuerySnapshot snapshot =
        await friendsRef.doc(id).collection('mutual').get();
    List<String> feedItems = [];

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      feedItems.add(doc.reference.id);
    }

    snapshot = await friendsRef.doc(id).collection('pending').get();

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      feedItems.add(doc.reference.id);
    }

    return feedItems;
  }

  static getFriendsSnap(String id) async {
    QuerySnapshot snapshot =
        await friendsRef.doc(id).collection('mutual').get();
    return snapshot;
  }

  Future<List<String>> getFriendsList(String id) async {
    QuerySnapshot snapshot =
    await friendsRef.doc(id).collection('mutual').get();
    List<String>? suggestions = [];
    snapshot.docs.forEach((doc) {
      suggestions.add(doc.reference.id);
    });
    return suggestions;
  }

  static getLikesList(String ownerId, String postId) async {
    DocumentSnapshot snapshot =
        await postsRef.doc(ownerId).collection('userPosts').doc(postId).get();
    return snapshot;
  }
}
