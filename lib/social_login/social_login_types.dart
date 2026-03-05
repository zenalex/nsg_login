import 'package:flutter/material.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';

abstract class SocialAuthType {
  String get requestFunction;
  String get requestMethodName;
  String get verifyFunction;
  String get verifyMethodName;
  Map<String, dynamic>? get requestParams => NsgLoginModel().toJson();
  Map<String, dynamic>? getVerifyParams(NsgSocialLoginResponse response) =>
      response.toJson();

  /// Нативная авторизация на устройстве (например, Apple Sign In).
  /// Если true, вместо веб-флоу (request URL → WebView → verify)
  /// вызывается [performNativeAuth], результат отправляется на verify.
  bool get useNativeAuth => false;

  /// Выполняет нативную авторизацию на устройстве.
  /// Возвращает [NsgSocialLoginResponse] с code/state для верификации,
  /// или null если пользователь отменил.
  Future<NsgSocialLoginResponse?> performNativeAuth({
    BuildContext? context,
  }) async => null;

  Widget Function(void Function() login) get icon;
  String get socialName;
}

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.onTap,
    required this.logo,
    this.backgroundColor,
    required this.buttonText,
    this.textStyle,
  });

  final void Function() onTap;
  final Widget logo;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 44),
      child: Material(
        color: backgroundColor ?? nsgtheme.colorBase.c100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  logo,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: nsgtheme.colorBase.c0,
                        fontSize: nsgtheme.sizeXL,
                        fontWeight: FontWeight.w500,
                      ).merge(textStyle),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
