import 'package:flutter/material.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/metrica/nsg_metrica.dart';
import 'package:nsg_data/navigator/nsg_navigator.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/nsg_login_params.dart';
import 'package:nsg_login/pages/nsg_login_state.dart';

class LoginWidgetNewController extends ChangeNotifier {
  LoginWidgetNewController(this.widgetParams, this.provider);

  final NsgLoginParams widgetParams;
  final NsgDataProvider provider;

  NsgLoginState _currentState = NsgLoginState.login;

  NsgLoginState get currentState => _currentState;

  set currentState(NsgLoginState state) {
    if (_currentState == state) return;
    _currentState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkRequestSMSanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    //0 - успешно, 40201 - смс отправлено ранее. И в том и другом случае, переходим на экран ввода кода подтверждения
    if ((answerCode.errorCode == 0 || answerCode.errorCode == 40201) &&
        (currentState == NsgLoginState.registration ||
            currentState == NsgLoginState.login)) {
      if (currentState == NsgLoginState.registration ||
          widgetParams.usePasswordLogin) {
        currentState = NsgLoginState.verification;
      } else {
        //isLoginSuccessfull = true;
      }
      //Если мы перешли на экран с ошибкой смс уже отправлено, выводим ошибку на экран после перехода на страницу подтверждения
      if (answerCode.errorCode != 0) {
        var errorMessage = widgetParams.errorMessageByStatusCode!(
          answerCode.errorCode,
        );
        widgetParams.showError(context, errorMessage);
        // widget.widgetParams.showError(context, answerCode.errorMessage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && widgetParams.usePasswordLogin) {
      NsgMetrica.reportLoginSuccess('Phone');
      if (widgetParams.onLogin != null) {
        widgetParams.onLogin!();
      } else {
        NsgNavigator.instance.offAndToPage(widgetParams.mainPage);
      }
      return;
    }
    if (answerCode.errorCode == 0 && !widgetParams.usePasswordLogin) {
      return;
    }
    var needRefreshCaptcha = false;
    var errorMessage = widgetParams.errorMessageByStatusCode!(
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
    widgetParams.showError(context, errorMessage);

    if (needRefreshCaptcha) {
      //refreshCaptcha();
    }
  }

  ///Установить новый пароль пользователя
  ///securityCode - код верификации, полученный на предыдущем этапе
  ///loginType - тип логина (телефон/емаил)
  ///newPassword - новый (устанавливаемый) пароль
  // Future setNewPassword(
  //   BuildContext context, {
  //   required String securityCode,
  //   required NsgLoginType loginType,
  //   required String newPassword,
  // }) async {
  //   if (!formKey.currentState!.validate()) return;
  //   provider
  //       .phoneLogin(
  //         phoneNumber: loginType == NsgLoginType.phone ? phoneNumber : email,
  //         securityCode: securityCode,
  //         register: true,
  //         newPassword: newPassword,
  //       )
  //       // ignore: use_build_context_synchronously
  //       .then((value) => checkRequestNewPasswordanswer(context, value))
  //       .catchError((e) {
  //         if (context.mounted) {
  //           widgetParams.showError(context, widgetParams.textCheckInternet);
  //         }
  //       });
  // }

  ///Проверка результата попытки установить новый пароль пользователя фукцией setNewPassword
  ///answerCode - проверяемый код ответа
  void checkRequestNewPasswordanswer(
    BuildContext? context,
    NsgLoginResponse answerCode,
  ) {
    //Код ноль - пароль установлен успешно, переходим на страницу приложения
    if (answerCode.errorCode == 0) {
      NsgMetrica.reportLoginSuccess('Phone');
      if (widgetParams.eventLoginWidgweClosed != null) {
        widgetParams.eventLoginWidgweClosed!(true);
      }
      if (widgetParams.onLogin != null) {
        widgetParams.onLogin!();
      } else {
        NsgNavigator.instance.offAndToPage(widgetParams.mainPage);
      }
      return;
    }
    //Если код ответа отличен от нуля - это ошибка, расшифровываем её и показываем пользователю
    //TODO_FUTURE: проверить остались ли еще попытки ввода кода подтверждения или требуется новый.
    var errorMessage = widgetParams.errorMessageByStatusCode!(
      answerCode.errorCode,
    );
    NsgMetrica.reportLoginFailed('Phone', answerCode.toString());
    widgetParams.showError(context, errorMessage);
  }
}
