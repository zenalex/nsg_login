import 'package:flutter/material.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_controls/widgets/nsg_snackbar.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_params.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

class NsgLoginParams implements NsgLoginParamsInterface {
  /// При добавлении этой функции появляется крестик закрытия окна логина/регистрации
  VoidCallback? get onClose => null;
  VoidCallback? get onLogin => null;

  ///Введенный пользователем телефон для авторизации
  String phoneNumber;

  ///Введенный пользователем email для авторизации
  String email;

  ///Режим авторизации по паролю
  bool usePasswordLogin;

  ///Разрешить авторизацию по телефону
  bool usePhoneLogin;

  ///Разрешить авторизацию по email
  bool useEmailLogin;

  ///Разрешить сохранять токен на устройстве для автоматической авторизации при следующем входе
  double cardSize;
  double iconSize;
  double buttonSize;
  String textEnter;
  String textBackToEnterPage;
  String headerMessage;

  /// Текст "Подтвердить"
  String textConfirm;
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
  String textRememberUser;
  String textRegistration;
  String textReturnToLogin;
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
  List<SocialAuthType> socialLoginTypes;

  ///callback функция, вызываемая при закрытии окна авторизации
  ///Вызывается в трех случаях:
  ///логин успешен
  ///пользователь отказался от логина
  ///произошла какая-то ошибка
  ///isLoginSuccessfull - результат отработки логина. Пользователь авторизован или нет
  final void Function(bool isLoginSuccessfull)? eventLoginWidgweClosed;

  final PasswordStrength? Function(String password)? passwordIndicator;
  final String? Function(String? password)? passwordValidator;

  bool? appbar;
  bool? headerMessageVisible;

  NsgLoginParams({
    this.loginType,
    this.email = '',
    this.textEnter = 'Войти',
    this.textBackToEnterPage = 'Вернуться на страницу входа',
    this.phoneNumber = '',
    this.usePasswordLogin = false,
    this.usePhoneLogin = true,
    this.useEmailLogin = false,
    this.cardSize = 345.0,
    this.iconSize = 28.0,
    this.buttonSize = 42.0,
    this.textRememberUser = 'Запомнить пользователя',
    this.headerMessage = 'NSG Application',
    this.textConfirm = 'Подтвердить', // 'Confirm',
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
    this.textEnterNewPassword = 'Введите новый пароль', //'Enter new password',
    this.textEnterPasswordAgain =
        'Введите второй раз ваш пароль', // 'Confirm password',
    this.textResendSms = 'Отправить СМС заново', //'Send SMS again',
    this.descriptionStyle,
    this.textSendSms = 'Отправить СМС', // 'Send SMS',
    this.textEnterCaptcha = 'Введите текст Капчи', // 'Enter captcha text',
    this.textLoginSuccessful = 'Успешный логин', //'Login successful',
    this.textEnterCorrectPhone =
        'Введите корректный номер', // 'Enter correct phone',
    this.textCheckInternet =
        'Невозможно выполнить запрос. Проверьте соединение с интернетом.', //'Cannot compleate request. Check internet connection and repeat.',
    this.textRegistration =
        'Регистрация / Забыл пароль', // 'Enter correct phone',
    this.textReturnToLogin = 'Уже зарегистрирован / Войти по паролю',
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
    this.mainPage = '',
    this.eventLoginWidgweClosed,
    this.passwordIndicator,
    this.passwordValidator,
    this.socialLoginTypes = const [],
  }) {
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
        message = tran.you_have_to_enter_captcha_text;
        break;
      case 40102:
        message = tran.captcha_is_obsolet_try_again;
        break;
      case 40103:
        message = tran.captcha_text_is_wrong_try_again;
        break;
      case 40104:
        message = tran.you_have_to_enter_you_phone_number;
        break;
      case 40105:
        message = tran.you_have_to_enter_captcha_text;
        break;
      case 40300:
        message = tran.wrong_security_code_try_again;
        break;
      case 40301:
        message = tran.you_entered_wrong_code_too_many_times;
        break;
      case 40302:
        message = tran.security_code_is_obsolete;
        break;
      case 40303:
        message = tran.you_need_to_create_verification_code_again;
        break;
      case 40304:
        message = tran.wrong_user_name_or_password;
        break;
      default:
        message = statusCode == 0
            ? ''
            : tran.error_statuscode_is_occured(statusCode);
    }
    return message;
  }

  void showError(BuildContext? context, String message, {int delayed = 5}) {
    if (message == '') return;
    nsgSnackbar(
      type: NsgSnarkBarType.error,
      text: message,
      duration: Duration(seconds: delayed),
    );
  }
}

class NsgLoginParamsDefault {
  static NsgLoginParams get defaultParams => NsgLoginParams(
    loginType: null,
    email: '',
    textEnter: tran.login,
    textBackToEnterPage: tran.return_to_login_page,
    phoneNumber: '',
    usePasswordLogin: false,
    usePhoneLogin: true,
    useEmailLogin: false,
    cardSize: 345.0,
    iconSize: 28.0,
    buttonSize: 42.0,
    textRememberUser: tran.remember_user,
    headerMessage: 'NSG Application',
    textConfirm: tran.confirm,
    headerMessageLogin: tran.enter,
    headerMessageRegistration: tran.registration,
    headerMessageVerification: tran.enter_code,
    descriptionMessegeVerificationPhone:
        'Мы отправили вам код в СМС\nна номер телефона: \n{{phone}}', // 'We sent code in SMS\nto phone number\n{{phone}}',
    descriptionMessegeVerificationEmail:
        'Мы отправили вам код в сообщении\nна e-mail: \n{{phone}}', // 'We sent code in SMS\nto phone number\n{{phone}}',
    textEnterCode: tran.code,
    textEnterPhone: tran.enter_your_phone_number,
    textEnterEmail: tran.enter_your_email,
    textEnterPassword: tran.enter_your_password,
    textEnterNewPassword: tran.enter_new_password,
    textEnterPasswordAgain: tran.confirm_password, // 'Confirm password',
    textResendSms: tran.send_sms_again,
    textSendSms: tran.send_sms,
    textEnterCaptcha: tran.enter_captcha_text,
    textLoginSuccessful: tran.successful_login,
    textEnterCorrectPhone: tran.please_enter_a_valid_number,
    textCheckInternet:
        tran.the_request_could_not_be_completed_check_your_internet_connection,
    textRegistration: tran.registration_forgot_password,
    textReturnToLogin: tran.already_registered_login_with_password,
    textColor: Colors.black,
    fillColor: Colors.black,
    disableButtonColor: Colors.blueGrey,
    headerMessageVisible: false,
    useCaptcha: true,
    mainPage: '',
    socialLoginTypes: const [],
  );
}
