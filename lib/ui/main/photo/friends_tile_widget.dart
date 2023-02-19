import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/constants.dart';

class FriendListTileWidget extends StatelessWidget {
  final MyUser country;
  final bool isNative;
  final bool isSelected;
  final ValueChanged<MyUser> onSelectedCountry;

  const FriendListTileWidget({
    required this.country,
    required this.isNative,
    required this.isSelected,
    required this.onSelectedCountry,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.amber;
    final style = isSelected
        ? TextStyle(
            fontSize: 18,
            color: selectedColor,
            fontWeight: FontWeight.bold,
          )
        : const TextStyle(fontSize: 18, color: Color(COLOR_PRIMARY));

    return ListTile(
      onTap: () => onSelectedCountry(country),
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        backgroundImage: CachedNetworkImageProvider(country.profilePictureURL),
      ),
      title: Text(
        country.uniqueName,
        style: style,
      ),
      subtitle: Text(country.name,style: TextStyle(color: Color(COLOR_PRIMARY))),
      trailing: isSelected
          ? Icon(Icons.check_box_outlined, color: selectedColor, size: 26)
          : const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 26),
    );
  }
}
