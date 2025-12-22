import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';

abstract class SocialAuthType {
  String get requestFunction;
  String get requestMethodName;
  String get verifyFunction;
  String get verifyMethodName;
  Map<String, dynamic>? get requestParams => NsgLoginModel().toJson();
  Map<String, dynamic>? getVerifyParams(NsgSocialLoginResponse response) {
    var login = NsgLoginModel();
    login.code = response.code;
    login.deviceId = response.deviceId;
    login.state = response.state;
    return login.toJson();
  }

  Widget get icon;
  String get socialName;
}
