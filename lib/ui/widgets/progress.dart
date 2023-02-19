import 'package:flutter/material.dart';

Container circularProgress() {
  return Container(
    child: const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
  );
}

Container linearProgress() {
  return Container(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: const LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
  );
}