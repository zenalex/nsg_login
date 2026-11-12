import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/social_login/default_login_types/default_login_dialog.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_oauth_wait.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:telegram_login_flutter/telegram_login_flutter.dart';

abstract class TelegramDefaultAuth extends SocialAuthType {
  String get botId;
  String get botDomain;

  InputDecoration? get inputDecoration => null;
  Color? get cursorColor => null;

  String get buttonText => tran.login_via_social("Telegram");
  TextStyle? get textStyle => null;
  Color? get backgroundColor => null;

  @override
  String get requestFunction => "";

  @override
  String get requestMethodName => "";

  @override
  String get verifyFunction;

  @override
  String get verifyMethodName;

  @override
  bool get useNativeAuth => true;

  @override
  Future<NsgSocialLoginResponse?> performNativeAuth({
    BuildContext? context,
    NsgDataProvider? provider,
  }) async {
    NsgSocialLoginResponse? response;
    if (context != null) {
      await SocialLoginDialog.show(
        context,
        builder: (dialogContext) => TelegramLoginWidget(
          inputDecoration: inputDecoration,
          cursorColor: cursorColor,
          title: socialName,
          botId: botId,
          botDomain: botDomain,
          buttonText: buttonText,
          logo: icon(50),
          onLoginSuccess: (user) {
            response = NsgSocialLoginResponse(
              code: user.hash.toString(),
              state: user.id.toString(),
              payload: user.toJson(),
              loginType: 'Telegram',
            );
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }
    return response;
  }

  @override
  Widget Function(void Function() login) get socialLoginButton =>
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: backgroundColor,
        buttonText: buttonText,
        textStyle: textStyle,
        logo: icon(20),
      );

  @override
  Widget icon(size) => SvgPicture.string(
    '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 240.1 240.1">
<linearGradient id="Oval_1_" gradientUnits="userSpaceOnUse" x1="-838.041" y1="660.581" x2="-838.041" y2="660.3427" gradientTransform="matrix(1000 0 0 -1000 838161 660581)">
 <stop offset="0" style="stop-color:#2AABEE"/>
 <stop offset="1" style="stop-color:#229ED9"/>
</linearGradient>
<circle fill-rule="evenodd" clip-rule="evenodd" fill="url(#Oval_1_)" cx="120.1" cy="120.1" r="120.1"/>
<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" d="M54.3,118.8c35-15.2,58.3-25.3,70-30.2 c33.3-13.9,40.3-16.3,44.8-16.4c1,0,3.2,0.2,4.7,1.4c1.2,1,1.5,2.3,1.7,3.3s0.4,3.1,0.2,4.7c-1.8,19-9.6,65.1-13.6,86.3 c-1.7,9-5,12-8.2,12.3c-7,0.6-12.3-4.6-19-9c-10.6-6.9-16.5-11.2-26.8-18c-11.9-7.8-4.2-12.1,2.6-19.1c1.8-1.8,32.5-29.8,33.1-32.3 c0.1-0.3,0.1-1.5-0.6-2.1c-0.7-0.6-1.7-0.4-2.5-0.2c-1.1,0.2-17.9,11.4-50.6,33.5c-4.8,3.3-9.1,4.9-13,4.8 c-4.3-0.1-12.5-2.4-18.7-4.4c-7.5-2.4-13.5-3.7-13-7.9C45.7,123.3,48.7,121.1,54.3,118.8z"/>
</svg>''',
    semanticsLabel: 'Telegram logo',
    width: size,
    height: size,
  );

  @override
  String get socialName => "Telegram";
}

/// Подмена oauth-клиента в тесте. В приложении — [TelegramPluginOauth].
abstract class TelegramOauthGateway {
  Future<void> start(String phoneNumber);
  Future<bool> checkLoginStatus();
  Future<TelegramUser?> getUserData();
}

class TelegramPluginOauth implements TelegramOauthGateway {
  TelegramPluginOauth(this._auth);

  final TelegramAuth _auth;

  @override
  Future<void> start(String phoneNumber) async {
    await _auth.launchTelegram();
    await _auth.initiateLogin();
  }

  @override
  Future<bool> checkLoginStatus() => _auth.checkLoginStatus();

  @override
  Future<TelegramUser?> getUserData() => _auth.getUserData();
}

class TelegramLoginWidget extends StatefulWidget {
  const TelegramLoginWidget({
    super.key,
    required this.botId,
    required this.botDomain,
    this.timeout,
    required this.buttonText,
    required this.onLoginSuccess,
    this.onAuthError,
    this.title,
    this.logo,
    this.inputDecoration,
    this.cursorColor,
    this.oauth,
    this.pollInterval = const Duration(seconds: 2),
    this.delay,
    this.now,
  });

  final String botId;
  final String botDomain;
  final String buttonText;
  final String? title;
  final Duration? timeout;
  final Widget? logo;
  final void Function(TelegramUser user) onLoginSuccess;
  final void Function(dynamic error)? onAuthError;
  final InputDecoration? inputDecoration;
  final Color? cursorColor;
  final TelegramOauthGateway Function(String phoneNumber, Duration timeout)?
  oauth;
  final Duration pollInterval;
  final Future<void> Function(Duration step)? delay;
  final DateTime Function()? now;

  @override
  State<TelegramLoginWidget> createState() => _TelegramLoginWidgetState();
}

class _TelegramLoginWidgetState extends State<TelegramLoginWidget>
    with WidgetsBindingObserver {
  final _phone = TextEditingController();
  String? _error;
  TelegramOauthWait? _wait;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _phone.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wait = _wait;
    if (wait == null) return;
    if (state == AppLifecycleState.resumed) {
      wait.noteResume();
    } else {
      wait.notePause();
    }
  }

  Future<void> _login(String phoneNumber) async {
    if (mounted) setState(() => _error = null);
    final timeout = widget.timeout ?? telegramOauthActiveTimeout;
    final gateway =
        widget.oauth?.call(phoneNumber, timeout) ??
        TelegramPluginOauth(
          TelegramAuth(
            phoneNumber: phoneNumber,
            botId: widget.botId,
            botDomain: widget.botDomain,
            timeout: timeout,
          ),
        );
    final wait = TelegramOauthWait(timeout: timeout, now: widget.now);
    _wait = wait;
    try {
      await gateway.start(phoneNumber);
      final user = await waitTelegramOauth<TelegramUser>(
        wait: wait,
        isLoggedIn: gateway.checkLoginStatus,
        readUser: gateway.getUserData,
        delay: widget.delay ?? (step) => Future<void>.delayed(step),
        interval: widget.pollInterval,
        cancelled: () => _closed,
      );
      if (_closed) return;
      if (user == null) {
        _showFailure(Exception('Login timeout'));
        return;
      }
      widget.onLoginSuccess(user);
    } catch (e) {
      if (_closed) return;
      _showFailure(e);
    } finally {
      _wait = null;
    }
  }

  void _showFailure(Object error) {
    widget.onAuthError?.call(error);
    if (!mounted) return;
    setState(() => _error = tran.telegram_login_failed);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSocialLoginDialog(
      title: widget.title,
      logo: widget.logo,
      buttonText: widget.buttonText,
      inputDecoration: widget.inputDecoration,
      cursorColor: widget.cursorColor,
      phoneController: _phone,
      errorText: _error,
      onButtonPressed: _login,
    );
  }
}
