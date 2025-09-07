// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hovering/hovering.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';
import 'package:nsg_login/pages/nsg_login_state.dart';
import 'package:nsg_controls/nsg_login_params.dart';
import 'package:nsg_controls/dialog/show_nsg_dialog.dart';
import 'package:nsg_login/pages/nsg_social_login_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class NsgLoginPage extends StatelessWidget {
  final NsgDataProvider provider;
  final NsgLoginParams Function() widgetParams;
  final String? initialEmail;

  //final NsgLoginType loginType;
  NsgLoginPage(
    this.provider, {
    super.key,
    required this.widgetParams,
    this.initialEmail,
    //this.loginType = NsgLoginType.phone
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widgetParams().appbar ?? false) ? getAppBar(context) : null,
      //backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(color: nsgtheme.colorMain.withAlpha(25)),
        child: LoginWidget(
          this,
          provider,
          widgetParams: widgetParams(),
          initialEmail: initialEmail,
        ),
      ),
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
  final NsgLoginParams widgetParams;
  final NsgDataProvider provider;
  final String? initialEmail;
  const LoginWidget(
    this.loginPage,
    this.provider, {
    super.key,
    required this.widgetParams,
    this.initialEmail,
  });
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
    email = widget.initialEmail ?? '';
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
      fillColor: widget.widgetParams.phoneFieldColor,
      errorStyle: const TextStyle(fontSize: 12),
      hintStyle: TextStyle(color: nsgtheme.colorText.withAlpha(75)),
    );
    widget.loginPage.callback.sendDataPressed = () => doSmsRequest(
      Get.context!,
      loginType: loginType,
      password: password,
      firebaseToken: firebaseToken,
    );
    if (widget.widgetParams.useEmailLogin) {
      loginType = NsgLoginType.email;
    } else {
      loginType = NsgLoginType.phone;
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
        Positioned.fill(child: widget.loginPage.getBackground()),
        Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(child: widget.loginPage.getLogo()),
                Container(child: _getContext(context)),
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
        if (mounted) {
          NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
          // ignore: use_build_context_synchronously
          return getContextSuccessful(context);
        }
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
                color: nsgtheme.colorMainBack,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              padding: const EdgeInsets.all(15.0),
              width: widget.widgetParams.cardSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        widget.widgetParams.headerMessageVisible == true
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  widget.widgetParams.headerMessage,
                                  style: TextStyle(color: nsgtheme.colorText),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox(),
                        //Кнопки LOGIN, REGISTRATION
                        //Для этапа ввода нового пароля отключаем их
                        if (widget.widgetParams.usePasswordLogin &&
                            currentState != NsgLoginState.verification)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: NsgButton(
                                    borderRadius: 0,
                                    color: currentState == NsgLoginState.login
                                        ? nsgtheme.colorBase.b0
                                        : nsgtheme.colorTertiary,
                                    backColor:
                                        currentState == NsgLoginState.login
                                        ? nsgtheme.colorPrimary
                                        : nsgtheme.colorSecondary,
                                    onPressed: () {
                                      currentState = NsgLoginState.login;
                                      setState(() {});
                                    },
                                    text: widget.widgetParams.headerMessageLogin
                                        .toUpperCase(),
                                  ),
                                ),

                                Flexible(
                                  child: NsgButton(
                                    borderRadius: 0,
                                    color:
                                        currentState ==
                                            NsgLoginState.registration
                                        ? nsgtheme.colorBase.b0
                                        : nsgtheme.colorTertiary,
                                    backColor:
                                        currentState ==
                                            NsgLoginState.registration
                                        ? nsgtheme.colorPrimary
                                        : nsgtheme.colorSecondary,
                                    onPressed: () {
                                      currentState = NsgLoginState.registration;
                                      setState(() {});
                                    },
                                    text: widget
                                        .widgetParams
                                        .headerMessageRegistration
                                        .toUpperCase(),
                                  ),
                                ),

                                //    Text(
                                //   widget.widgetParams.headerMessageLogin,
                                //   style: widget.widgetParams.headerMessageStyle,
                                //   textAlign: TextAlign.center,
                                // ),
                              ],
                            ),
                          ),

                        if (currentState == NsgLoginState.login)
                          ..._loginStateWidget(),
                        if (currentState == NsgLoginState.registration)
                          ..._registrationStateWidget(),
                        if (currentState == NsgLoginState.verification)
                          ..._verificationStateWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.widgetParams.onClose != null)
              InkWell(
                onTap: () {
                  NsgNavigator.pop();
                  widget.widgetParams.onClose!;
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Icon(
                    NsgIcons.close,
                    color: nsgtheme.colorPrimary.b100.withAlpha(127),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? getcaptchaImage() {
    if (captureImage == null || isCaptchaLoading) {
      return Icon(
        Icons.hourglass_empty,
        color: widget.widgetParams.textColor,
        size: 40.0,
      );
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

  void checkRequestSMSanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    //0 - успешно, 40201 - смс отправлено ранее. И в том и другом случае, переходим на экран ввода кода подтверждения
    if ((answerCode.errorCode == 0 || answerCode.errorCode == 40201) &&
        (currentState == NsgLoginState.registration ||
            currentState == NsgLoginState.login)) {
      if (currentState == NsgLoginState.registration ||
          !widget.widgetParams.usePasswordLogin) {
        currentState = NsgLoginState.verification;
      } else {
        isLoginSuccessfull = true;
      }
      setState(() {});
      //Если мы перешли на экран с ошибкой смс уже отправлено, выводим ошибку на экран после перехода на страницу подтверждения
      if (answerCode.errorCode != 0) {
        var errorMessage = widget.widgetParams.errorMessageByStatusCode!(
          answerCode.errorCode,
        );
        widget.widgetParams.showError(context, errorMessage);
        // widget.widgetParams.showError(context, answerCode.errorMessage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && widget.widgetParams.usePasswordLogin) {
      NsgMetrica.reportLoginSuccess('Phone');
      NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
      return;
    }
    if (answerCode.errorCode == 0 && !widget.widgetParams.usePasswordLogin) {
      gotoNextPage(context);
      return;
    }
    var needRefreshCaptcha = false;
    var errorMessage = widget.widgetParams.errorMessageByStatusCode!(
      answerCode.errorCode,
    );
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
    widget.widgetParams.showError(context, errorMessage);

    if (needRefreshCaptcha) {
      refreshCaptcha();
    } else {}
  }

  ///Запросить код проверки в виде СМС или t-mail в зависимости от loginType
  void doSmsRequest(
    BuildContext context, {
    NsgLoginType loginType = NsgLoginType.email,
    String? password,
    required String firebaseToken,
  }) {
    if (!_formKey.currentState!.validate()) return;

    NsgMetrica.reportLoginStart(loginType.toString());

    /* -------------------------------------------------------------- Если введён пароль -------------------------------------------------------------- */
    if (password != null && password != '') {
      captchaCode = password;
    } else {
      captchaCode = '';
    }

    if (widget.widgetParams.usePasswordLogin) {
      //Регистрация нового пользователя/восстановление пароля по e-mail или вход по паролю
      //Определяется наличием или отсутствием captchaCode
      widget.provider
          .phoneLoginPassword(
            phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
            securityCode: captchaCode,
            loginType: loginType,
          )
          .then((value) {
            if (mounted) {
              // ignore: use_build_context_synchronously
              checkRequestSMSanswer(context, value);
            }
          })
          .catchError((e) {
            if (mounted) {
              widget.widgetParams.showError(
                context,
                widget.widgetParams.textCheckInternet,
              );
            }
          });
    } else {
      widget.provider
          .phoneLoginRequestSMS(
            phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
            securityCode: captchaCode,
            loginType: loginType,
            firebaseToken: firebaseToken,
          )
          .then((value) {
            if (mounted) {
              checkRequestSMSanswer(context, value);
            }
          })
          .catchError((e) {
            if (mounted) {
              widget.widgetParams.showError(
                context,
                widget.widgetParams.textCheckInternet,
              );
            }
          });
    }
  }

  void refreshCaptcha() {
    isCaptchaLoading = true;
    if (!widget.widgetParams.useCaptcha) return;
    _loadCaptureImage().then(
      (value) => setState(() {
        captureImage = value;
        _captchaController!.value = TextEditingValue.empty;
        isCaptchaLoading = false;
        if (updateTimer != null) {
          updateTimer!.cancel();
        }
        secondsLeft = 120;
        updateTimer = Timer.periodic(
          const Duration(seconds: 1),
          (Timer t) => captchaTimer(t),
        );
      }),
    );
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
    //   if (widget.widgetParams.loginSuccessful != null) {
    //     widget.widgetParams.loginSuccessful!(
    //         context, widget.widgetParams.parameter);
    //   }
    // } else {
    //   refreshCaptcha();
    // }
  }

  Widget getContextSuccessful(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15.0),
        color: widget.widgetParams.cardColor,
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
                      widget.widgetParams.textLoginSuccessful,
                      style: widget.widgetParams.headerMessageStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///Элементы управления для состояния login
  List<Widget> _loginStateWidget() {
    return [
      if (widget.widgetParams.useEmailLogin &&
          widget.widgetParams.usePhoneLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            children: [
              Expanded(
                child: NsgCheckBox(
                  margin: EdgeInsets.zero,
                  key: GlobalKey(),
                  radio: true,
                  label: widget.widgetParams.textEnterEmail,
                  onPressed: (bool currentValue) {
                    setState(() {
                      loginType = NsgLoginType.email;
                    });
                  },
                  value: loginType == NsgLoginType.email,
                ),
              ),
              Expanded(
                child: NsgCheckBox(
                  margin: EdgeInsets.zero,
                  key: GlobalKey(),
                  radio: true,
                  label: widget.widgetParams.textEnterPhone,
                  onPressed: (bool currentValue) {
                    setState(() {
                      loginType = NsgLoginType.phone;
                    });
                  },
                  value: loginType == NsgLoginType.phone,
                ),
              ),
            ],
          ),
        ),
      if (widget.widgetParams.usePhoneLogin)
        if (loginType == NsgLoginType.phone)
          TextFormField(
            key: GlobalKey(),
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneFormatter],
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
            decoration: decor.copyWith(
              hintText: widget.widgetParams.textEnterPhone,
            ),
            initialValue: phoneNumber,
            onChanged: (value) => phoneNumber = value,
            validator: (value) => isPhoneValid(value!)
                ? null
                : widget.widgetParams.textEnterCorrectPhone,
          ),
      if (widget.widgetParams.useEmailLogin)
        if (loginType == NsgLoginType.email)
          TextFormField(
            key: GlobalKey(),
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: null,
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
            decoration: decor.copyWith(
              hintText: widget.widgetParams.textEnterEmail,
            ),
            initialValue: email,
            onChanged: (value) => email = value,
            validator: (value) => null,
          ),
      if (widget.widgetParams.usePasswordLogin)
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
              hintText: widget.widgetParams.textEnterPassword,
            ),
            onChanged: (value) {
              password = value;
            },
            validator: (value) => value == null || value.length < 1
                ? 'Password is required'
                : null,
          ),
        ),
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS))
        widget.loginPage.getRememberMeCheckbox()
      else
        const SizedBox(height: 10),
      if (widget.widgetParams.useCaptcha)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 160, child: getcaptchaImage()),
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
                        color: widget.widgetParams.phoneIconColor,
                        size: widget.widgetParams.buttonSize,
                      ),
                      onPressed: () {
                        refreshCaptcha();
                      },
                      //padding: EdgeInsets.all(0.0),
                    ),
                  ),
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
      if (widget.widgetParams.useCaptcha)
        Container(
          decoration: const BoxDecoration(
            //color: widget.widgetParams.phoneFieldColor,
            //borderRadius: BorderRadius.circular(5.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 0.0,
              vertical: 10.0,
            ),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              controller: _captchaController,
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams.textEnterCaptcha,
              ),
              style: widget.widgetParams.textPhoneField,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => captchaCode = value,
              validator: (value) => captchaCode.length == 6
                  ? null
                  : widget.widgetParams.textEnterCaptcha,
            ),
          ),
        ),
      NsgButton(
        margin: const EdgeInsets.only(top: 10),
        onPressed: () {
          widget.widgetParams.phoneNumber = phoneNumber;
          widget.widgetParams.loginType = loginType;
          doSmsRequest(
            Get.context!,
            loginType: loginType,
            password: password,
            firebaseToken: firebaseToken,
          );
        },
        text: widget.widgetParams.headerMessageLogin.toUpperCase(),
      ),
      if (widget.widgetParams.usePasswordLogin)
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
                  widget.widgetParams.textRegistration,
                  style: const TextStyle(),
                ),
                onHover: (PointerEnterEvent event) {},
                child: Text(
                  widget.widgetParams.textRegistration,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ),
      if (widget.widgetParams.useSocialLogin) _socialLogin(),
    ];
  }

  List<Widget> _registrationStateWidget() {
    return [
      if (widget.widgetParams.usePhoneLogin &&
          widget.widgetParams.useEmailLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            children: [
              Expanded(
                child: NsgCheckBox(
                  margin: EdgeInsets.zero,
                  key: GlobalKey(),
                  radio: true,
                  label: widget.widgetParams.textEnterEmail,
                  onPressed: (bool currentValue) {
                    setState(() {
                      loginType = NsgLoginType.email;
                    });
                  },
                  value: loginType == NsgLoginType.email,
                ),
              ),
              Expanded(
                child: NsgCheckBox(
                  margin: EdgeInsets.zero,
                  key: GlobalKey(),
                  radio: true,
                  label: widget.widgetParams.textEnterPhone,
                  onPressed: (bool currentValue) {
                    setState(() {
                      loginType = NsgLoginType.phone;
                    });
                  },
                  value: loginType == NsgLoginType.phone,
                ),
              ),
            ],
          ),
        ),
      if (widget.widgetParams.usePhoneLogin)
        if (loginType == NsgLoginType.phone)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatter],
              // style: widget.widgetParams.textPhoneField,
              style: TextStyle(color: nsgtheme.colorText),
              textAlign: TextAlign.center,
              decoration: decor.copyWith(
                hintText: widget.widgetParams.textEnterPhone,
              ),

              initialValue: phoneNumber,
              onChanged: (value) => phoneNumber = value,
              validator: (value) => isPhoneValid(value!) && value.length >= 9
                  ? null
                  : widget.widgetParams.textEnterCorrectPhone,
            ),
          ),
      if (widget.widgetParams.useEmailLogin)
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
                hintText: widget.widgetParams.textEnterEmail,
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
          doSmsRequest(
            context,
            firebaseToken: firebaseToken,
            loginType: loginType,
          );
        },
        text: widget.widgetParams.textSendSms.toUpperCase(),
      ),
      const SizedBox(height: 15),
      if (widget.widgetParams.useSocialLogin) _socialLogin(),
    ];
  }

  ///Виджет ввода кода верификации
  ///при использовании варианта авторизации по паролю, установка нового пароля пользователя
  List<Widget> _verificationStateWidget() {
    ValueNotifier<PasswordStrength?>? passwordListener;
    if (widget.widgetParams.passwordIndicator != null)
      passwordListener = ValueNotifier(null);
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          widget.widgetParams.headerMessageVerification,
          style: widget.widgetParams.headerMessageStyle,
          textAlign: TextAlign.center,
        ),
      ),
      _getInput(
        hintText: widget.widgetParams.textEnterCode,
        initialValue: securityCode,
        autofillHints: [AutofillHints.oneTimeCode],
        keyboardType: TextInputType.number,
        onChanged: (value) => securityCode = value,
        validator: (value) => value == null || value.length < 6
            ? 'Enter confirmation code from message'
            : null,
      ),
      if (widget.widgetParams.usePasswordLogin)
        _getInput(
          hintText: widget.widgetParams.textEnterNewPassword,
          initialValue: newPassword1,
          obscureText: true,
          onChanged: (value) {
            if (widget.widgetParams.passwordIndicator != null) {
              passwordListener!.value = widget.widgetParams.passwordIndicator!(
                value,
              );
            }
            newPassword1 = value;
          },
          validator: widget.widgetParams.passwordValidator,
        ),
      if (widget.widgetParams.usePasswordLogin)
        _getInput(
          hintText: widget.widgetParams.textEnterPasswordAgain,
          initialValue: newPassword2,
          obscureText: true,
          onChanged: (value) => newPassword2 = value,
          validator: (value) =>
              value == newPassword1 ? null : 'Passwords mistmatch',
        ),
      if (widget.widgetParams.usePasswordLogin &&
          widget.widgetParams.passwordIndicator != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: _getIndicator(
            listener: passwordListener!,
            colors: passwordStrengthColors,
            values: PasswordStrength.values,
            messages: passwordStrengthMessages,
            defaultColor: Colors.blueGrey,
            defaultMessage: 'Password is empty',
          ),
        ),

      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(
          onTap: () {
            currentState = NsgLoginState.login;
            // captchaCode = '';
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: HoverWidget(
              hoverChild: Text(
                'Try another login method',
                style: const TextStyle(),
              ),
              onHover: (PointerEnterEvent event) {},
              child: Text(
                'Try another login method',
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ),

      /// CONFIRM кнопка
      NsgButton(
        margin: EdgeInsets.zero,
        onPressed: () {
          setNewPassword(
            context,
            securityCode: securityCode,
            loginType: loginType,
            newPassword: newPassword1,
          );
        },
        text: widget.widgetParams.textConfirm.toUpperCase(),
      ),
    ];
  }

  Widget _getInput({
    String hintText = '',
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    Iterable<String> autofillHints = const [],
    bool obscureText = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
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
        decoration: decor.copyWith(hintText: hintText),
        initialValue: initialValue,
        onChanged: onChanged,
        validator: (value) {
          if (value != newPassword2) return null;
          if (validator != null) return validator(value);
          return null;
        },
        obscureText: obscureText,
      ),
    );
  }

  Widget _getIndicator<T>({
    required ValueNotifier listener,
    required Iterable<T> values,
    required Iterable<Color> colors,
    required Iterable<String> messages,
    String? defaultMessage,
    Color? defaultColor,
  }) {
    return ListenableBuilder(
      listenable: listener,
      builder: (BuildContext context, Widget? child) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: (() {
                  for (int i = 0; i < values.length; i++) {
                    if (values.elementAt(i) == listener.value)
                      return colors.elementAt(i);
                  }
                  return defaultColor ?? Colors.transparent;
                })(),
              ),
              child: SizedBox(width: double.infinity, height: 5, child: child),
            ),
            const SizedBox(height: 5),
            Text(
              (() {
                for (int i = 0; i < values.length; i++) {
                  if (values.elementAt(i) == listener.value)
                    return messages.elementAt(i);
                }
                return defaultMessage ?? '';
              })(),
            ),
          ],
        );
      },
    );
  }

  Widget _socialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: InkWell(
            onTap: () async {
              // Сохранять токен обязательно
              // if (!widget.provider.saveToken) {
              //   widget.widgetParams.showError(context, 'Опция "Запомнить пользователя" при авторизации через соцсети обязательная!');
              //   return;
              // }
              var response = await widget.provider.requestVK();
              if (context.mounted) {
                if (response.errorMessage.startsWith('https://')) {
                  var url = response.errorMessage;
                  if (!kIsWeb) {
                    await showNsgDialog(
                      context: context,
                      title: '',
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: NsgSocialLoginWidget(
                          authUrl: url,
                          onVerify: (response) async {
                            await widget.provider.verifyVK(response);
                            // widget.provider.connect(controller);
                            NsgNavigator.instance.offAndToPage(
                              widget.widgetParams.mainPage,
                            );
                          },
                        ),
                      ),
                      buttons: [],
                      showCloseButton: true,
                    );
                  } else {
                    await launchUrl(Uri.parse(url));
                  }
                } else {
                  widget.widgetParams.showError(context, response.errorMessage);
                }
              }
            },
            child: SvgPicture.string(
              '''<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0 48C0 25.3726 0 14.0589 7.02944 7.02944C14.0589 0 25.3726 0 48 0H52C74.6274 0 85.9411 0 92.9706 7.02944C100 14.0589 100 25.3726 100 48V52C100 74.6274 100 85.9411 92.9706 92.9706C85.9411 100 74.6274 100 52 100H48C25.3726 100 14.0589 100 7.02944 92.9706C0 85.9411 0 74.6274 0 52V48Z" fill="#0077FF"/>
                <path d="M53.2083 72.042C30.4167 72.042 17.4168 56.417 16.8751 30.417H28.2917C28.6667 49.5003 37.0833 57.5836 43.7499 59.2503V30.417H54.5002V46.8752C61.0836 46.1669 67.9994 38.667 70.3328 30.417H81.0831C79.2914 40.5837 71.7914 48.0836 66.458 51.1669C71.7914 53.6669 80.3335 60.2086 83.5835 72.042H71.7498C69.2081 64.1253 62.8752 58.0003 54.5002 57.1669V72.042H53.2083Z" fill="white"/>
                </svg>''',
              semanticsLabel: 'VK logo',
              width: 35,
              height: 35,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: InkWell(
            onTap: () async {
              // Сохранять токен обязательно
              // if (!widget.provider.saveToken) {
              //   widget.widgetParams.showError(context, 'Опция "Запомнить пользователя" при авторизации через соцсети обязательная!');
              //   return;
              // }
              var response = await widget.provider.requestGoogle();
              assert(context.mounted);
              if (response.errorMessage.startsWith('https://')) {
                var url = response.errorMessage;
                if (!kIsWeb) {
                  await showNsgDialog(
                    context: context,
                    title: '',
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: NsgSocialLoginWidget(
                        authUrl: url,
                        onVerify: (response) async {
                          await widget.provider.verifyGoogle(response);
                          // widget.provider.connect(controller);
                          NsgNavigator.instance.offAndToPage(
                            widget.widgetParams.mainPage,
                          );
                        },
                      ),
                    ),
                    buttons: [],
                    showCloseButton: true,
                  );
                } else {
                  await launchUrl(Uri.parse(url));
                }
              } else {
                widget.widgetParams.showError(context, response.errorMessage);
              }
            },
            child: SvgPicture.string(
              '''<svg width="294" height="300" viewBox="0 0 294 300" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M150 122.729V180.82H230.727C227.183 199.502 216.545 215.321 200.59 225.957L249.272 263.731C277.636 237.55 294 199.094 294 153.412C294 142.776 293.046 132.548 291.273 122.73L150 122.729Z" fill="#4285F4"/>
                <path d="M65.9342 178.553L54.9546 186.958L16.0898 217.23C40.7719 266.185 91.3596 300.004 149.996 300.004C190.496 300.004 224.45 286.64 249.269 263.731L200.587 225.958C187.223 234.958 170.177 240.413 149.996 240.413C110.996 240.413 77.8602 214.095 65.9955 178.639L65.9342 178.553Z" fill="#34A853"/>
                <path d="M16.0899 82.7734C5.86309 102.955 0 125.728 0 150.001C0 174.273 5.86309 197.047 16.0899 217.228C16.0899 217.363 66.0004 178.5 66.0004 178.5C63.0004 169.5 61.2272 159.955 61.2272 149.999C61.2272 140.043 63.0004 130.498 66.0004 121.498L16.0899 82.7734Z" fill="#FBBC05"/>
                <path d="M149.999 59.7279C172.091 59.7279 191.727 67.3642 207.409 82.0918L250.364 39.1373C224.318 14.8647 190.5 0 149.999 0C91.3627 0 40.7719 33.6821 16.0898 82.7738L65.9988 121.502C77.8619 86.0462 110.999 59.7279 149.999 59.7279Z" fill="#EA4335"/>
                </svg>''',
              semanticsLabel: 'Google logo',
              width: 35,
              height: 35,
            ),
          ),
        ),
      ],
    );
  }

  ///Установить новый пароль пользователя
  ///securityCode - код верификации, полученный на предыдущем этапе
  ///loginType - тип логина (телефон/емаил)
  ///newPassword - новый (устанавливаемый) пароль
  Future setNewPassword(
    BuildContext context, {
    required String securityCode,
    required NsgLoginType loginType,
    required String newPassword,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    widget.provider
        .phoneLogin(
          phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
          securityCode: securityCode,
          register: true,
          newPassword: newPassword,
        )
        .then((value) => checkRequestNewPasswordanswer(context, value))
        .catchError((e) {
          widget.widgetParams.showError(
            context,
            widget.widgetParams.textCheckInternet,
          );
        });
  }

  ///Проверка результата попытки установить новый пароль пользователя фукцией setNewPassword
  ///answerCode - проверяемый код ответа
  void checkRequestNewPasswordanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }
    //Код ноль - пароль установлен успешно, переходим на страницу приложения
    if (answerCode.errorCode == 0) {
      NsgMetrica.reportLoginSuccess('Phone');
      if (widget.widgetParams.eventLoginWidgweClosed != null) {
        widget.widgetParams.eventLoginWidgweClosed!(true);
      }
      NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
      return;
    }
    //Если код ответа отличен от нуля - это ошибка, расшифровываем её и показываем пользователю
    //TODO: проверить остались ли еще попытки ввода кода подтверждения или требуется новый.
    var errorMessage = widget.widgetParams.errorMessageByStatusCode!(
      answerCode.errorCode,
    );
    NsgMetrica.reportLoginFailed('Phone', answerCode.toString());
    widget.widgetParams.showError(context, errorMessage);
  }
}
