// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:hovering/hovering.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_params.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_login/pages/nsg_login_state.dart';

class NsgLoginPage extends StatelessWidget {
  final NsgDataProvider provider;
  final NsgLoginParams Function() widgetParams;
  //final NsgLoginType loginType;
  NsgLoginPage(
    this.provider, {
    super.key,
    required this.widgetParams,
    //this.loginType = NsgLoginType.phone
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widgetParams().appbar ?? false) ? getAppBar(context) : null,
      //backgroundColor: Colors.white,
      body: Container(
          decoration: BoxDecoration(color: nsgtheme.colorMain.withOpacity(0.1)),
          child: LoginWidget(this, provider, widgetParams: widgetParams())),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(title: const Text(''), centerTitle: true);
  }

  Widget getLogo() {
    var logo = const Image(
      image: AssetImage('assets/images/logo.png', package: 'nsg_login'),
      width: 140.0,
      height: 140.0,
      alignment: Alignment.center,
    );
    return logo;
  }

  Widget getRememberMeCheckbox() {
    bool initialValue = provider.saveToken;
    var checkbox = NsgCheckBox(
      checkColor: nsgtheme.colorText,
      toggleInside: true,
      simple: true,
      margin: EdgeInsets.zero,
      label: widgetParams().textRememberUser,
      onPressed: (currentValue) {
        provider.saveToken = currentValue;
      },
      value: initialValue,
    );
    return checkbox;
  }

  Widget getBackground() {
    Widget background = const SizedBox();
    return background;
  }

  final callback = CallbackFunctionClass();
  void sendData() {
    callback.sendData();
  }
}

class CallbackFunctionClass {
  void Function()? sendDataPressed;

  void sendData() {
    if (sendDataPressed != null) {
      sendDataPressed!();
    }
  }
}

class LoginWidget extends StatefulWidget {
  @override
  LoginWidgetState createState() => LoginWidgetState();

  final NsgLoginPage loginPage;
  final NsgLoginParams? widgetParams;
  final NsgDataProvider provider;
  const LoginWidget(this.loginPage, this.provider, {super.key, this.widgetParams});
}

class LoginWidgetState extends State<LoginWidget> {
  InputDecoration decor = const InputDecoration();
  Image? captureImage;
  String phoneNumber = '';
  String email = '';
  String captchaCode = '';
  String securityCode = '';
  bool isCaptchaLoading = false;
  int currentStage = LoginWidgetState.stagePreLogin;
  bool isLoginSuccessfull = false;
  String password = '';
  String newPassword1 = '';
  String newPassword2 = '';
  PhoneInputFormatter phoneFormatter = PhoneInputFormatter();
  late NsgLoginType loginType;
  //Осталось секунд до автообновления капчи. Если -1, то капча еще не получена
  //и таймер запускать нет смысла
  int secondsLeft = -1;
  //таймер, запускаемый по факту получения капчи. С автообновлением капчи через 2 минуты
  Timer? updateTimer;
  NsgLoginState currentState = NsgLoginState.login;

  //TODO: заполнять токен!!!
  String firebaseToken = '';

  ///Get captcha and send request for SMS
  ///This is first stage of authorization
  static int stagePreLogin = 1;

  @override
  void initState() {
    super.initState();
    decor = InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
          borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
          borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
          borderSide: BorderSide(color: nsgtheme.colorText, width: 1.0),
        ),
        filled: true,
        fillColor: widget.widgetParams!.phoneFieldColor,
        errorStyle: const TextStyle(fontSize: 12),
        hintStyle: TextStyle(color: nsgtheme.colorText.withOpacity(0.3)));
    widget.loginPage.callback.sendDataPressed =
        () => doSmsRequest(Get.context!, loginType: loginType, password: password, firebaseToken: firebaseToken);
    if (widget.widgetParams!.usePhoneLogin) {
      loginType = NsgLoginType.phone;
    } else {
      loginType = NsgLoginType.email;
    }
    refreshCaptcha();
  }

  @override
  void dispose() {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _getBody(context);
  }

  Widget _getBody(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: widget.loginPage.getBackground(),
        ),
        Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: widget.loginPage.getLogo(),
                ),
                Container(
                  child: _getContext(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController? _captchaController;
  Widget _getContext(BuildContext context) {
    if (isLoginSuccessfull) {
      Future.delayed(const Duration(milliseconds: 10)).then((e) {
        if (widget.widgetParams != null) {
          NsgNavigator.instance.offAndToPage(widget.widgetParams!.mainPage);
        } else {
          NsgNavigator.pop();
        }

        return getContextSuccessful(context);
      });
    }
    _captchaController ??= TextEditingController();
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: nsgtheme.colorMainBack, borderRadius: const BorderRadius.all(Radius.circular(10))),
              padding: const EdgeInsets.all(15.0),
              width: widget.widgetParams!.cardSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        widget.widgetParams!.headerMessageVisible == true
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  widget.widgetParams!.headerMessage,
                                  style: TextStyle(color: nsgtheme.colorText),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox(),
                        //Кнопки LOGIN, REGISTRATION
                        //Для этапа ввода нового пароля отключаем их
                        if (widget.widgetParams!.usePasswordLogin && currentState != NsgLoginState.verification)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: NsgButton(
                                  borderRadius: 0,
                                  color: currentState == NsgLoginState.login
                                      ? nsgtheme.colorBase.b0
                                      : nsgtheme.colorTertiary,
                                  backColor: currentState == NsgLoginState.login
                                      ? nsgtheme.colorPrimary
                                      : nsgtheme.colorSecondary,
                                  onPressed: () {
                                    currentState = NsgLoginState.login;
                                    setState(() {});
                                  },
                                  text: widget.widgetParams!.headerMessageLogin.toUpperCase(),
                                ),
                              ),

                              Flexible(
                                child: NsgButton(
                                  borderRadius: 0,
                                  color: currentState == NsgLoginState.registration
                                      ? nsgtheme.colorBase.b0
                                      : nsgtheme.colorTertiary,
                                  backColor: currentState == NsgLoginState.registration
                                      ? nsgtheme.colorPrimary
                                      : nsgtheme.colorSecondary,
                                  onPressed: () {
                                    currentState = NsgLoginState.registration;
                                    setState(() {});
                                  },
                                  text: widget.widgetParams!.headerMessageRegistration.toUpperCase(),
                                ),
                              ),

                              //    Text(
                              //   widget.widgetParams!.headerMessageLogin,
                              //   style: widget.widgetParams!.headerMessageStyle,
                              //   textAlign: TextAlign.center,
                              // ),
                            ]),
                          ),

                        if (currentState == NsgLoginState.login) ..._loginStateWidget(),
                        if (currentState == NsgLoginState.registration) ..._registrationStateWidget(),
                        if (currentState == NsgLoginState.verification) ..._verificationStateWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.widgetParams!.onClose != null)
              InkWell(
                onTap: () {
                  NsgNavigator.pop();
                  widget.widgetParams!.onClose!;
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Icon(
                    NsgIcons.close,
                    color: nsgtheme.colorPrimary.b100.withOpacity(0.5),
                    size: 18,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget? getcaptchaImage() {
    if (captureImage == null || isCaptchaLoading) {
      return Icon(Icons.hourglass_empty, color: widget.widgetParams!.textColor, size: 40.0);
    }
    return captureImage;
  }

  ///Get captcha from server
  Future<Image> _loadCaptureImage() async {
    Image image;
    try {
      image = await widget.provider.getCaptcha();
    } catch (e) {
      image = Image.asset('lib/assets/no_image.jpg');
    }
    return image;
  }

  void checkRequestSMSanswer(BuildContext? context, NsgLoginResponse answerCode) {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    //0 - успешно, 40201 - смс отправлено ранее. И в том и другом случае, переходим на экран ввода кода подтверждения
    if ((answerCode.errorCode == 0 || answerCode.errorCode == 40201) &&
        (currentState == NsgLoginState.registration || currentState == NsgLoginState.login)) {
      if (currentState == NsgLoginState.registration || !widget.widgetParams!.usePasswordLogin) {
        currentState = NsgLoginState.verification;
      } else {
        isLoginSuccessfull = true;
      }
      setState(() {});
      //Если мы перешли на экран с ошибкой смс уже отправлено, выводим ошибку на экран после перехода на страницу подтверждения
      if (answerCode.errorCode != 0) {
        var errorMessage = widget.widgetParams!.errorMessageByStatusCode!(answerCode.errorCode);
        widget.widgetParams!.showError(context, errorMessage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && widget.widgetParams!.usePasswordLogin) {
      NsgMetrica.reportLoginSuccess('Phone');
      NsgNavigator.instance.offAndToPage(widget.widgetParams!.mainPage);
      return;
    }
    if (answerCode.errorCode == 0 && !widget.widgetParams!.usePasswordLogin) {
      gotoNextPage(context);
      return;
    }
    var needRefreshCaptcha = false;
    var errorMessage = widget.widgetParams!.errorMessageByStatusCode!(answerCode.errorCode);
    switch (answerCode.errorCode) {
      case 40102:
        needRefreshCaptcha = true;
        break;
      case 40103:
        needRefreshCaptcha = true;
        break;
      default:
        needRefreshCaptcha = false;
    }
    NsgMetrica.reportLoginFailed('Phone', answerCode.toString());
    widget.widgetParams!.showError(context, errorMessage);

    if (needRefreshCaptcha) {
      refreshCaptcha();
    } else {}
  }

  ///Запросить код проверки в виде СМС или t-mail в зависимости от loginType
  void doSmsRequest(BuildContext context,
      {NsgLoginType loginType = NsgLoginType.phone, String? password, required String firebaseToken}) {
    if (!_formKey.currentState!.validate()) return;

    NsgMetrica.reportLoginStart(loginType.toString());

/* -------------------------------------------------------------- Если введён пароль -------------------------------------------------------------- */
    if (password != null && password != '') {
      captchaCode = password;
    } else {
      captchaCode = '';
    }

    if (widget.widgetParams!.usePasswordLogin) {
      //Регистрация нового пользователя/восстановление пароля по e-mail или вход по паролю
      //Опраделяется наличием или отсутствием captchaCode
      widget.provider
          .phoneLoginPassword(
              phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
              securityCode: captchaCode,
              loginType: loginType)
          .then((value) => checkRequestSMSanswer(context, value))
          .catchError((e) {
        widget.widgetParams!.showError(context, widget.widgetParams!.textCheckInternet);
      });
    } else {
      widget.provider
          .phoneLoginRequestSMS(
              phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
              securityCode: captchaCode,
              loginType: loginType,
              firebaseToken: firebaseToken)
          .then((value) => checkRequestSMSanswer(context, value))
          .catchError((e) {
        widget.widgetParams!.showError(context, widget.widgetParams!.textCheckInternet);
      });
    }
  }

  void refreshCaptcha() {
    isCaptchaLoading = true;
    if (!widget.widgetParams!.useCaptcha) return;
    _loadCaptureImage().then((value) => setState(() {
          captureImage = value;
          _captchaController!.value = TextEditingValue.empty;
          isCaptchaLoading = false;
          if (updateTimer != null) {
            updateTimer!.cancel();
          }
          secondsLeft = 120;
          updateTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => captchaTimer(t));
        }));
  }

  void captchaTimer(Timer timer) {
    if (secondsLeft > 0) {
      setState(() {
        secondsLeft--;
      });
    } else {
      updateTimer!.cancel();
      updateTimer = null;
      refreshCaptcha();
    }
  }

  void gotoNextPage(BuildContext? context) async {
    //TODO: navigation
    // var result = await Navigator.push<bool>(context!,
    //     MaterialPageRoute(builder: (context) => _getVerificationWidget()));
    // //var result = await Get.to(_getVerificationWidget);
    // if (result ??= false) {
    //   setState(() {
    //     isLoginSuccessfull = true;
    //   });
    //   if (widget.widgetParams!.loginSuccessful != null) {
    //     widget.widgetParams!.loginSuccessful!(
    //         context, widget.widgetParams!.parameter);
    //   }
    // } else {
    //   refreshCaptcha();
    // }
  }

  Widget getContextSuccessful(BuildContext context) {
    return Center(
      child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 15.0),
          color: widget.widgetParams!.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                          Text(
                            widget.widgetParams!.textLoginSuccessful,
                            style: widget.widgetParams!.headerMessageStyle,
                          )
                        ]))
                  ]))),
    );
  }

  ///Элементы управления для состояния login
  List<Widget> _loginStateWidget() {
    return [
      if (widget.widgetParams!.useEmailLogin && widget.widgetParams!.usePhoneLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            children: [
              Expanded(
                  child: NsgCheckBox(
                margin: EdgeInsets.zero,
                key: GlobalKey(),
                radio: true,
                label: widget.widgetParams!.textEnterPhone,
                onPressed: (bool currentValue) {
                  setState(() {
                    loginType = NsgLoginType.phone;
                  });
                },
                value: loginType == NsgLoginType.phone,
              )),
              Expanded(
                  child: NsgCheckBox(
                      margin: EdgeInsets.zero,
                      key: GlobalKey(),
                      radio: true,
                      label: widget.widgetParams!.textEnterEmail,
                      onPressed: (bool currentValue) {
                        setState(() {
                          loginType = NsgLoginType.email;
                        });
                      },
                      value: loginType == NsgLoginType.email)),
            ],
          ),
        ),
      if (widget.widgetParams!.usePhoneLogin)
        if (loginType == NsgLoginType.phone)
          TextFormField(
            key: GlobalKey(),
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneFormatter],
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
            decoration: decor.copyWith(
              hintText: widget.widgetParams!.textEnterPhone,
            ),
            initialValue: phoneNumber,
            onChanged: (value) => phoneNumber = value,
            validator: (value) => isPhoneValid(value!) ? null : widget.widgetParams!.textEnterCorrectPhone,
          ),
      if (widget.widgetParams!.useEmailLogin)
        if (loginType == NsgLoginType.email)
          TextFormField(
            key: GlobalKey(),
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: null,
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
            decoration: decor.copyWith(
              hintText: widget.widgetParams!.textEnterEmail,
            ),
            initialValue: email,
            onChanged: (value) => email = value,
            validator: (value) => null,
          ),
      if (widget.widgetParams!.usePasswordLogin)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
              obscureText: true,
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.visiblePassword,
              inputFormatters: null,
              style: TextStyle(color: nsgtheme.colorText),
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams!.textEnterPassword,
              ),
              validator: (value) => value == null || value.length < 1 ? 'Password is required' : null),
        ),
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS))
        widget.loginPage.getRememberMeCheckbox()
      else
        const SizedBox(height: 10),
      if (widget.widgetParams!.useCaptcha)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: getcaptchaImage(),
            ),
            SizedBox(
              height: 50,
              width: 40,
              child: Stack(
                children: [
                  Align(
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        icon: Icon(
                          Icons.cached,
                          color: widget.widgetParams!.phoneIconColor,
                          size: widget.widgetParams!.buttonSize,
                        ),
                        onPressed: () {
                          refreshCaptcha();
                        },
                        //padding: EdgeInsets.all(0.0),
                      )),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      secondsLeft.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      if (widget.widgetParams!.useCaptcha)
        Container(
          decoration: const BoxDecoration(
              //color: widget.widgetParams!.phoneFieldColor,
              //borderRadius: BorderRadius.circular(5.0),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              controller: _captchaController,
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams!.textEnterCaptcha,
              ),
              style: widget.widgetParams!.textPhoneField,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => captchaCode = value,
              validator: (value) => captchaCode.length == 6 ? null : widget.widgetParams!.textEnterCaptcha,
            ),
          ),
        ),
      NsgButton(
        margin: const EdgeInsets.only(top: 10),
        onPressed: () {
          widget.widgetParams!.phoneNumber = phoneNumber;
          widget.widgetParams!.loginType = loginType;
          doSmsRequest(Get.context!, loginType: loginType, password: password, firebaseToken: firebaseToken);
        },
        text: widget.widgetParams!.headerMessageLogin.toUpperCase(),
      ),
      if (widget.widgetParams!.usePasswordLogin)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InkWell(
            onTap: () {
              currentState = NsgLoginState.registration;
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: HoverWidget(
                hoverChild: Text(
                  widget.widgetParams!.textRegistration,
                  style: const TextStyle(),
                ),
                onHover: (PointerEnterEvent event) {},
                child: Text(
                  widget.widgetParams!.textRegistration,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        )
    ];
  }

  List<Widget> _registrationStateWidget() {
    return [
      if (widget.widgetParams!.usePhoneLogin && widget.widgetParams!.useEmailLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            children: [
              Expanded(
                  child: NsgCheckBox(
                margin: EdgeInsets.zero,
                key: GlobalKey(),
                radio: true,
                label: widget.widgetParams!.textEnterPhone,
                onPressed: (bool currentValue) {
                  setState(() {
                    loginType = NsgLoginType.phone;
                  });
                },
                value: loginType == NsgLoginType.phone,
              )),
              Expanded(
                  child: NsgCheckBox(
                      margin: EdgeInsets.zero,
                      key: GlobalKey(),
                      radio: true,
                      label: widget.widgetParams!.textEnterEmail,
                      onPressed: (bool currentValue) {
                        setState(() {
                          loginType = NsgLoginType.email;
                        });
                      },
                      value: loginType == NsgLoginType.email)),
            ],
          ),
        ),
      if (widget.widgetParams!.usePhoneLogin)
        if (loginType == NsgLoginType.phone)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatter],
              // style: widget.widgetParams!.textPhoneField,
              style: TextStyle(color: nsgtheme.colorText),
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams!.textEnterPhone,
              ),

              initialValue: phoneNumber,
              onChanged: (value) => phoneNumber = value,
              validator: (value) =>
                  isPhoneValid(value!) && value.length >= 9 ? null : widget.widgetParams!.textEnterCorrectPhone,
            ),
          ),
      if (widget.widgetParams!.useEmailLogin)
        if (loginType == NsgLoginType.email)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: null,
              style: TextStyle(color: nsgtheme.colorText),
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams!.textEnterEmail,
              ),
              initialValue: email,
              onChanged: (value) => email = value,
              validator: (value) => null,
            ),
          ),
      const SizedBox(height: 15),

      /// GET CODE кнопка
      NsgButton(
          margin: EdgeInsets.zero,
          onPressed: () {
            doSmsRequest(context, firebaseToken: firebaseToken, loginType: loginType);
          },
          text: widget.provider.widgetParams().textSendSms.toUpperCase()),
    ];
  }

  ///Виджет ввода кода верификации
  ///при использовании варианта авторизации по паролю, установка нового пароля пользователя
  List<Widget> _verificationStateWidget() {
    return [
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            widget.widgetParams!.headerMessageVerification,
            style: widget.widgetParams!.headerMessageStyle,
            textAlign: TextAlign.center,
          )),
      _getInput(
          hintText: widget.widgetParams!.textEnterCode,
          initialValue: securityCode,
          autofillHints: [AutofillHints.oneTimeCode],
          keyboardType: TextInputType.number,
          onChanged: (value) => securityCode = value,
          validator: (value) => value == null || value.length < 6 ? 'Enter confirmation code from message' : null),
      if (widget.widgetParams!.usePasswordLogin)
        _getInput(
            hintText: widget.widgetParams!.textEnterNewPassword,
            initialValue: newPassword1,
            obscureText: true,
            onChanged: (value) => newPassword1 = value,
            validator: (value) => value == newPassword2 ? null : 'Passwords mistmatch'),
      if (widget.widgetParams!.usePasswordLogin)
        _getInput(
            hintText: widget.widgetParams!.textEnterPasswordAgain,
            initialValue: newPassword2,
            obscureText: true,
            onChanged: (value) => newPassword2 = value,
            validator: (value) => value == newPassword1 ? null : 'Passwords mistmatch'),
      const SizedBox(height: 15),

      /// CONFIRM кнопка
      NsgButton(
          margin: EdgeInsets.zero,
          onPressed: () {
            setNewPassword(context, securityCode: securityCode, loginType: loginType, newPassword: newPassword1);
          },
          text: widget.provider.widgetParams().textConfirm.toUpperCase()),
    ];
  }

  Widget _getInput(
      {String hintText = '',
      String? initialValue,
      TextInputType keyboardType = TextInputType.text,
      Iterable<String> autofillHints = const [],
      bool obscureText = false,
      Function(String)? onChanged,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: GlobalKey(),
        autofillHints: autofillHints,
        cursorColor: Theme.of(context).primaryColor,
        keyboardType: keyboardType,
        inputFormatters: null,
        style: TextStyle(color: nsgtheme.colorText),
        textAlign: TextAlign.center,
        decoration: decor.copyWith(
          hintText: hintText,
        ),
        initialValue: initialValue,
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
      ),
    );
  }

  ///Установить новый пароль пользователя
  ///securityCode - код верификации, полученный на предыдущем этапе
  ///loginType - тип логина (телефон/емаил)
  ///newPassword - новый (устанавливаемый) пароль
  Future setNewPassword(BuildContext context,
      {required String securityCode, required NsgLoginType loginType, required String newPassword}) async {
    if (!_formKey.currentState!.validate()) return;
    widget.provider
        .phoneLogin(
            phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
            securityCode: securityCode,
            register: true,
            newPassword: newPassword)
        .then((value) => checkRequestNewPasswordanswer(context, value))
        .catchError((e) {
      widget.widgetParams!.showError(context, widget.widgetParams!.textCheckInternet);
    });
  }

  ///Проверка результата попытки установить новый пароль пользователя фукцией setNewPassword
  ///answerCode - проверяемый код ответа
  void checkRequestNewPasswordanswer(BuildContext? context, NsgLoginResponse answerCode) {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }
    //Код ноль - пароль установлен успешно, переходим на страницу приложения
    if (answerCode.errorCode == 0) {
      NsgMetrica.reportLoginSuccess('Phone');
      if (widget.widgetParams!.eventLoginWidgweClosed != null) {
        widget.widgetParams!.eventLoginWidgweClosed!(true);
      }
      NsgNavigator.instance.offAndToPage(widget.widgetParams!.mainPage);
      return;
    }
    //Если код ответа отличен от нуля - это ошибка, расшифровываем её и показываем пользователю
    //TODO: проверить остались ли еще попытки ввода кода подтверждения или требуется новый.
    var errorMessage = widget.widgetParams!.errorMessageByStatusCode!(answerCode.errorCode);
    NsgMetrica.reportLoginFailed('Phone', answerCode.toString());
    widget.widgetParams!.showError(context, errorMessage);
  }
}
