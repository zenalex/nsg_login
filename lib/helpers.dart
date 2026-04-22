import 'package:flutter/material.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';

class NsgScaffoldService {
  static final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  static void showSnackBar({required Widget content}) {
    scaffoldKey.currentState?.showSnackBar(SnackBar(content: content));
  }
}

NsgLoginLocalizations get tran =>
    NsgLoginLocalizations.of(NsgNavigator.currentContext!)!;
