import 'package:flutter/material.dart';

AppBar header(BuildContext context,
    {bool isAppTitle = false,
      required String titleText,
      bool removeBackButton = false}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      color: Colors.black,
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      isAppTitle ? 'Flutter Social' : titleText,
      style: TextStyle(
          color: Colors.black,
          fontFamily: isAppTitle ? 'Signatra' : "",
          fontSize: isAppTitle ? 50.0 : 22.0),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).colorScheme.secondary,
  );
}