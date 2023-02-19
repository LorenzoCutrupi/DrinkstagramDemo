import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provauth/beans/user.dart';
import 'package:provauth/constants.dart';
import 'package:provauth/services/auth_service.dart';
import 'package:provauth/ui/main/mainpage.dart';
import 'package:url_launcher/url_launcher.dart';

class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  late final Future<Position> _init;
  late Future<List<Marker>> _markers;

  @override
  void initState() {
    super.initState();
    _init = getUserPosition();
    _markers = getMarkers();
  }

  Future<Position> getUserPosition() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<Marker>> getMarkers() async {
    List<Marker> markerTemp = [];
    List<String> friendsList = [];
    friendsList = await FireStoreUtils().getFriendsList(current.userID);

    try {
      for (var friend in friendsList) {
        DocumentSnapshot document = await locationRef.doc(friend).get();
        if (document.exists) {
          QuerySnapshot snapshotTemp =
              await FireStoreUtils.getUserByUserID(friend);
          MyUser userTemp = MyUser.fromJsonDocument(snapshotTemp.docs.first);
          Timestamp timestamp = document.get("timestamp");
          DateTime time = timestamp.toDate().add(const Duration(hours: 3));
          if (time.isBefore(DateTime.now())) {
            await locationRef.doc(friend).delete();
          } else {
            markerTemp.add(
              Marker(
                width: 70.0,
                height: 70.0,
                point: LatLng(document.get("latitude"), document.get("longitude")),
                builder: (ctx) => GestureDetector(
                  onTap: () => openMap(document.get("latitude"),document.get("longitude")),
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: CircleAvatar(
                      radius: 33,
                      backgroundColor: Colors.blue,
                      backgroundImage: CachedNetworkImageProvider(
                          userTemp.profilePictureURL),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return markerTemp;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marker>>(
        future: _markers,
        builder: (context, snapshot) {
          if (snapshot.hasError || !snapshot.hasData) {
            return Container();
          }
          List<Marker>? markers = snapshot.data as List<Marker>;
          return FutureBuilder<Position>(
              future: _init,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  // Return a widget to be shown while the position is being fetch
                  return Center(child: CircularProgressIndicator());

                if (snapshot.hasError)
                  // Return a widget to be shown if an error ocurred while fetching
                  return Text("${snapshot.error}");

                // You can access `position` here
                final Position position = snapshot.data!;
                return FlutterMap(
                  options: MapOptions(
                    center: LatLng(position.latitude, position.longitude),
                    zoom: 13.0,
                  ),
                  layers: [
                    TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      attributionBuilder: (_) {
                        return Text("© OpenStreetMap contributors");
                      },
                    ),
                    MarkerLayerOptions(
                      markers: markers,
                    ),
                  ],
                );
              });
        });
  }
}

Future<void> openMap(double latitude, double longitude) async {
  String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not open the map';
  }
}
