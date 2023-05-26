// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_controls/widgets/nsg_snackbar.dart';

import 'nsgPhoneLoginPage.dart';

class NsgPhoneLoginParams {
  String phoneNumber;
  String email;
  bool usePasswordLogin;
  bool usePhoneLogin;
  bool useEmailLogin;
  double cardSize;
  double iconSize;
  double buttonSize;
  String headerMessage;
  String headerMessageVerification;
  String headerMessageLogin;
  String headerMessageRegistration;
  String descriptionMessegeVerificationEmail;
  String descriptionMessegeVerificationPhone;
  TextStyle? headerMessageStyle;
  String textEnterPhone;
  String textEnterEmail;
  String textSendSms;
  String textResendSms;
  String textEnterCaptcha;
  String textLoginSuccessful;
  String textEnterCorrectPhone;
  String textCheckInternet;
  String textEnterCode;
  String textEnterPassword;
  String textEnterNewPassword;
  String textEnterPasswordAgain;
  TextStyle? descriptionStyle;
  TextStyle? textPhoneField;
  Color? cardColor;
  Color textColor;
  Color fillColor;
  Color disableButtonColor;
  Color? sendSmsButtonColor;
  Color? sendSmsBorderColor;
  Color? phoneIconColor;
  Color? phoneFieldColor;
  NsgLoginType? loginType;
  final bool useCaptcha;
  dynamic parameter;
  String Function(int)? errorMessageByStatusCode;
  void Function(BuildContext? context, dynamic parameter)? loginSuccessful;
  void Function()? loginFailed;
  String mainPage;

  static NsgPhoneLoginParams defaultParams = NsgPhoneLoginParams();
  bool? appbar;
  bool? headerMessageVisible;

  NsgPhoneLoginParams(
      {this.loginType,
      this.email = '',
      this.phoneNumber = '',
      this.usePasswordLogin = false,
      this.usePhoneLogin = true,
      this.useEmailLogin = false,
      this.cardSize = 345.0,
      this.iconSize = 28.0,
      this.buttonSize = 42.0,
      this.headerMessage = 'NSG Application',
      this.headerMessageLogin = 'Вход', // 'Enter',
      this.headerMessageRegistration = 'Регистрация', // 'Registration',
      this.headerMessageVerification = 'Введите код', // 'Enter security code',
      this.descriptionMessegeVerificationPhone =
          'Мы отправили вам код в СМС\nна номер телефона: \n{{phone}}', // 'We sent code in SMS\nto phone number\n{{phone}}',
      this.descriptionMessegeVerificationEmail =
          'Мы отправили вам код в сообщении\nна e-mail: \n{{phone}}', // 'We sent code in SMS\nto phone number\n{{phone}}',
      this.headerMessageStyle,
      this.textEnterCode = 'Код', //'Code',
      this.textEnterPhone = 'Введите номер телефона', //'Enter your phone',
      this.textEnterEmail = 'Введите ваш e-mail', //'Enter your email',
      this.textEnterPassword = 'Введите ваш пароль', // 'Enter you password',
      this.textEnterNewPassword =
          'Введите новый пароль', //'Enter new password',
      this.textEnterPasswordAgain =
          'Введите второй раз ваш пароль', // 'Enter password again',
      this.textResendSms = 'Отправить СМС заново', //'Send SMS again',
      this.descriptionStyle,
      this.textSendSms = 'Отправить СМС', // 'Send SMS',
      this.textEnterCaptcha = 'Введите текст Капчи', // 'Enter captcha text',
      this.textLoginSuccessful = 'Успешный логин', //'Login successful',
      this.textEnterCorrectPhone =
          'Введите корректный номер', // 'Enter correct phone',
      this.textCheckInternet =
          'Невозможно выполнить запрос. Проверьте соединение с интернетом.', //'Cannot compleate request. Check internet connection and repeat.',
      this.textPhoneField,
      this.cardColor,
      this.textColor = Colors.black,
      this.fillColor = Colors.black,
      this.disableButtonColor = Colors.blueGrey,
      this.sendSmsButtonColor,
      this.sendSmsBorderColor,
      this.phoneIconColor,
      this.phoneFieldColor,
      this.errorMessageByStatusCode,
      this.appbar,
      this.headerMessageVisible = false,
      this.useCaptcha = true,
      this.mainPage = ''}) {
    headerMessageStyle ??= TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      color: ControlOptions.instance.colorText,
    );
    textPhoneField ??= const TextStyle(
      fontSize: 18.0,
      fontFamily: 'Roboto',
      color: Color.fromRGBO(2, 54, 92, 1.0),
      fontWeight: FontWeight.normal,
    );
    headerMessageStyle ??= TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18.0,
      color: ControlOptions.instance.colorText,
    );
    cardColor ??= Colors.white;
    sendSmsButtonColor ??= const Color.fromRGBO(0, 101, 175, 1.0);
    sendSmsBorderColor ??= const Color.fromRGBO(0, 301, 175, 1.0);
    phoneIconColor ??= const Color.fromRGBO(50, 50, 50, 1.0);
    phoneFieldColor ??= const Color.fromRGBO(2, 54, 92, 0.1);

    errorMessageByStatusCode ??= errorMessage;
  }

  String interpolate(String string, {Map<String, dynamic> params = const {}}) {
    var keys = params.keys;
    var result = string;
    for (var key in keys) {
      if (string.contains('{{$key}}')) {
        result = result.replaceAll('{{$key}}', params[key].toString());
      }
    }
    return result;
  }

  String errorMessage(int statusCode) {
    String message;
    switch (statusCode) {
      case 40101:
        message = 'You have to get captha first';
        break;
      case 40102:
        message = 'Captcha is obsolet. Try again!';
        break;
      case 40103:
        message = 'Captcha text is wrong. Try again!';
        break;
      case 40104:
        message = 'You have to enter you phone number!';
        break;
      case 40105:
        message = 'You have to enter captcha text!';
        break;
      case 40300:
        message = 'Wrong security code. Try again!';
        break;
      case 40301:
        message = 'You entered wrong code too many times!';
        break;
      case 40302:
        message = 'Security code is obsolete';
        break;
      case 40303:
        message = 'You have to enter captcha first';
        break;
      default:
        message = statusCode == 0 ? '' : 'Error $statusCode is occured';
    }
    return message;
  }

  void showError(BuildContext context, String message) {
    if (message == '') return;
    nsgSnackbar(
      context,
      type: NsgSnarkBarType.error,
      text: message,
      duration: const Duration(seconds: 5),
    );
  }
}