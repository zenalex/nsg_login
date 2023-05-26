import 'package:flutter/material.dart';

class NsgScaffoldService {
  static final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  static void showSnackBar({required Widget content}) {
    scaffoldKey.currentState?.showSnackBar(SnackBar(content: content));
  }
}
