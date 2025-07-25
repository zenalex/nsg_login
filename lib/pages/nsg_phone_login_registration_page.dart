import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';
import 'package:get/get.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_controls/widgets/nsg_snackbar.dart';
import 'package:hovering/hovering.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/nsg_data.dart';

import 'package:nsg_controls/nsg_login_params.dart';

class NsgLoginRegistrationPage extends StatelessWidget {
  final NsgDataProvider provider;
  final NsgLoginParams widgetParams;

  const NsgLoginRegistrationPage(
    this.provider, {
    super.key,
    required this.widgetParams,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widgetParams.appbar! ? getAppBar(context) : null,
      //backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(color: nsgtheme.colorMain.withAlpha(25)),
        child: NsgLoginRegistrationWidget(this, provider),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(title: const Text(''), centerTitle: true);
  }

  Widget getLogo() {
    var logo = const Image(
      image: AssetImage('lib/assets/logo-wfrs.png', package: 'nsg_data'),
      width: 140.0,
      height: 140.0,
      alignment: Alignment.center,
    );
    return logo;
  }

  Widget getBackground() {
    Widget background = const SizedBox();
    return background;
  }

  Widget getButtons() {
    return const ElevatedButton(
      onPressed: null,
      child: Text('you need to override getButtons'),
    );
  }

  void sendData() {
    // if (provider.)
    // callback.sendData();
  }
}

class NsgLoginRegistrationWidget extends StatefulWidget {
  final NsgLoginParams? widgetParams;
  final NsgDataProvider provider;
  final NsgLoginRegistrationPage registrationPage;

  const NsgLoginRegistrationWidget(
    this.registrationPage,
    this.provider, {
    super.key,
    this.widgetParams,
  });
  @override
  State<StatefulWidget> createState() => _NsgLoginregistrationState();
}

class _NsgLoginregistrationState extends State<NsgLoginRegistrationWidget> {
  Timer? updateTimer;
  bool isBusy = false;
  int secondsRepeateLeft = 120;
  String phoneNumber = '';
  String email = '';
  bool isLoginSuccessfull = false;
  bool isSMSRequested = false;
  String captchaCode = '';
  //TODO: заполнять токен!!!!!
  String firebaseToken = '';
  late NsgLoginType loginType;

  @override
  Widget build(BuildContext context) {
    return _getBody(context);
  }

  @override
  void initState() {
    //widget.registrationPage.callback.sendDataPressed = () => doSmsRequest(loginType: loginType, firebaseToken: firebaseToken);
    if (widget.widgetParams!.usePhoneLogin) {
      loginType = NsgLoginType.phone;
    } else {
      loginType = NsgLoginType.email;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _getBody(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: widget.registrationPage.getBackground()),
        Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(child: widget.registrationPage.getLogo()),
                Container(child: _getContext(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  String securityCode = '';
  PhoneInputFormatter phoneFormatter = PhoneInputFormatter();
  Widget _getContext(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        decoration: BoxDecoration(
          color: nsgtheme.colorMainBack,
          borderRadius: const BorderRadius.all(Radius.circular(3.0)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      widget.widgetParams!.headerMessageRegistration,
                      style: widget.widgetParams!.headerMessageStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.widgetParams!.usePhoneLogin &&
                      widget.widgetParams!.useEmailLogin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, top: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: NsgCheckBox(
                              key: GlobalKey(),
                              radio: true,
                              label: widget.widgetParams!.textEnterPhone,
                              onPressed: (bool currentValue) {
                                setState(() {
                                  loginType = NsgLoginType.phone;
                                });
                              },
                              value: loginType == NsgLoginType.phone,
                            ),
                          ),
                          Expanded(
                            child: NsgCheckBox(
                              key: GlobalKey(),
                              radio: true,
                              label: widget.widgetParams!.textEnterEmail,
                              onPressed: (bool currentValue) {
                                setState(() {
                                  loginType = NsgLoginType.email;
                                });
                              },
                              value: loginType == NsgLoginType.email,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.widgetParams!.usePhoneLogin)
                    if (loginType == NsgLoginType.phone)
                      TextFormField(
                        key: GlobalKey(),
                        cursorColor: Colors.black,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [phoneFormatter],
                        // style: widget.widgetParams!.textPhoneField,
                        style: TextStyle(color: nsgtheme.colorText),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                            left: 10,
                            top: 10,
                            right: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              nsgtheme.borderRadius,
                            ),
                          ),
                          filled: true,
                          fillColor: widget.widgetParams!.phoneFieldColor,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              nsgtheme.borderRadius,
                            ),
                            borderSide: BorderSide(
                              color: nsgtheme.colorText,
                              width: 1.0,
                            ),
                          ),
                          errorStyle: const TextStyle(fontSize: 12),
                          hintText: widget.widgetParams!.textEnterEmail,
                          hintStyle: TextStyle(
                            color: nsgtheme.colorText.withAlpha(75),
                          ),
                        ),
                        initialValue: phoneNumber,
                        onChanged: (value) => phoneNumber = value,
                        validator: (value) =>
                            isPhoneValid(value!) && value.length >= 16
                            ? null
                            : widget.widgetParams!.textEnterCorrectPhone,
                      ),
                  if (widget.widgetParams!.useEmailLogin)
                    if (loginType == NsgLoginType.email)
                      TextFormField(
                        key: GlobalKey(),
                        cursorColor: Colors.black,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: null,
                        style: TextStyle(color: nsgtheme.colorText),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                            left: 10,
                            top: 10,
                            right: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              nsgtheme.borderRadius,
                            ),
                          ),
                          filled: true,
                          fillColor: widget.widgetParams!.phoneFieldColor,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              nsgtheme.borderRadius,
                            ),
                            borderSide: BorderSide(
                              color: nsgtheme.colorText,
                              width: 1.0,
                            ),
                          ),
                          errorStyle: const TextStyle(fontSize: 12),
                          hintText: widget.widgetParams!.textEnterEmail,
                          hintStyle: TextStyle(
                            color: nsgtheme.colorText.withAlpha(75),
                          ),
                        ),
                        initialValue: email,
                        onChanged: (value) => email = value,
                        validator: (value) => null,
                      ),
                  const SizedBox(height: 15),
                  widget.registrationPage.getButtons(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: InkWell(
                      onTap: () {
                        //gotoLoginPage(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: HoverWidget(
                          hoverChild: Text(
                            widget.widgetParams!.textReturnToLogin,
                            style: const TextStyle(),
                          ),
                          onHover: (PointerEnterEvent event) {},
                          child: Text(
                            widget.widgetParams!.textReturnToLogin,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void doSmsRequest({
    NsgLoginType loginType = NsgLoginType.phone,
    String? password,
    required firebaseToken,
  }) {
    var context = Get.context;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isSMSRequested = true;
    });
    NsgMetrica.reportLoginStart('Phone');

    /* -------------------------------------------------------------- Если введён пароль -------------------------------------------------------------- */
    if (password != null && password != '') {
      captchaCode = password;
    }
    if (loginType == NsgLoginType.phone) {
      widget.widgetParams!.phoneNumber = phoneNumber;
    } else {
      widget.widgetParams!.email = email;
    }
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
            widget.widgetParams!.showError(
              context,
              widget.widgetParams!.textCheckInternet,
            );
          }
        });
  }

  // void gotoLoginPage(BuildContext? context) {
  //   Navigator.push<bool>(
  //       context!, MaterialPageRoute(builder: (context) => _getLoginWidget()));
  // }

  //Widget _getLoginWidget() {
  // return widget.provider.getLoginWidget!(widget.provider);
  //}

  //Widget _getVerificationWidget() {
  //return widget.provider.getVerificationWidget!(widget.provider);
  //}

  void checkRequestSMSanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    if (updateTimer != null) {
      updateTimer!.cancel();
    }
    if (answerCode.errorCode == 40300) {
      nsgSnackbar(text: answerCode.errorMessage);
      return;
    }
    if (answerCode.errorCode == 0) {
      setState(() {
        isSMSRequested = false;
      });
      NsgMetrica.reportLoginSuccess('Phone');
      gotoNextPage(context);
    }
    var needRefreshCaptcha = false;
    var errorMessage = widget.widgetParams!.errorMessageByStatusCode!(
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
    isSMSRequested = false;
    NsgMetrica.reportLoginFailed('Phone', answerCode.errorCode.toString());
    widget.widgetParams!.showError(context, errorMessage);

    if (needRefreshCaptcha) {
      //refreshCaptcha();
    } else {
      setState(() {
        isSMSRequested = false;
      });
    }
  }

  void gotoNextPage(BuildContext? context) async {
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
    //   //refreshCaptcha();
    // }
  }

  void checkLoginResult(BuildContext context, NsgLoginResponse answer) {
    var answerCode = answer.errorCode;
    if (answerCode != 0) {
      var needEnterCaptcha = (answerCode > 40100 && answerCode < 40400);
      var errorMessage = answer.errorMessage;
      if (errorMessage == '') {
        widget.widgetParams!.errorMessageByStatusCode!(answerCode);
      }
      showError(errorMessage, needEnterCaptcha);
    } else {
      //NsgNavigator.instance.offAndToPage(widget.widgetParams!.mainPage);
    }
  }

  Future showError(String errorMessage, bool needEnterCaptcha) async {
    widget.widgetParams!.showError(context, errorMessage, delayed: 3);
    if (needEnterCaptcha) {
      setState(() {
        isBusy = true;
      });
    }
  }
}
