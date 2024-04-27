/*import 'package:flutter/material.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/nsg_data.dart' as nsg_data;
import 'package:nsg_login/nsg_snackbar.dart';
import 'package:nsg_login/pages/nsg_login_params.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nsg_login_model.dart';

enum NsgLoginType { phone, email }

class NsgLoginProvider {
  String phoneNumber = '';
  nsg_data.NsgDataProvider provider;
  bool saveToken = true;
  DateTime? smsRequestedTime;
  bool saveTokenWebDefaultTrue = false;
  final NsgLoginParams widgetParams;

  NsgLoginProvider({required this.provider, required this.widgetParams});

  Future<NsgLoginResponse> phoneLoginRequestSMS(
      {required String phoneNumber,
      required String securityCode,
      NsgLoginType? loginType,
      required String firebaseToken}) async {
    this.phoneNumber = phoneNumber;
    var login = NsgPhoneLoginModel();
    login.phoneNumber = phoneNumber;
    if (loginType != null) login.loginType = loginType;
    if (securityCode == '') {
      login.register = true;
    }
    login.securityCode = securityCode == '' ? 'security' : securityCode;
    login.firebaseToken = firebaseToken;
    var s = login.toJson();
    Map<String, dynamic>? response;
    await nsgFutureProgressAndException(func: () async {
      response = await (provider.baseRequest(
          function: 'PhoneLoginRequestSMS',
          headers: provider.getAuthorizationHeader(),
          url:
              '${provider.serverUri}/${provider.authorizationApi}/PhoneLoginRequestSMS',
          method: 'POST',
          params: s));
    });

    var loginResponse = NsgLoginResponse.fromJson(response);
    if (loginResponse.errorCode == 0) {
      smsRequestedTime = DateTime.now();
    }
    return loginResponse;
  }

  Future<NsgLoginResponse> phoneLoginPassword(
      {required String phoneNumber,
      required String securityCode,
      NsgLoginType? loginType}) async {
    this.phoneNumber = phoneNumber;
    var login = NsgPhoneLoginModel();
    login.phoneNumber = phoneNumber;
    if (loginType != null) login.loginType = loginType;
    login.securityCode = securityCode == '' ? 'security' : securityCode;
    var s = login.toJson();

    var response = await (provider.baseRequest(
        function: 'PhoneLoginRequestSMS',
        headers: provider.getAuthorizationHeader(),
        url:
            '${provider.serverUri}/${provider.authorizationApi}/PhoneLoginRequestSMS',
        method: 'POST',
        params: s));

    var loginResponse = NsgLoginResponse.fromJson(response);
    if (loginResponse.errorCode == 0) {
      provider.token = loginResponse.token;
      provider.isAnonymous = loginResponse.isAnonymous;
      if (!provider.isAnonymous && saveToken) {
        var prefs = await SharedPreferences.getInstance();
        await prefs.setString(provider.applicationName, provider.token!);
      }
    }
    return loginResponse;
  }

  Future<NsgLoginResponse> phoneLogin(
      {required String phoneNumber,
      required String securityCode,
      bool? register,
      String? newPassword}) async {
    this.phoneNumber = phoneNumber;
    var login = NsgPhoneLoginModel();
    login.phoneNumber = phoneNumber;
    login.securityCode = securityCode;
    login.register = register ?? false;
    login.newPassword = newPassword;
    var s = login.toJson();

    try {
      var response = await (provider.baseRequest(
          function: 'PhoneLogin',
          headers: provider.getAuthorizationHeader(),
          url: '${provider.serverUri}/${provider.authorizationApi}/PhoneLogin',
          method: 'POST',
          params: s));

      var loginResponse = NsgLoginResponse.fromJson(response);
      if (loginResponse.errorCode == 0) {
        provider.token = loginResponse.token;
        provider.isAnonymous = loginResponse.isAnonymous;
      }
      if (!provider.isAnonymous && provider.saveToken) {
        var prefs = await SharedPreferences.getInstance();
        await prefs.setString(provider.applicationName, provider.token!);
      }

      return loginResponse;
    } catch (e) {
      NsgSnackBar.show(
        null,
        text: 'Произошла ошибка. Попробуйте еще раз.',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red[200]!,
        textColor: Colors.black,
      );
    }
    return NsgLoginResponse(isError: true, errorCode: 500);
  }

  Future<Image> getCaptcha() async {
    var response = await provider.imageRequest(
        debug: provider.isDebug,
        function: 'GetCaptcha',
        url: '${provider.serverUri}/${provider.authorizationApi}/GetCaptcha',
        method: 'GET',
        headers: provider.getAuthorizationHeader());

    return response;
  }
}
*/