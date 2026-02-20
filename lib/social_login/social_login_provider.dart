import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLoginProvider {
  SocialLoginProvider(this.provider);
  final NsgDataProvider provider;
  Future<bool> processLogin(
    SocialAuthType social, {
    Future<NsgSocialLoginResponse?> Function(String url)? onAuthLink,
  }) async {
    if (social.useNativeAuth) {
      var authResult = await social.performNativeAuth();
      return await processVerify(social, authResult);
    }

    var response = await provider.requestSocialMethod(
      methodName: social.requestMethodName,
      function: social.requestFunction,
      params: social.requestParams,
    );

    if (response.isError) {
      throw Exception(response.errorMessage.isNotEmpty
          ? response.errorMessage
          : 'Authorization request failed');
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
