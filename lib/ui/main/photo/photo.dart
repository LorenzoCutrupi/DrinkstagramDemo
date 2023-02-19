import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/main/photo/edit_photo.dart';
import 'package:provauth/ui/widgets/drink_choicebox.dart';
import 'package:provauth/ui/widgets/progress.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../constants.dart';
import 'friends_page.dart';

class Upload extends StatefulWidget {
  final MyUser currentUser;

  Upload({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  late Position position;
  bool positionInitialized = false;
  String cocktailName = '';
  final controllerCocktails = TextEditingController();
  XFile? file;
  var bytes;
  bool isUploading = false;
  String postId = const Uuid().v4();
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  List<MyUser> friends = [];

  @override
  void initState() {
    cocktailsList.clear();
    drinkNameToImage.forEach((key, value) {
      Cocktail cocktail = Cocktail(key, value);
      cocktailsList.add(cocktail);
    });
  }

  bool isFileAVideo(String path) {
    List<String> videoFormats = ['mp4', 'mov', 'avi'];
    List<String> parts = path.split('.');
    if (videoFormats.contains(parts[parts.length - 1])) {
      return true;
    }
    return false;
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 960, maxHeight: 675);
    file = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPhotoScreen(
            arguments: file,
          ),
        ));
    setState(() {
      this.file = file;
      bytes = File(file!.path).readAsBytesSync();
    });
  }

  handleTakeVideo() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker().pickVideo(
        source: ImageSource.camera, maxDuration: const Duration(seconds: 10));
    setState(() {
      this.file = file;
      bytes = File(file!.path).readAsBytesSync();
    });
  }

  handleChooseImageFromGallery() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 960, maxHeight: 675);
    setState(() {
      this.file = file;
      bytes = File(file!.path).readAsBytesSync();
    });
  }

  handleChooseVideoFromGallery() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker().pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(seconds: 10));
    setState(() {
      this.file = file;
      bytes = File(file!.path).readAsBytesSync();
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: Colors.amber[300],
            title: const Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                child: const Text('Photo with Camera'),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: const Text('Image from Gallery'),
                onPressed: handleChooseImageFromGallery,
              ),
              SimpleDialogOption(
                child: const Text('Video with Camera'),
                onPressed: handleTakeVideo,
              ),
              SimpleDialogOption(
                child: const Text('Video from Gallery'),
                onPressed: handleChooseVideoFromGallery,
              ),
              SimpleDialogOption(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(left: 7),
              child: GestureDetector(
                  onTap: () => selectImage(context),
                  child: SvgPicture.asset('assets/images/upload.svg',
                      height: 260))),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () => selectImage(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.amberAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Upload',
                style: TextStyle(color: Colors.black, fontSize: 22.0),
              ),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
      bytes = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    File file1 = File(file!.path);
    Im.Image? imageFile = Im.decodeImage(file1.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = XFile(compressedImageFile.path);
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadVideo(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$postId.mp4").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {required String mediaUrl,
      required String cocktail,
      required String location,
      required String description,
      required List<MyUser> tagged}) async {
    String oldPostId = postId;
    List<String> taggedIds = [];
    for (var element in tagged) {
      taggedIds.add(element.userID);
    }

    postsRef
        .doc(widget.currentUser.userID)
        .collection('userPosts')
        .doc(oldPostId)
        .set({
      "postId": oldPostId,
      "ownerId": widget.currentUser.userID,
      "username": widget.currentUser.uniqueName,
      "mediaUrl": mediaUrl,
      "cocktail": cocktail,
      "description": description,
      "location": location,
      "timestamp": DateTime.now(),
      "tagged": taggedIds,
      "likes": {},
    });

    List<MyUser> friendsList = [];
    QuerySnapshot snapshot =
        await friendsRef.doc(current.userID).collection('mutual').get();
    for (var doc in snapshot.docs) {
      QuerySnapshot boh =
          await FireStoreUtils.getUserByUserID(doc.reference.id);
      friendsList.add(MyUser.fromJsonDocument(boh.docs.first));
    }

    for (var element in taggedIds) {
      activityFeedRef.doc(element).collection('feedItems').add({
        'type': 'tagged',
        'commentData': '',
        'timestamp': DateTime.now(),
        'postId': oldPostId,
        'postOwnerId': current.userID,
        'username': current.uniqueName,
        'userId': current.userID,
        'userProfileImg': current.profilePictureURL,
        "mediaUrl": mediaUrl,
      });
    }

    for (var friend in friendsList) {
      timelineRef
          .doc(friend.userID)
          .collection('timelinePosts')
          .doc(oldPostId)
          .set({
        "postId": oldPostId,
        "ownerId": widget.currentUser.userID,
        "timestamp": DateTime.now(),
      });
    }
  }

  Widget buildSelectFriends() {
    final countriesText =
        friends.map((country) => country.uniqueName).join(', ');

    onTap() async {
      final countries = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => friendsPage(
                  isMultiSelection: true,
                  friends: List.of(friends),
                )),
      );

      if (countries == null) return;

      setState(() => friends = countries);
    }

    return buildCountryPicker(
      child: friends.isEmpty
          ? buildListTile(title: 'Who are you drinking with?', onTap: onTap)
          : buildListTile(title: countriesText, onTap: onTap),
    );
  }

  Widget buildCountryPicker({
    required Widget child,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: child,
            color: Colors.black,
          ),
        ],
      );

  Widget buildListTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(
          Icons.group,
          color: Colors.amber[800],
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.amber[100], fontSize: 16),
      ),
      trailing: Icon(Icons.arrow_drop_down, color: Colors.black),
    );
  }

  editPhoto() async {
    XFile? fileTemp = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPhotoScreen(
            arguments: this.file,
          ),
        ));
    setState(() {
      this.file = fileTemp;
      bytes = File(file!.path).readAsBytesSync();
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    String mediaUrl = '';
    if (isFileAVideo(file!.path)) {
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(file!.path);
      print(mediaInfo);
      mediaUrl = await uploadVideo(File(file!.path));
    } else {
      await compressImage();
      mediaUrl = await uploadImage(File(file!.path));
    }
    if (positionInitialized) {
      FireStoreUtils.updateCurrentPosition(position);
    }
    createPostInFirestore(
        cocktail: controllerCocktails.text,
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text,
        tagged: friends);
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      bytes = null;
      isUploading = false;
      postId = const Uuid().v4();
      currentIndex = 4;
    });
  }

  Widget buildImageView() {
    return SizedBox(
      height: MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width,
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
            onTap: () => editPhoto(), child: Image.memory(bytes)),
      ),
    );
  }

  Widget buildVideoView() {
    File toShow = File(this.file!.path);
    return SizedBox(
      height: MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width,
      child: AspectRatio(
        aspectRatio: 1,
        child: Chewie(
          controller: ChewieController(
              autoPlay: true,
              looping: true,
              videoPlayerController: VideoPlayerController.file(toShow)),
        ),
      ),
    );
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: clearImage,
        ),
        title: const Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Post',
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0),
            ),
            onPressed: isUploading ? null : () => handleSubmit(),
          )
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          children: <Widget>[
            isUploading ? linearProgress() : const Text(""),
            isFileAVideo(file!.path) ? buildVideoView() : buildImageView(),
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
            ),
            const Divider(color: Color(0xFFFFE082)),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(
                    widget.currentUser.profilePictureURL),
              ),
              title: SizedBox(
                width: 250.0,
                child: TextField(
                  cursorColor: Color(COLOR_PRIMARY),
                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                  controller: captionController,
                  decoration: const InputDecoration(
                      hintStyle: TextStyle(color: Color(0xFFFFECB3)),
                      hintText: 'Write a caption',
                      border: InputBorder.none),
                ),
              ),
            ),
            const Divider(color: Color(0xFFFFE082)),
            ListTile(
              leading: (cocktailName != '' &&
                      drinkNameToImage[cocktailName] != null)
                  ? Image(
                      image:
                          AssetImage(drinkNameToImage[cocktailName] as String),
                      width: 40,
                      height: 40,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.local_drink,
                        color: Colors.amber[800],
                      ),
                    ),
              title: TypeAheadFormField<Cocktail>(
                textFieldConfiguration: TextFieldConfiguration(
                  style: const TextStyle(color: Color(COLOR_PRIMARY)),
                  cursorColor: Color(COLOR_PRIMARY),
                  controller: controllerCocktails,
                  decoration: const InputDecoration(
                    hintText: 'What cocktail are you drinking?',
                    hintStyle: TextStyle(
                      color: Color(0xFFFFECB3),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(COLOR_PRIMARY))),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(COLOR_PRIMARY))),
                  ),
                ),
                suggestionsCallback: getSuggestions,
                itemBuilder: (context, Cocktail? suggestion) => ListTile(
                  tileColor: Colors.black87,
                  title: Text(
                    suggestion!.name,
                    style: TextStyle(color: Color(COLOR_PRIMARY)),
                  ),
                  leading: Image(
                    image: AssetImage(suggestion.url),
                    height: 40,
                    width: 40,
                  ),
                ),
                onSuggestionSelected: (Cocktail? suggestion) {
                  controllerCocktails.text = suggestion!.name;
                  setState(() {
                    cocktailName = suggestion.name;
                  });
                },
              ),
            ),
            const Divider(color: Color(0xFFFFE082)),
            buildSelectFriends(),
            const Divider(color: Color(0xFFFFE082)),
            ListTile(
              leading: const Icon(
                Icons.pin_drop,
                color: Colors.orange,
                size: 35,
              ),
              title: SizedBox(
                width: 280,
                child: TextField(
                  cursorColor: Color(COLOR_PRIMARY),
                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                  controller: locationController,
                  decoration: const InputDecoration(
                      hintStyle: TextStyle(color: Color(0xFFFFECB3)),
                      hintText: 'Where was this photo taken ?',
                      border: InputBorder.none),
                ),
              ),
            ),
            Container(
              width: 200.0,
              height: 50.0,
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                label: const Text(
                  'Use Current Location',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  primary: Colors.amber[700],
                ),
                onPressed: getUserLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(color: Color(0xFFFFE082)),
            Padding(padding: EdgeInsets.only(top: 100))
          ],
        ),
      ),
    );
  }

  getUserLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      positionInitialized = true;
    });
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String formatedAdress = "${placemark.street},${placemark.locality}";
    locationController.text = formatedAdress;
  }

  static List<Cocktail> getSuggestions(String query) =>
      List.of(cocktailsList).where((cocktail) {
        final cocktailLower = cocktail.name.toLowerCase();
        final queryLower = query.toLowerCase();

        return cocktailLower.contains(queryLower);
      }).toList();

  @override
  get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
