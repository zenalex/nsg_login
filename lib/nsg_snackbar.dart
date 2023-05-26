import 'package:flutter/material.dart';

import 'helpers.dart';

const Duration _nsgSnackBarDisplayDuration = Duration(milliseconds: 4000);
const Color _nsgSnackBarBackgroundColor = Colors.red;
const Color _nsgSnackBarTextColor = Colors.black;

class NsgSnackBar {
  static void show(BuildContext? context,
      {required String text,
      Duration duration = _nsgSnackBarDisplayDuration,
      Color backgroundColor = _nsgSnackBarBackgroundColor,
      Color textColor = _nsgSnackBarTextColor}) {
    var snackBar = SnackBar(
        content: Flexible(
            child: Container(
          color: backgroundColor,
          child: Text(text),
        )),
        duration: duration);
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      NsgScaffoldService.showSnackBar(content: snackBar);
    }
  }
}
