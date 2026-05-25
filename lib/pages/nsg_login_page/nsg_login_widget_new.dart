// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:hovering/hovering.dart';
import 'package:nsg_controls/dialog/nsg_future_progress_exception.dart';
import 'package:nsg_controls/dialog/show_nsg_dialog.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_controls/widgets/nsg_snackbar.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/nsg_login_params.dart';
import 'package:nsg_login/pages/nsg_login_page/nsg_login_page_new.dart';
import 'package:nsg_login/pages/nsg_login_state.dart';
import 'package:nsg_login/pages/nsg_social_login_widget.dart';
import 'package:nsg_login/social_login/social_login_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginWidgetNew extends StatefulWidget {
  const LoginWidgetNew(
    this.loginPage,
    this.provider, {
    super.key,
    required this.widgetParams,
    this.initialEmail,
  });

  final NsgLoginPageNew loginPage;
  final NsgDataProvider provider;
  final NsgLoginParams widgetParams;
  final String? initialEmail;

  @override
  State<LoginWidgetNew> createState() => _LoginWidgetNewState();
}

class _LoginWidgetNewState extends State<LoginWidgetNew> {
  late final SocialLoginProvider socialProvider = SocialLoginProvider(
    widget.provider,
  );

  late InputDecoration decor;
  Image? captureImage;
  String phoneNumber = '';
  String email = '';
  String captchaCode = '';
  String securityCode = '';
  bool isCaptchaLoading = false;
  int currentStage = _LoginWidgetNewState.stagePreLogin;
  bool isLoginSuccessfull = false;
  String password = '';
  String newPassword1 = '';
  String newPassword2 = '';
  final PhoneInputFormatter phoneFormatter = PhoneInputFormatter();
  late NsgLoginType loginType;
  int secondsLeft = -1;
  Timer? updateTimer;
  NsgLoginState currentState = NsgLoginState.login;
  bool _loginResultHandled = false;
  bool _closeHandled = false;
  String firebaseToken = '';
  bool _obscureLoginPassword = true;
  bool _obscureNewPassword1 = true;
  bool _obscureNewPassword2 = true;

  static int stagePreLogin = 1;

  final _formKey = GlobalKey<FormState>();
  TextEditingController? _captchaController;

  ValueNotifier<PasswordStrength?>? passwordListener;

  @override
  void initState() {
    super.initState();
    email = widget.initialEmail ?? '';
    decor = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorText, width: 1),
      ),
      filled: true,
      fillColor: widget.widgetParams.phoneFieldColor,
      errorStyle: const TextStyle(fontSize: 12),
      hintStyle: TextStyle(color: nsgtheme.colorText.withAlpha(75)),
      alignLabelWithHint: true,
    );
    widget.loginPage.callback.sendDataPressed = () => doSmsRequest(
      context,
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
    updateTimer?.cancel();
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
              children: [widget.loginPage.getLogo(), _getContext(context)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getContext(BuildContext context) {
    if (isLoginSuccessfull && !_loginResultHandled) {
      _loginResultHandled = true;
      Future.delayed(const Duration(milliseconds: 500)).then((_) {
        if (mounted) {
          if (widget.widgetParams.onLogin != null) {
            widget.widgetParams.onLogin!();
          } else {
            NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
          }
        }
      });
    }
    _captchaController ??= TextEditingController();
    return isLoginSuccessfull
        ? getContextSuccessful(context)
        : Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  _buildAuthCard(context),
                  if (widget.widgetParams.onClose != null)
                    InkWell(
                      onTap: () {
                        if (_closeHandled) {
                          return;
                        }
                        _closeHandled = true;
                        widget.widgetParams.onClose!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5),
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

  Widget _buildAuthCard(BuildContext context) {
    return Container(
      width: widget.widgetParams.cardSize,
      decoration: BoxDecoration(
        color: widget.widgetParams.cardColor ?? nsgtheme.colorMainBack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: nsgtheme.colorTertiary.withAlpha(120),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: nsgtheme.colorMain.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.widgetParams.headerMessageVisible == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                widget.widgetParams.headerMessage,
                style: TextStyle(color: nsgtheme.colorText),
                textAlign: TextAlign.center,
              ),
            ),
          if (widget.widgetParams.usePasswordLogin &&
              currentState != NsgLoginState.verification)
            _buildTopTabs(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentState == NsgLoginState.login)
                  ..._loginStateWidget(context),
                if (currentState == NsgLoginState.registration)
                  ..._registrationStateWidget(context),
                if (currentState == NsgLoginState.verification)
                  ..._verificationStateWidget(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context) {
    if (!widget.widgetParams.enableRegistration) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Text(
          widget.widgetParams.loginHeaderText,
          style: TextStyle(
            fontSize: nsgtheme.sizeH2,
            color: nsgtheme.colorText,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    const topRadius = Radius.circular(20);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: Material(
        color: nsgtheme.colorSecondary,
        child: Row(
          children: [
            Expanded(
              child: _tabCell(
                label: widget.widgetParams.headerMessageLogin.toUpperCase(),
                selected: currentState == NsgLoginState.login,
                onTap: () {
                  if (currentState != NsgLoginState.login) {
                    setState(() => currentState = NsgLoginState.login);
                  }
                },
              ),
            ),
            Expanded(
              child: _tabCell(
                label: widget.widgetParams.headerMessageRegistration
                    .toUpperCase(),
                selected: currentState == NsgLoginState.registration,
                onTap: () {
                  if (currentState != NsgLoginState.registration) {
                    setState(() => currentState = NsgLoginState.registration);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabCell({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? nsgtheme.colorPrimary
          : nsgtheme.colorSecondary.c0, //TODO: Поправить цвета
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? nsgtheme.colorBase.b0 : nsgtheme.colorTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: nsgtheme.colorTertiary.withAlpha(100),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nsgtheme.colorTertiary.withAlpha(180),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: nsgtheme.colorTertiary.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Material(
      color: nsgtheme.colorPrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: nsgtheme.colorBase.b0,
              fontWeight: FontWeight.bold,
              fontSize: nsgtheme.sizeL,
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: HoverWidget(
        hoverChild: Text(text, style: TextStyle(color: nsgtheme.colorText)),
        onHover: (_) {},
        child: Text(
          text,
          style: TextStyle(
            color: nsgtheme.colorText,
            decoration: TextDecoration.underline,
            decorationColor: nsgtheme.colorText.withAlpha(200),
          ),
        ),
      ),
    );
  }

  Widget _labeledField({required String? label, required Widget field}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: nsgtheme.sizeM,
              color: nsgtheme.colorText.withAlpha(230),
            ),
          ),
          const SizedBox(height: 6),
        ],
        field,
      ],
    );
  }

  TextStyle get _fieldTextStyle =>
      TextStyle(color: nsgtheme.colorText, fontSize: nsgtheme.sizeL);

  Widget? getcaptchaImage() {
    if (captureImage == null || isCaptchaLoading) {
      return Icon(
        Icons.hourglass_empty,
        color: widget.widgetParams.textColor,
        size: 40,
      );
    }
    return captureImage;
  }

  Future<Image> _loadCaptureImage() async {
    Image image;
    try {
      image = await widget.provider.getCaptcha();
    } catch (e) {
      image = Image.asset('assets/images/logo.png', package: 'nsg_login');
    }
    return image;
  }

  void checkRequestSMSanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    updateTimer?.cancel();

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
      if (answerCode.errorCode != 0) {
        final errorMessage = widget.widgetParams.errorMessageByStatusCode!(
          answerCode.errorCode,
        );
        widget.widgetParams.showError(context, errorMessage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && widget.widgetParams.usePasswordLogin) {
      NsgMetrica.reportLoginSuccess('Phone');
      if (widget.widgetParams.onLogin != null) {
        widget.widgetParams.onLogin!();
      } else {
        NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && !widget.widgetParams.usePasswordLogin) {
      gotoNextPage(context);
      return;
    }
    var needRefreshCaptcha = false;
    final errorMessage = widget.widgetParams.errorMessageByStatusCode!(
      answerCode.errorCode,
    );
    switch (answerCode.errorCode) {
      case 40102:
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
    }
  }

  void doSmsRequest(
    BuildContext context, {
    NsgLoginType loginType = NsgLoginType.email,
    String? password,
    required String firebaseToken,
  }) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    NsgMetrica.reportLoginStart(loginType.toString());

    if (password != null && password != '') {
      captchaCode = password;
    } else {
      captchaCode = '';
    }

    if (widget.widgetParams.usePasswordLogin) {
      widget.provider
          .phoneLoginPassword(
            phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
            securityCode: captchaCode,
            loginType: loginType,
          )
          .then((value) {
            if (mounted) {
              checkRequestSMSanswer(context, value);
            }
          })
          .catchError((e) {
            if (mounted && context.mounted) {
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
            if (mounted && context.mounted) {
              checkRequestSMSanswer(context, value);
            }
          })
          .catchError((e) {
            if (mounted && context.mounted) {
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
    if (!widget.widgetParams.useCaptcha) {
      return;
    }
    _loadCaptureImage().then(
      (value) => setState(() {
        captureImage = value;
        _captchaController!.value = TextEditingValue.empty;
        isCaptchaLoading = false;
        updateTimer?.cancel();
        secondsLeft = 120;
        updateTimer = Timer.periodic(const Duration(seconds: 1), captchaTimer);
      }),
    );
  }

  void captchaTimer(Timer timer) {
    if (secondsLeft > 0) {
      setState(() {
        secondsLeft--;
      });
    } else {
      updateTimer?.cancel();
      updateTimer = null;
      refreshCaptcha();
    }
  }

  void gotoNextPage(BuildContext? context) async {}

  Widget getContextSuccessful(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        color: widget.widgetParams.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 250,
                      child: Text(
                        widget.widgetParams.textLoginSuccessful,
                        style: widget.widgetParams.headerMessageStyle,
                        textAlign: TextAlign.center,
                      ),
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

  String? _stackedInputValidator(
    String? value,
    String? Function(String?)? inner,
  ) {
    if (value != newPassword2) {
      return null;
    }
    if (inner != null) {
      return inner(value);
    }
    return null;
  }

  List<Widget> _loginStateWidget(BuildContext context) {
    return [
      if (widget.widgetParams.useEmailLogin &&
          widget.widgetParams.usePhoneLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  loginType == NsgLoginType.email
                      ? widget.widgetParams.textEnterEmail
                      : widget.widgetParams.textEnterPhone,
                  style: TextStyle(
                    color: nsgtheme.colorText,
                    fontSize: nsgtheme.sizeL,
                  ),
                ),
              ),
              _link(
                loginType == NsgLoginType.email
                    ? widget.widgetParams.textEnterPhone
                    : widget.widgetParams.textEnterEmail,
                () => setState(() {
                  loginType = loginType == NsgLoginType.email
                      ? NsgLoginType.phone
                      : NsgLoginType.email;
                }),
              ),
            ],
          ),
        ),
      if (widget.widgetParams.usePhoneLogin)
        if (loginType == NsgLoginType.phone)
          _labeledField(
            label: null,
            field: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatter],
              style: _fieldTextStyle,
              textAlign: TextAlign.start,
              decoration: decor.copyWith(
                hintText: widget.widgetParams.textEnterPhone,
              ),
              initialValue: phoneNumber,
              onChanged: (value) => phoneNumber = value,
              validator: (value) => isPhoneValid(value!)
                  ? null
                  : widget.widgetParams.textEnterCorrectPhone,
            ),
          ),
      if (widget.widgetParams.useEmailLogin)
        if (loginType == NsgLoginType.email)
          _labeledField(
            label: null,
            field: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.emailAddress,
              style: _fieldTextStyle,
              textAlign: TextAlign.start,
              decoration: decor.copyWith(
                hintText: widget.widgetParams.textEnterEmail,
              ),
              initialValue: email,
              onChanged: (value) => email = value,
              validator: (value) => null,
            ),
          ),
      if (widget.widgetParams.usePasswordLogin)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            key: GlobalKey(),
            obscureText: _obscureLoginPassword,
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.visiblePassword,
            style: _fieldTextStyle,
            textAlign: TextAlign.start,
            decoration: decor.copyWith(
              hintText: widget.widgetParams.textEnterPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: nsgtheme.colorText.withAlpha(160),
                  size: 22,
                ),
                onPressed: () => setState(
                  () => _obscureLoginPassword = !_obscureLoginPassword,
                ),
              ),
            ),
            onChanged: (value) => password = value,
            validator: (value) => value == null || value.isEmpty
                ? tran.password_is_required
                : null,
          ),
        ),
      if (widget.widgetParams.usePasswordLogin &&
          widget.widgetParams.enableRegistration)
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (kIsWeb ||
                  (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS))
                Expanded(child: widget.loginPage.getRememberMeCheckbox())
              else
                const Spacer(),
              _link(widget.widgetParams.textRegistration, () {
                currentState = NsgLoginState.registration;
                setState(() {});
              }),
            ],
          ),
        )
      else if (kIsWeb ||
          (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: widget.loginPage.getRememberMeCheckbox(),
          ),
        )
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
                      onPressed: refreshCaptcha,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextFormField(
            key: GlobalKey(),
            cursorColor: Theme.of(context).primaryColor,
            controller: _captchaController,
            textAlign: TextAlign.start,
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
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _primaryButton(
          text: widget.widgetParams.headerMessageLogin,
          onPressed: () {
            widget.widgetParams.phoneNumber = phoneNumber;
            widget.widgetParams.loginType = loginType;
            doSmsRequest(
              context,
              loginType: loginType,
              password: password,
              firebaseToken: firebaseToken,
            );
          },
        ),
      ),
      if (widget.widgetParams.socialLoginTypes.isNotEmpty) ...[
        _socialDivider(),
        _socialLogin(context),
      ],
    ];
  }

  List<Widget> _registrationStateWidget(BuildContext context) {
    if (passwordListener == null &&
        widget.widgetParams.passwordIndicator != null) {
      passwordListener = ValueNotifier(null);
    }
    return [
      if (widget.widgetParams.usePhoneLogin &&
          widget.widgetParams.useEmailLogin)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  loginType == NsgLoginType.email
                      ? widget.widgetParams.textEnterEmail
                      : widget.widgetParams.textEnterPhone,
                  style: TextStyle(
                    color: nsgtheme.colorText,
                    fontSize: nsgtheme.sizeL,
                  ),
                ),
              ),
              _link(
                loginType == NsgLoginType.email
                    ? widget.widgetParams.textEnterPhone
                    : widget.widgetParams.textEnterEmail,
                () => setState(() {
                  loginType = loginType == NsgLoginType.email
                      ? NsgLoginType.phone
                      : NsgLoginType.email;
                }),
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
              style: _fieldTextStyle,
              textAlign: TextAlign.start,
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
        if (loginType == NsgLoginType.email) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: GlobalKey(),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.emailAddress,
              style: _fieldTextStyle,
              textAlign: TextAlign.start,
              decoration: decor.copyWith(
                hintText: widget.widgetParams.textEnterEmail,
              ),
              initialValue: email,
              onChanged: (value) => email = value,
              validator: (value) => null,
            ),
          ),
        ],
      const SizedBox(height: 4),
      _primaryButton(
        text: widget.widgetParams.textSendSms,
        onPressed: () {
          doSmsRequest(
            context,
            firebaseToken: firebaseToken,
            loginType: loginType,
          );
        },
      ),
      if (widget.widgetParams.socialLoginTypes.isNotEmpty) ...[
        _socialDivider(),
        _socialLogin(context),
      ],
    ];
  }

  List<Widget> _verificationStateWidget(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          widget.widgetParams.headerMessageVerification,
          style: widget.widgetParams.headerMessageStyle,
          textAlign: TextAlign.start,
        ),
      ),
      _getInput(
        hintText: widget.widgetParams.textEnterCode,
        initialValue: securityCode,
        autofillHints: const [AutofillHints.oneTimeCode],
        keyboardType: TextInputType.number,
        onChanged: (value) => securityCode = value,
        validator: (value) => value == null || value.length < 6
            ? tran.enter_confirmation_code_from_message
            : null,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          loginType == NsgLoginType.email
              ? tran.we_sent_you_the_code_in_a_message_by_email_phone(email)
              : tran.we_sent_you_a_code_via_sms_to_your_phone_number(
                  phoneNumber,
                ),
          style:
              widget.widgetParams.descriptionStyle ??
              TextStyle(
                fontSize: nsgtheme.sizeM,
                color: nsgtheme.colorText.withAlpha(180),
                height: 1.35,
              ),
        ),
      ),
      if (widget.widgetParams.usePasswordLogin) ...[
        _labeledField(
          label: widget.widgetParams.textEnterNewPassword,
          field: TextFormField(
            key: GlobalKey(),
            obscureText: _obscureNewPassword1,
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.visiblePassword,
            style: _fieldTextStyle,
            textAlign: TextAlign.start,
            decoration: decor.copyWith(
              hintText: widget.widgetParams.textEnterNewPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword1
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: nsgtheme.colorText.withAlpha(160),
                  size: 22,
                ),
                onPressed: () => setState(() {
                  _obscureNewPassword1 = !_obscureNewPassword1;
                }),
              ),
            ),
            initialValue: newPassword1,
            onChanged: (value) {
              if (widget.widgetParams.passwordIndicator != null) {
                passwordListener!.value =
                    widget.widgetParams.passwordIndicator!(value);
              }
              newPassword1 = value;
            },
            validator: (v) => _stackedInputValidator(
              v,
              widget.widgetParams.passwordValidator,
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 10)),
        _labeledField(
          label: null,
          field: TextFormField(
            key: GlobalKey(),
            obscureText: _obscureNewPassword2,
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.visiblePassword,
            style: _fieldTextStyle,
            textAlign: TextAlign.start,
            decoration: decor.copyWith(
              hintText: widget.widgetParams.textEnterPasswordAgain,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword2
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: nsgtheme.colorText.withAlpha(160),
                  size: 22,
                ),
                onPressed: () => setState(
                  () => _obscureNewPassword2 = !_obscureNewPassword2,
                ),
              ),
            ),
            initialValue: newPassword2,
            onChanged: (value) => newPassword2 = value,
            validator: (v) => _stackedInputValidator(
              v,
              (x) => x == newPassword1 ? null : tran.passwords_mistmatch,
            ),
          ),
        ),
      ],
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
            defaultMessage: tran.password_is_empty,
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(
          onTap: () {
            currentState = NsgLoginState.login;
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: HoverWidget(
              hoverChild: Text(
                tran.try_another_login_method,
                style: const TextStyle(),
              ),
              onHover: (PointerEnterEvent event) {},
              child: Text(
                tran.try_another_login_method,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ),
      _primaryButton(
        text: widget.widgetParams.textConfirm,
        onPressed: () {
          setNewPassword(
            context,
            securityCode: securityCode,
            loginType: loginType,
            newPassword: newPassword1,
          );
        },
      ),
    ];
  }

  Widget _getInput({
    String hintText = '',
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    Iterable<String> autofillHints = const [],
    bool obscureText = false,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: GlobalKey(),
        autofillHints: autofillHints,
        cursorColor: Theme.of(context).primaryColor,
        keyboardType: keyboardType,
        style: _fieldTextStyle,
        textAlign: TextAlign.start,
        decoration: decor.copyWith(hintText: hintText),
        initialValue: initialValue,
        onChanged: onChanged,
        validator: (value) {
          if (value != newPassword2) {
            return null;
          }
          if (validator != null) {
            return validator(value);
          }
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
                  for (var i = 0; i < values.length; i++) {
                    if (values.elementAt(i) == listener.value) {
                      return colors.elementAt(i);
                    }
                  }
                  return defaultColor ?? Colors.transparent;
                })(),
              ),
              child: SizedBox(width: double.infinity, height: 5, child: child),
            ),
            const SizedBox(height: 5),
            Text(
              (() {
                for (var i = 0; i < values.length; i++) {
                  if (values.elementAt(i) == listener.value) {
                    return messages.elementAt(i);
                  }
                }
                return defaultMessage ?? '';
              })(),
            ),
          ],
        );
      },
    );
  }

  Widget _socialLogin(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: widget.widgetParams.socialLoginTypes.map((i) {
            Future<void> onSocialTap() async {
              nsgFutureProgressAndException(
                func: () async {
                  try {
                    final success = await socialProvider.processLogin(
                      i,
                      context: context,
                      onAuthLink: (url) async {
                        NsgSocialLoginResponse? response;
                        if (!kIsWeb) {
                          await showNsgDialog(
                            contentPadding: EdgeInsets.zero,
                            context: context,
                            title: tran.authorization_social(i.socialName),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: NsgSocialLoginWidget(
                                authUrl: url,
                                onVerify: (res) async {
                                  response = res;
                                },
                              ),
                            ),
                            buttons: const [],
                            showCloseButton: true,
                          );
                        } else {
                          await launchUrl(
                            Uri.parse(url),
                            webOnlyWindowName: '_self',
                          );
                        }
                        if (response != null) {
                          return response!;
                        }
                        return null;
                      },
                    );
                    if (success) {
                      if (widget.widgetParams.onLogin != null) {
                        widget.widgetParams.onLogin!();
                      } else {
                        NsgNavigator.instance.offAndToPage(
                          widget.widgetParams.mainPage,
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Social login error: $e');
                    if (context.mounted) {
                      nsgSnackbar(
                        text: e.toString(),
                        type: NsgSnarkBarType.error,
                      );
                    }
                    rethrow;
                  }
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: i.socialLoginButton(onSocialTap),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void setNewPassword(
    BuildContext context, {
    required String securityCode,
    required NsgLoginType loginType,
    required String newPassword,
  }) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.provider
        .phoneLogin(
          phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
          securityCode: securityCode,
          register: true,
          newPassword: newPassword,
        )
        // ignore: use_build_context_synchronously
        .then((value) => checkRequestNewPasswordanswer(context, value))
        .catchError((e) {
          if (context.mounted) {
            widget.widgetParams.showError(
              context,
              widget.widgetParams.textCheckInternet,
            );
          }
        });
  }

  void checkRequestNewPasswordanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    updateTimer?.cancel();
    if (answerCode.errorCode == 0) {
      NsgMetrica.reportLoginSuccess('Phone');
      widget.widgetParams.eventLoginWidgweClosed?.call(true);
      if (widget.widgetParams.onLogin != null) {
        widget.widgetParams.onLogin!();
      } else {
        NsgNavigator.instance.offAndToPage(widget.widgetParams.mainPage);
      }
      return;
    }
    final errorMessage = widget.widgetParams.errorMessageByStatusCode!(
      answerCode.errorCode,
    );
    NsgMetrica.reportLoginFailed('Phone', answerCode.toString());
    widget.widgetParams.showError(context, errorMessage);
  }
}
