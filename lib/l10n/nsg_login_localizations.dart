import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'nsg_login_localizations_en.dart';
import 'nsg_login_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of NsgLoginLocalizations
/// returned by `NsgLoginLocalizations.of(context)`.
///
/// Applications need to include `NsgLoginLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/nsg_login_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: NsgLoginLocalizations.localizationsDelegates,
///   supportedLocales: NsgLoginLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the NsgLoginLocalizations.supportedLocales
/// property.
abstract class NsgLoginLocalizations {
  NsgLoginLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static NsgLoginLocalizations? of(BuildContext context) {
    return Localizations.of<NsgLoginLocalizations>(
      context,
      NsgLoginLocalizations,
    );
  }

  static const LocalizationsDelegate<NsgLoginLocalizations> delegate =
      _NsgLoginLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @return_to_login_page.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться на страницу входа'**
  String get return_to_login_page;

  /// No description provided for @remember_user.
  ///
  /// In ru, this message translates to:
  /// **'Запомнить пользователя'**
  String get remember_user;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @enter.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get enter;

  /// No description provided for @registration.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registration;

  /// No description provided for @enter_code.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get enter_code;

  /// No description provided for @we_sent_you_a_code_via_sms_to_your_phone_number.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили вам код в СМС на номер телефона: {phone}'**
  String we_sent_you_a_code_via_sms_to_your_phone_number(Object phone);

  /// No description provided for @we_sent_you_the_code_in_a_message_by_email_phone.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили вам код в сообщении на e-mail: {phone}'**
  String we_sent_you_the_code_in_a_message_by_email_phone(Object phone);

  /// No description provided for @code.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get code;

  /// No description provided for @enter_your_phone_number.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get enter_your_phone_number;

  /// No description provided for @enter_your_email.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваш e-mail'**
  String get enter_your_email;

  /// No description provided for @enter_your_password.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваш пароль'**
  String get enter_your_password;

  /// No description provided for @enter_new_password.
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get enter_new_password;

  /// No description provided for @confirm_password.
  ///
  /// In ru, this message translates to:
  /// **'Введите второй раз ваш пароль'**
  String get confirm_password;

  /// No description provided for @send_sms_again.
  ///
  /// In ru, this message translates to:
  /// **'Отправить СМС заново'**
  String get send_sms_again;

  /// No description provided for @send_sms.
  ///
  /// In ru, this message translates to:
  /// **'Отправить СМС'**
  String get send_sms;

  /// No description provided for @enter_captcha_text.
  ///
  /// In ru, this message translates to:
  /// **'Введите текст Капчи'**
  String get enter_captcha_text;

  /// No description provided for @successful_login.
  ///
  /// In ru, this message translates to:
  /// **'Успешный логин'**
  String get successful_login;

  /// No description provided for @please_enter_a_valid_number.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный номер'**
  String get please_enter_a_valid_number;

  /// No description provided for @the_request_could_not_be_completed_check_your_internet_connection.
  ///
  /// In ru, this message translates to:
  /// **'Невозможно выполнить запрос. Проверьте соединение с интернетом.'**
  String get the_request_could_not_be_completed_check_your_internet_connection;

  /// No description provided for @registration_forgot_password.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация / Забыл пароль'**
  String get registration_forgot_password;

  /// No description provided for @already_registered_login_with_password.
  ///
  /// In ru, this message translates to:
  /// **'Уже зарегистрирован / Войти по паролю'**
  String get already_registered_login_with_password;

  /// No description provided for @you_have_to_get_captha_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала нужно получить капту'**
  String get you_have_to_get_captha_first;

  /// No description provided for @captcha_is_obsolet_try_again.
  ///
  /// In ru, this message translates to:
  /// **'Капча устарела. Попробуйте еще раз!'**
  String get captcha_is_obsolet_try_again;

  /// No description provided for @captcha_text_is_wrong_try_again.
  ///
  /// In ru, this message translates to:
  /// **'Текст капчи неправильный. Попробуйте еще раз!'**
  String get captcha_text_is_wrong_try_again;

  /// No description provided for @you_have_to_enter_you_phone_number.
  ///
  /// In ru, this message translates to:
  /// **'Вам необходимо ввести свой номер телефона!'**
  String get you_have_to_enter_you_phone_number;

  /// No description provided for @you_have_to_enter_captcha_text.
  ///
  /// In ru, this message translates to:
  /// **'Вам необходимо ввести текст-капчу!'**
  String get you_have_to_enter_captcha_text;

  /// No description provided for @wrong_security_code_try_again.
  ///
  /// In ru, this message translates to:
  /// **'Неправильный код безопасности. Попробуйте еще раз!'**
  String get wrong_security_code_try_again;

  /// No description provided for @you_entered_wrong_code_too_many_times.
  ///
  /// In ru, this message translates to:
  /// **'Вы слишком много раз ввели неверный код!'**
  String get you_entered_wrong_code_too_many_times;

  /// No description provided for @security_code_is_obsolete.
  ///
  /// In ru, this message translates to:
  /// **'Код безопасности устарел'**
  String get security_code_is_obsolete;

  /// No description provided for @you_need_to_create_verification_code_again.
  ///
  /// In ru, this message translates to:
  /// **'Вам необходимо создать код подтверждения еще раз.'**
  String get you_need_to_create_verification_code_again;

  /// No description provided for @wrong_user_name_or_password.
  ///
  /// In ru, this message translates to:
  /// **'Неверное имя пользователя или пароль'**
  String get wrong_user_name_or_password;

  /// No description provided for @error_statuscode_is_occured.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка {statusCode}'**
  String error_statuscode_is_occured(Object statusCode);

  /// No description provided for @phone_number_in_international_format.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона в международном формате'**
  String get phone_number_in_international_format;

  /// No description provided for @login_via_social.
  ///
  /// In ru, this message translates to:
  /// **'Войти через {social}'**
  String login_via_social(Object social);

  /// No description provided for @vk.
  ///
  /// In ru, this message translates to:
  /// **'ВК'**
  String get vk;

  /// No description provided for @authorization_social.
  ///
  /// In ru, this message translates to:
  /// **'Авторизация: {social}'**
  String authorization_social(Object social);
}

class _NsgLoginLocalizationsDelegate
    extends LocalizationsDelegate<NsgLoginLocalizations> {
  const _NsgLoginLocalizationsDelegate();

  @override
  Future<NsgLoginLocalizations> load(Locale locale) {
    return SynchronousFuture<NsgLoginLocalizations>(
      lookupNsgLoginLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_NsgLoginLocalizationsDelegate old) => false;
}

NsgLoginLocalizations lookupNsgLoginLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return NsgLoginLocalizationsEn();
    case 'ru':
      return NsgLoginLocalizationsRu();
  }

  throw FlutterError(
    'NsgLoginLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
