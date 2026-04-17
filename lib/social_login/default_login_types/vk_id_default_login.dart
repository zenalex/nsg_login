import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

abstract class VkIdDefaultAuth extends SocialAuthType {
  String get buttonText => tran.login_via_social(tran.vk);
  Set<String> get scopes => const {'email', 'phone'};
  bool get useConfidentialFlow => true;
  String? get authState => null;
  int get stateLength => 32;
  int get codeVerifierLength => 64;
  String get loginType => 'VkId';

  String? _state;
  String? _codeVerifier;

  @override
  String get requestFunction;

  @override
  String get requestMethodName;

  @override
  String get verifyFunction;

  @override
  String get verifyMethodName;

  @override
  Map<String, dynamic>? get requestParams {
    _state = authState ?? _generateState(stateLength);
    _codeVerifier = useConfidentialFlow ? _generateCodeVerifier(codeVerifierLength) : null;

    final params = NsgSocialLoginResponse(
      state: _state!,
      loginType: loginType,
      payload: {
        'flow': useConfidentialFlow ? 'confidential' : 'public',
        'scope': scopes.join(' '),
        if (_codeVerifier != null) 'code_verifier': _codeVerifier,
        if (_codeVerifier != null) 'code_challenge': _generateCodeChallenge(_codeVerifier!),
      },
    );
    return params.toJson();
  }

  @override
  Map<String, dynamic>? getVerifyParams(NsgSocialLoginResponse response) {
    final payload = <String, dynamic>{
      ...?response.payload,
      // Fallback for flows where backend expects values from initial request.
      if ((response.state).isEmpty && _state != null) 'state': _state,
      if (response.deviceId.isNotEmpty) 'device_id': response.deviceId,
      if (_codeVerifier != null) 'code_verifier': _codeVerifier,
    };

    return NsgSocialLoginResponse(
      code: response.code,
      state: response.state.isNotEmpty ? response.state : (_state ?? ''),
      deviceId: response.deviceId,
      loginType: response.loginType.isNotEmpty ? response.loginType : loginType,
      payload: payload,
    ).toJson();
  }

  @override
  bool get useNativeAuth => false;

  @override
  Widget Function(void Function() login) get socialLoginButton =>
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: const Color(0xFF0077FF),
        buttonText: buttonText,
        textStyle: TextStyle(color: nsgtheme.colorBase.c0, fontSize: nsgtheme.sizeM, fontWeight: FontWeight.w600),
        logo: icon(20),
      );

  @override
  String get socialName => tran.vk;

  @override
  Widget icon(size) => SvgPicture.string(
    '''<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0 48C0 25.3726 0 14.0589 7.02944 7.02944C14.0589 0 25.3726 0 48 0H52C74.6274 0 85.9411 0 92.9706 7.02944C100 14.0589 100 25.3726 100 48V52C100 74.6274 100 85.9411 92.9706 92.9706C85.9411 100 74.6274 100 52 100H48C25.3726 100 14.0589 100 7.02944 92.9706C0 85.9411 0 74.6274 0 52V48Z" fill="#0077FF"/>
                <path d="M53.2083 72.042C30.4167 72.042 17.4168 56.417 16.8751 30.417H28.2917C28.6667 49.5003 37.0833 57.5836 43.7499 59.2503V30.417H54.5002V46.8752C61.0836 46.1669 67.9994 38.667 70.3328 30.417H81.0831C79.2914 40.5837 71.7914 48.0836 66.458 51.1669C71.7914 53.6669 80.3335 60.2086 83.5835 72.042H71.7498C69.2081 64.1253 62.8752 58.0003 54.5002 57.1669V72.042H53.2083Z" fill="white"/>
                </svg>''',
    semanticsLabel: 'VK logo',
    width: size,
    height: size,
  );

  static String _generateState([int length = 32]) => _generateRandomBase(length: length, minLength: 32);

  static String _generateCodeVerifier([int length = 64]) => _generateRandomBase(length: length, minLength: 43, maxLength: 128);

  static String _generateCodeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String _generateRandomBase({required int length, int? minLength, int? maxLength}) {
    if (minLength != null && length < minLength) {
      throw ArgumentError.value(length, 'length', 'must be >= $minLength');
    }
    if (maxLength != null && length > maxLength) {
      throw ArgumentError.value(length, 'length', 'must be <= $maxLength');
    }
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
