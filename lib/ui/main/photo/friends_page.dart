import 'package:flutter/material.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/constants.dart';
import 'package:provauth/ui/main/photo/friends_provider.dart';
import 'package:provauth/ui/main/photo/friends_tile_widget.dart';
import 'package:provider/provider.dart';

import 'search_widget.dart';

class friendsPage extends StatefulWidget {
  final bool isMultiSelection;
  final List<MyUser> friends;

  const friendsPage({
    this.isMultiSelection = false,
    this.friends = const [],
  });

  @override
  _CountryPageState createState() => _CountryPageState();
}

class _CountryPageState extends State<friendsPage> {
  String text = '';
  List<MyUser> selectedCountries = [];
  bool isNative = false;

  @override
  void initState() {
    super.initState();

    selectedCountries = widget.friends;
  }

  bool containsSearchText(MyUser friend) {
    final name = friend.uniqueName;
    final textLower = text.toLowerCase();
    final countryLower = name.toLowerCase();

    return countryLower.contains(textLower);
  }

  List<MyUser> getPrioritizedFriends(List<MyUser> friends) {
    final notSelectedCountries = List.of(friends)
      ..removeWhere((country) => selectedCountries.contains(country));

    return [
      ...List.of(selectedCountries)..sort(Utils.ascendingSort),
      ...notSelectedCountries,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendsProvider>(context);
    final allCountries = getPrioritizedFriends(provider.countries);
    final countries = allCountries.where(containsSearchText).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: buildAppBar(),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: countries.map((country) {
                  final isSelected = selectedCountries.contains(country);

                  return Column(
                    children: [
                      FriendListTileWidget(
                        country: country,
                        isNative: isNative,
                        isSelected: isSelected,
                        onSelectedCountry: selectCountry,
                      ),
                      const Divider(color: Colors.amber,height: 0,)
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppBar() {

    return AppBar(
      leading: IconButton(color: Colors.black, icon: Icon(Icons.arrow_back), onPressed: submit,),
      backgroundColor: const Color(COLOR_PRIMARY),
      title: const Text('Select friends',style: TextStyle(color:Colors.black),),

      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SearchWidget(
          text: text,
          onChanged: (text) => setState(() => this.text = text),
          hintText: 'Search friends',
        ),
      ),
    );
  }

  Widget buildSelectButton(BuildContext context) {
    final label = widget.isMultiSelection
        ? 'Select ${selectedCountries.length} Countries'
        : 'Continue';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: Theme.of(context).primaryColor,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          minimumSize: Size.fromHeight(40),
          primary: Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        onPressed: submit,
      ),
    );
  }

  void selectCountry(MyUser country) {
    if (widget.isMultiSelection) {
      final isSelected = selectedCountries.contains(country);
      setState(() => isSelected
          ? selectedCountries.remove(country)
          : selectedCountries.add(country));
    } else {
      Navigator.pop(context, country);
    }
  }

  void submit() => Navigator.pop(context, selectedCountries);
}

class Utils {
  static int ascendingSort(MyUser c1, MyUser c2) =>
      c1.uniqueName.compareTo(c2.uniqueName);
}
