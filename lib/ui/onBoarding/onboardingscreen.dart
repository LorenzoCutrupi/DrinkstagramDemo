import 'package:flutter/material.dart';
import 'package:provauth/services/helper.dart';
import 'package:provauth/ui/auth/authscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../constants.dart';

class OnBoardingScreen extends StatefulWidget {
  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  PageController pageController = PageController();
  final List<String> _titlesList = [
    'Post your drinking adventures',
    'Connect with your friends',
    'Login with Facebook or Google',
    'Drinkstagram',
    'Jump straight into the action.'
  ];

  final List<String> _subtitlesList = [
    'Take a photo every time you drink.',
    'Add them in your friends list.',
    'Use your accounts to an easier access.',
    'The favourite app of the alcoholics',
    'Get Started'
  ];

  final List<dynamic> _imageList = [
    Icons.photo_camera_rounded,
    Icons.group_add,
    Icons.login,
    'assets/images/beer.png',
    Icons.play_circle_fill
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(COLOR_PRIMARY),
      body: Stack(
        children: <Widget>[
          PageView.builder(
            itemBuilder: (context, index) => getPage(
                _imageList[index],
                _titlesList[index],
                _subtitlesList[index],
                context,
                index + 1 == _titlesList.length),
            controller: pageController,
            itemCount: _titlesList.length,
            onPageChanged: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Visibility(
            visible: _currentIndex + 1 == _titlesList.length,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Directionality.of(context) == TextDirection.ltr
                      ? Alignment.bottomRight
                      : Alignment.bottomLeft,
                  child: OutlinedButton(
                    onPressed: () {
                      setFinishedOnBoarding();
                      pushReplacement(context, AuthScreen());
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white),
                        shape: StadiumBorder()),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SmoothPageIndicator(
                controller: pageController,
                count: _titlesList.length,
                effect: ScrollingDotsEffect(
                    activeDotColor: Colors.white,
                    dotColor: Colors.grey.shade400,
                    dotWidth: 8,
                    dotHeight: 8),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getPage(dynamic image, String title, String subTitle,
      BuildContext context, bool isLastPage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        image is String
            ? Image.asset(
                image,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              )
            : Icon(
                image as IconData,
                color: Colors.white,
                size: 150,
              ),
        SizedBox(height: 40),
        Text(
          title.toUpperCase(),
          style: TextStyle(
              color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<bool> setFinishedOnBoarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(FINISHED_ON_BOARDING, true);
  }
}
