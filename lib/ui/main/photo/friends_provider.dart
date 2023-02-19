import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/constants.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';

import 'friends_page.dart';

class FriendsProvider with ChangeNotifier {
  FriendsProvider() {
    loadCountries().then((countries) {
      _countries = countries;
      notifyListeners();
    });
  }

  List<MyUser> _countries = [];

  List<MyUser> get countries => _countries;

  Future loadCountries() async {
    /*final data = await rootBundle.loadString('assets/country_codes.json');
    final countriesJson = json.decode(data);

    return countriesJson.keys.map<MyUser>((code) {
      final json = countriesJson[code];
      final newJson = json..addAll({'code': code.toLowerCase()});

      return MyUser.fromJson(newJson);
    }).toList()
      ..sort(Utils.ascendingSort);*/

    List<String> list = await FireStoreUtils().getFriendsList(current.userID);
    List<MyUser> users = [];
    for (var element in list) {
      QuerySnapshot snapshotTemp = await FireStoreUtils.getUserByUserID(element);
      MyUser tempUser = MyUser.fromJsonDocument(snapshotTemp.docs.first);
      users.add(tempUser);
    }

    return users..sort(Utils.ascendingSort);
  }
}