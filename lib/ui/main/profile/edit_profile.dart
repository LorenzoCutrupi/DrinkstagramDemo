import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:provauth/ui/widgets/drink_choicebox.dart';
import 'package:provauth/ui/widgets/progress.dart';

import '../../../constants.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final controllerCocktails = TextEditingController();
  String? selectedCocktail;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  XFile? file;
  bool isLoading = false, isUploading = false, imageChanged = false;
  late MyUser user;
  bool _bioValid = true;
  bool _displayNameValid = true;

  @override
  void initState() {
    MyUser temp = current;
    cocktailsList.clear();
    drinkNameToImage.forEach((key, value) {
      Cocktail cocktail = Cocktail(key, value);
      cocktailsList.add(cocktail);
    });
    controllerCocktails.text = (current.favouriteCocktail!='') ? current.favouriteCocktail: '';
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = MyUser.fromJsonDocument(doc);
    displayNameController.text = user.name;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Name',
            style: TextStyle(color: Color(0xFFFFECB3)),
          ),
        ),
        TextField(
          cursorColor: Color(COLOR_PRIMARY),
          style: TextStyle(color: Color(COLOR_PRIMARY)),
          controller: displayNameController,
          decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFFECB3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
              ),
              hintText: 'Update name',
              errorStyle: TextStyle(color: Colors.red),
              errorText: _displayNameValid ? null : 'Name too short'),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Bio',
            style: TextStyle(color: Color(0xFFFFECB3)),
          ),
        ),
        TextField(
          cursorColor: Color(COLOR_PRIMARY),
          style: TextStyle(color: Color(COLOR_PRIMARY)),
          controller: bioController,
          decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFFECB3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
              ),
              hintText: 'Update bio',
              errorStyle: TextStyle(color: Colors.red),
              errorText: _bioValid ? null : 'Bio too long'),
        )
      ],
    );
  }

  updateProfileData() async {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;

      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;

      if (_displayNameValid && _bioValid) {
        current.name = displayNameController.text;
        current.bio = bioController.text;
        current.favouriteCocktail = controllerCocktails.text;
      }
    });
    await handleSubmit();
  }

  Scaffold buildSplashScreen() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.amber,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
            onPressed: () async {
              await updateProfileData();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: isLoading
          ? circularProgress()
          : Container(
              color: Colors.black,
              child: ListView(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          backgroundImage: !imageChanged
                              ? CachedNetworkImageProvider(
                                  user.profilePictureURL)
                              : FileImage(File(file!.path)) as ImageProvider,
                          radius: 50.0,
                          child: Stack(children: [
                            Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white70,
                                child: IconButton(
                                  icon: Icon(Icons.camera_alt_outlined),
                                  onPressed: () => selectPhoto(),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TypeAheadFormField<Cocktail?>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                                  cursorColor: Color(COLOR_PRIMARY),
                                  controller: controllerCocktails,
                                  decoration: const InputDecoration(
                                    hintText: 'Select your favourite drink',
                                    hintStyle: TextStyle(
                                      color: Color(0xFFFFECB3),
                                    ),
                                    labelText: 'Favourite Cocktail',
                                    labelStyle:
                                        TextStyle(color: Color(0xFFFFECB3)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFFFECB3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY))),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY))),
                                  ),
                                ),
                                suggestionsCallback: getSuggestions,
                                itemBuilder: (context, Cocktail? suggestion) =>
                                    ListTile(
                                  tileColor: Colors.black87,
                                  title: Text(
                                    suggestion!.name,
                                    style:
                                        TextStyle(color: Color(COLOR_PRIMARY)),
                                  ),
                                  leading: Image(
                                    image: AssetImage(suggestion.url),
                                    height: 40,
                                    width: 40,
                                  ),
                                ),
                                onSuggestionSelected: (Cocktail? suggestion) =>
                                    controllerCocktails.text = suggestion!.name,
                                onSaved: (value) => selectedCocktail = value,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).viewInsets.bottom))
                ],
              ),
            ),
    );
  }

  static List<Cocktail> getSuggestions(String query) =>
      List.of(cocktailsList).where((cocktail) {
        final cocktailLower = cocktail.name.toLowerCase();
        final queryLower = query.toLowerCase();

        return cocktailLower.contains(queryLower);
      }).toList();

  selectPhoto() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Edit your profile picture'),
            children: <Widget>[
              SimpleDialogOption(
                child: const Text('Photo with Camera'),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: const Text('Image from Gallery'),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 960, maxHeight: 675);
    setState(() {
      imageChanged = true;
      this.file = file;
    });
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 960, maxHeight: 675);
    setState(() {
      imageChanged = true;
      this.file = file;
    });
  }

  clearImage() {
    setState(() {
      imageChanged = false;
      file = null;
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    String mediaUrl;
    if (file != null) {
      mediaUrl = await FireStoreUtils.uploadUserImageToFireStorage(
          File(file!.path), current.userID);
      current.profilePictureURL = mediaUrl;
    }
    FireStoreUtils.updateCurrentUser(current);
    setState(() {
      imageChanged = false;
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildSplashScreen();
  }
}
