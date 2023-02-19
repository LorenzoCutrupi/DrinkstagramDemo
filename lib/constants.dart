import 'dart:collection';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provauth/ui/widgets/drink_choicebox.dart';

const FINISHED_ON_BOARDING = 'finishedOnBoarding';
const COLOR_PRIMARY = 0xFFFFCA28;
const FACEBOOK_BUTTON_COLOR = 0xFF415893;
const USERS = 'users';
final Reference storageRef = FirebaseStorage.instance.ref();
final CollectionReference postsRef = FirebaseFirestore.instance.collection('posts');
final CollectionReference friendsRef = FirebaseFirestore.instance.collection('friends');
final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
final CollectionReference commentsRef = FirebaseFirestore.instance.collection('comments');
final CollectionReference activityFeedRef = FirebaseFirestore.instance.collection('feed');
final CollectionReference timelineRef = FirebaseFirestore.instance.collection('timeline');
final CollectionReference locationRef = FirebaseFirestore.instance.collection('location');
final DateTime timestamp = DateTime.now();
final Map<String,String> drinkNameToImage = {'Bloody Mary':'assets/drinks/bloody_mary.png',
  'Beer':'assets/drinks/beer.png','Black Russian':'assets/drinks/black_russian.png','White Russian':'assets/drinks/white_russian.png',
'Cuba Libre': 'assets/drinks/cuba_libre.png','Gin Tonic': 'assets/drinks/gin_tonic.png','Negroni':'assets/drinks/negroni.png',
'Margarita': 'assets/drinks/margarita.png', 'Martini Dry': 'assets/drinks/martini.png','Negroski':'assets/drinks/negroski.png',
  'Sbagliato':'assets/drinks/americano.png','Americano':'assets/drinks/americano.png','Whiskey Cola':'assets/drinks/whiskey_cola.png',
  'Old Fashioned':'assets/drinks/old_fashioned.png',
'Mojito' : 'assets/drinks/mojito.png', 'Pina Colada':'assets/drinks/pina_colada.png','Small Beer':'assets/drinks/small_beer.png'};

List<Cocktail> cocktailsList = [];
