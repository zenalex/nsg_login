// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'nsg_login_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class NsgLoginLocalizationsRu extends NsgLoginLocalizations {
  NsgLoginLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get login => 'Войти';

  @override
  String get return_to_login_page => 'Вернуться на страницу входа';

  @override
  String get remember_user => 'Запомнить пользователя';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get enter => 'Вход';

  @override
  String get registration => 'Регистрация';

  @override
  String get enter_code => 'Введите код';

  @override
  String we_sent_you_a_code_via_sms_to_your_phone_number(Object phone) {
    return 'Мы отправили вам код в СМС на номер телефона: $phone';
  }

  @override
  String we_sent_you_the_code_in_a_message_by_email_phone(Object phone) {
    return 'Мы отправили вам код в сообщении на e-mail: $phone';
  }

  @override
  String get code => 'Код';

  @override
  String get enter_your_phone_number => 'Введите номер телефона';

  @override
  String get enter_your_email => 'Введите ваш e-mail';

  @override
  String get enter_your_password => 'Введите ваш пароль';

  @override
  String get enter_new_password => 'Введите новый пароль';

  @override
  String get confirm_password => 'Введите второй раз ваш пароль';

  @override
  String get send_sms_again => 'Отправить СМС заново';

  @override
  String get send_sms => 'Отправить СМС';

  @override
  String get enter_captcha_text => 'Введите текст Капчи';

  @override
  String get successful_login => 'Успешный логин';

  @override
  String get please_enter_a_valid_number => 'Введите корректный номер';

  @override
  String
  get the_request_could_not_be_completed_check_your_internet_connection =>
      'Невозможно выполнить запрос. Проверьте соединение с интернетом.';

  @override
  String get registration_forgot_password => 'Регистрация / Забыл пароль';

  @override
  String get already_registered_login_with_password =>
      'Уже зарегистрирован / Войти по паролю';

  @override
  String get you_have_to_get_captha_first => 'Сначала нужно получить капту';

  @override
  String get captcha_is_obsolet_try_again =>
      'Капча устарела. Попробуйте еще раз!';

  @override
  String get captcha_text_is_wrong_try_again =>
      'Текст капчи неправильный. Попробуйте еще раз!';

  @override
  String get you_have_to_enter_you_phone_number =>
      'Вам необходимо ввести свой номер телефона!';

  @override
  String get you_have_to_enter_captcha_text =>
      'Вам необходимо ввести текст-капчу!';

  @override
  String get wrong_security_code_try_again =>
      'Неправильный код безопасности. Попробуйте еще раз!';

  @override
  String get you_entered_wrong_code_too_many_times =>
      'Вы слишком много раз ввели неверный код!';

  @override
  String get security_code_is_obsolete => 'Код безопасности устарел';

  @override
  String get you_need_to_create_verification_code_again =>
      'Вам необходимо создать код подтверждения еще раз.';

  @override
  String get wrong_user_name_or_password =>
      'Неверное имя пользователя или пароль';

  @override
  String error_statuscode_is_occured(Object statusCode) {
    return 'Произошла ошибка $statusCode';
  }

  @override
  String get phone_number_in_international_format =>
      'Номер телефона в международном формате';

  @override
  String login_via_social(Object social) {
    return 'Войти через $social';
  }

  @override
  String get vk => 'ВК';

  @override
  String authorization_social(Object social) {
    return 'Авторизация: $social';
  }
}
