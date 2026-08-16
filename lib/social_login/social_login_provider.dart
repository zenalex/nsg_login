import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLoginProvider {
  SocialLoginProvider(this.provider);
  final NsgDataProvider provider;

  /// Текст отказа, когда сервер не прислал сообщения.
  ///
  /// Раньше здесь была голая строка 'Authorization request failed'. Сервер при
  /// этом возвращает `errorCode`, а метод входа известен из самого запроса — и
  /// то и другое просто выбрасывалось. В GlitchTip копился кластер из
  /// 245 событий (с 28.06, продолжается), по которым нельзя было сказать ни
  /// какой вход сломан, ни почему.
  ///
  /// Сюда доходит только НЕ нативный путь: у Apple, MAX, Telegram и обычного VK
  /// `useNativeAuth == true`, и они уходят выше. Практически весь кластер —
  /// VK ID, единственный тип с `useNativeAuth == false`.
  ///
  /// ⚠️ Текст исключения — это отпечаток группировки: события разойдутся по
  /// методу и коду. Это и нужно — разные отказы перестанут склеиваться в одну
  /// кучу. Старый кластер после раскатки замолчит, новые появятся отдельно.
  static String _failureDetails(String method, NsgLoginResponse response) {
    final where = method.isEmpty ? 'unknown method' : method;
    return 'Authorization request failed ($where, errorCode ${response.errorCode})';
  }
  Future<bool> processLogin(
    SocialAuthType social, {
    BuildContext? context,
    Future<NsgSocialLoginResponse?> Function(String url)? onAuthLink,
  }) async {
    if (social.useNativeAuth) {
      var authResult = await social.performNativeAuth(
        context: context,
        provider: provider,
      );
      return await processVerify(social, authResult);
    }

    var response = await provider.requestSocialMethod(
      methodName: social.requestMethodName,
      function: social.requestFunction,
      params: social.requestParams,
    );

    if (response.isError) {
      throw Exception(
        response.errorMessage.isNotEmpty
            ? response.errorMessage
            : _failureDetails(social.requestMethodName, response),
      );
    }

    NsgSocialLoginResponse? authLink;
    if (response.errorMessage.startsWith('https://')) {
      var url = response.errorMessage;
      if (onAuthLink != null) {
        authLink = await onAuthLink(url);
      } else {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }

    return await processVerify(social, authLink);
  }

  Future<bool> processVerify(
    SocialAuthType social,
    NsgSocialLoginResponse? authLink,
  ) async {
    if (authLink != null) {
      var loginResponse = await provider.requestSocialMethod(
        methodName: social.verifyMethodName,
        function: social.verifyFunction,
        params: social.getVerifyParams(authLink),
      );

      if (loginResponse.errorCode == 0 && !loginResponse.isAnonymous) {
        return true;
      }

      return false;
    } else {
      return false;
    }
  }
}
