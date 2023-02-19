import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String ownerId;
  final String uniqueName;
  final String location;
  final String cocktail;
  final String description;
  final String mediaUrl;
  Map likes;

  Post(
      {required this.postId,
        required this.ownerId,
        required this.uniqueName,
        required this.location,
        required this.cocktail,
        required this.description,
        required this.mediaUrl,
        required this.likes});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      uniqueName: doc['username'],
      location: doc['location'],
      cocktail: doc.data().toString().contains('cocktail') ? doc['cocktail'] : '',
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    if (likes == {}) {
      return 0;
    }

    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }
}
