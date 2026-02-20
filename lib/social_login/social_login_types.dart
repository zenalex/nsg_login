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

  /// Нативная авторизация на устройстве (например, Apple Sign In).
  /// Если true, вместо веб-флоу (request URL → WebView → verify)
  /// вызывается [performNativeAuth], результат отправляется на verify.
  bool get useNativeAuth => false;

  /// Выполняет нативную авторизацию на устройстве.
  /// Возвращает [NsgSocialLoginResponse] с code/state для верификации,
  /// или null если пользователь отменил.
  Future<NsgSocialLoginResponse?> performNativeAuth() async => null;

  Widget get icon;
  String get socialName;
}
