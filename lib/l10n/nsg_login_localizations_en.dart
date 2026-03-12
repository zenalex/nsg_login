// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'nsg_login_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NsgLoginLocalizationsEn extends NsgLoginLocalizations {
  NsgLoginLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get return_to_login_page => 'Return to login page';

  @override
  String get remember_user => 'Remember user';

  @override
  String get confirm => 'Confirm';

  @override
  String get enter => 'Enter';

  @override
  String get registration => 'Registration';

  @override
  String get enter_code => 'Enter code';

  @override
  String we_sent_you_a_code_via_sms_to_your_phone_number(Object phone) {
    return 'We sent you a code via SMS to your phone number: $phone';
  }

  @override
  String we_sent_you_the_code_in_a_message_by_email_phone(Object phone) {
    return 'We sent you the code in a message by e-mail: $phone';
  }

  @override
  String get code => 'Code';

  @override
  String get enter_your_phone_number => 'Enter your phone number';

  @override
  String get enter_your_email => 'Enter your email';

  @override
  String get enter_your_password => 'Enter your password';

  @override
  String get enter_new_password => 'Enter new password';

  @override
  String get confirm_password => 'Confirm password';

  @override
  String get send_sms_again => 'Send SMS again';

  @override
  String get send_sms => 'Send SMS';

  @override
  String get enter_captcha_text => 'Enter Captcha text';

  @override
  String get successful_login => 'Successful login';

  @override
  String get please_enter_a_valid_number => 'Please enter a valid number';

  @override
  String
  get the_request_could_not_be_completed_check_your_internet_connection =>
      'The request could not be completed. Check your internet connection.';

  @override
  String get registration_forgot_password => 'Registration / Forgot password';

  @override
  String get already_registered_login_with_password =>
      'Already registered / Login with password';

  @override
  String get you_have_to_get_captha_first => 'You have to get captha first';

  @override
  String get captcha_is_obsolet_try_again => 'Captcha is obsolet. Try again!';

  @override
  String get captcha_text_is_wrong_try_again =>
      'Captcha text is wrong. Try again!';

  @override
  String get you_have_to_enter_you_phone_number =>
      'You have to enter you phone number!';

  @override
  String get you_have_to_enter_captcha_text =>
      'You have to enter captcha text!';

  @override
  String get wrong_security_code_try_again => 'Wrong security code. Try again!';

  @override
  String get you_entered_wrong_code_too_many_times =>
      'You entered wrong code too many times!';

  @override
  String get security_code_is_obsolete => 'Security code is obsolete';

  @override
  String get you_need_to_create_verification_code_again =>
      'You need to create verification code again';

  @override
  String get wrong_user_name_or_password => 'Wrong user name or password';

  @override
  String error_statuscode_is_occured(Object statusCode) {
    return 'Error $statusCode is occured';
  }

  @override
  String get phone_number_in_international_format =>
      'Phone number in international format';

  @override
  String login_via_social(Object social) {
    return 'Login via $social';
  }

  @override
  String get vk => 'VK';

  @override
  String authorization_social(Object social) {
    return 'Authorization: $social';
  }
}
