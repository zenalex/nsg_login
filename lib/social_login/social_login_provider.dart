import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/social_login/social_login_exception.dart';
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
      // Типизированное исключение вместо голого Exception: вызывающая сторона
      // должна отличать «покажи человеку сообщение» от «это дефект».
      // До правки 403-геоблок и обрыв связи оба приезжали в трекер как fatal,
      // хотя чинить в коде нечего ни в том, ни в другом случае (#1594).
      throw NsgSocialLoginException(
        message: response.errorMessage.isNotEmpty
            ? response.errorMessage
            : _failureDetails(social.requestMethodName, response),
        method: social.requestMethodName,
        code: response.errorCode,
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

  /// Проверка результата на нашем сервере — общий финал ОБОИХ путей входа.
  ///
  /// ⚠️ Сюда приходят и нативные способы (Apple, Telegram, MAX, VK-app), а их
  /// больше нигде не подхватывают: `useNativeAuth == true` уводит их мимо
  /// ветки с запросом ссылки в [processLogin]. Поэтому отказ, не показанный
  /// здесь, не показывается пользователю нигде.
  ///
  /// Раньше здесь на любой отказ стояло `return false`, и виджет на `false` не
  /// делает ничего: ни сообщения, ни записи в трекер. Вход через Apple в РФ
  /// выглядел как «кнопка не работает» — сервер при этом отвечал внятным 403
  /// «Авторизация Apple недоступна в РФ. Выберите другой способ», а вход через
  /// Telegram точно так же молча гас, и причина не доезжала вообще никуда.
  Future<bool> processVerify(
    SocialAuthType social,
    NsgSocialLoginResponse? authLink,
  ) async {
    // Пользователь закрыл окно соцсети или не подтвердил вход. Это отмена, а не
    // отказ: показывать нечего, и раньше, и сейчас — молча выходим.
    if (authLink == null) return false;

    var loginResponse = await provider.requestSocialMethod(
      methodName: social.verifyMethodName,
      function: social.verifyFunction,
      params: social.getVerifyParams(authLink),
    );

    if (loginResponse.errorCode == 0 && !loginResponse.isAnonymous) {
      return true;
    }

    // Симметрично [processLogin]: несём наверх код и текст сервера. Штатный
    // отказ (403 — не пустил осознанно, 0 — не ответил) вызывающая сторона
    // покажет и погасит, остальное уедет в трекер как дефект.
    throw NsgSocialLoginException(
      message: loginResponse.errorMessage.isNotEmpty
          ? loginResponse.errorMessage
          : _verifyFailureDetails(social.verifyMethodName, loginResponse),
      method: social.verifyMethodName,
      code: loginResponse.errorCode,
    );
  }

  /// Текст, когда сервер отказал, но объяснения не прислал.
  ///
  /// Отдельный от [_failureDetails] случай: `errorCode == 0` при анонимном
  /// ответе — это не «сервер не ответил», а «ответил успехом, но сессии нет».
  /// Кода у такого отказа нет, поэтому по [NsgSocialLoginException.isExpected]
  /// он пройдёт как штатный: пользователь увидит текст, в трекер не улетит.
  /// Так и задумано — гадать, дефект это или осознанный отказ сервера, здесь
  /// не на чем, а заваливать трекер догадками мы уже пробовали (#1594).
  static String _verifyFailureDetails(
    String method,
    NsgLoginResponse response,
  ) {
    final where = method.isEmpty ? 'unknown method' : method;
    if (response.errorCode == 0) {
      return 'Authorization verify returned anonymous session ($where)';
    }
    return 'Authorization verify failed ($where, errorCode ${response.errorCode})';
  }
}
