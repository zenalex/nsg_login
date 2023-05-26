import 'nsgPhoneLoginPage.dart';
import 'nsgPhoneLoginParams.dart';
import 'nsgPhoneLoginRegistrationPage.dart';
import 'nsgPhoneLoginVerificationPage.dart';
import 'nsg_login_provider.dart';

NsgPhoneLoginPage Function(NsgLoginProvider loginProvider)? getLoginWidget;
NsgPhoneLoginPage loginPage(NsgLoginProvider loginProvider) {
  if (getLoginWidget == null) {
    return NsgPhoneLoginPage(loginProvider,
        widgetParams: NsgPhoneLoginParams.defaultParams);
  } else {
    return getLoginWidget!(loginProvider);
  }
}

Function(NsgLoginProvider loginProvider)? getVerificationWidget;
NsgPhoneLoginVerificationPage verificationPage(NsgLoginProvider loginProvider) {
  if (getVerificationWidget == null) {
    return NsgPhoneLoginVerificationPage(loginProvider,
        widgetParams: registrationPage(loginProvider).widgetParams!);
  } else {
    return getVerificationWidget!(loginProvider);
  }
}

Function(NsgLoginProvider loginProvider)? getRegistrationWidget;
NsgPhoneLoginRegistrationPage registrationPage(NsgLoginProvider loginProvider) {
  if (getRegistrationWidget == null) {
    return NsgPhoneLoginRegistrationPage(loginProvider,
        widgetParams: NsgPhoneLoginParams.defaultParams);
  } else {
    return getRegistrationWidget!(loginProvider);
  }
}
