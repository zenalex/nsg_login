import 'package:flutter/material.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

abstract class MainLoginType extends SocialAuthType {
  String get tabTitle;
  List<MainLoginField> get requestFields;
  List<MainLoginField> get verifyFields;
}

class MainLoginField {
  MainLoginField({required this.label, required this.controller});
  String label;
  TextEditingController controller;
}
