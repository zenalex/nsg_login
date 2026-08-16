import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/main_login/main_login_type.dart';

class MainLoginProvider {
  MainLoginProvider(this.provider);
  final NsgDataProvider provider;

  Future<NsgLoginResponse> processRequest(MainLoginType mainLogin) async {
    var response = await provider.requestSocialMethod(
      methodName: mainLogin.requestMethodName,
      function: mainLogin.requestFunction,
      params: mainLogin.requestParams,
    );
    if (response.isError) {
      throw Exception(
        response.errorMessage.isNotEmpty
            ? response.errorMessage
            : _failureDetails(mainLogin.requestMethodName, response),
      );
    }
    return response;
  }

  /// Текст отказа, когда сервер не прислал сообщения.
  ///
  /// Раньше здесь была голая строка 'Authorization request failed'. Сервер при
  /// этом возвращает `errorCode`, а метод входа известен из самого запроса — и
  /// то и другое просто выбрасывалось. В GlitchTip копился кластер из
  /// 245 одинаковых событий, по которым нельзя было сказать ни какой вход
  /// сломан, ни почему.
  ///
  /// ⚠️ Текст исключения — это отпечаток группировки: события разойдутся по
  /// методу и коду. Это и нужно — разные отказы перестанут склеиваться в одну
  /// кучу. Старый кластер после раскатки замолчит, новые появятся отдельно.
  static String _failureDetails(String method, NsgLoginResponse response) {
    final where = method.isEmpty ? 'unknown method' : method;
    return 'Authorization request failed ($where, errorCode ${response.errorCode})';
  }

  Future<bool> processLogin(
    MainLoginType mainLogin, {
    BuildContext? context,
    Future<NsgSocialLoginResponse?> Function(String url)? onAuth,
  }) async {
    var response = await processRequest(mainLogin);

    NsgSocialLoginResponse? authLink;
    if (response.errorCode == 0) {
      //TODO: Переход на страницу ввода кода подтверждения
    }

    return await processVerify(mainLogin, authLink);
  }

  Future<bool> processVerify(
    MainLoginType mainLogin,
    NsgSocialLoginResponse? authLink,
  ) async {
    if (authLink != null) {
      var loginResponse = await provider.requestSocialMethod(
        methodName: mainLogin.verifyMethodName,
        function: mainLogin.verifyFunction,
        params: mainLogin.getVerifyParams(authLink),
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
