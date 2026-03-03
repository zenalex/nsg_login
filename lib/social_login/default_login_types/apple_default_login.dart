import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

abstract class AppleDefaultAuth extends SocialAuthType {
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
  }) async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    if (credential.identityToken == null) return null;

    return NsgSocialLoginResponse(
      code: credential.identityToken!,
      state: rawNonce,
      loginType: 'Apple',
    );
  }

  @override
  Widget Function(void Function() login) get icon =>
      (onSocialTap) => Flexible(
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 44),
            child: SignInWithAppleButton(onPressed: () => onSocialTap()),
          ),
        ),
      );

  @override
  String get socialName => "Apple";

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
