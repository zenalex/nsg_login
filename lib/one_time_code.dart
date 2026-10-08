import 'package:flutter/services.dart';

/// Длина кода подтверждения: сервер (`AuthSmsDataController.GenerateCode`
/// в NsgServerClasses) выдаёт ровно 6 цифр — и в SMS, и в письме.
const int nsgLoginCodeLength = 6;

/// Подсказка системе «сюда вводят одноразовый код» (NSG-SOFT/futbolista-tasks#3088).
///
/// iOS 17+ и Safari на macOS по ней предлагают над клавиатурой код из
/// пришедшего письма Apple Mail или SMS; на вебе Flutter отдаёт её браузеру
/// как `autocomplete="one-time-code"`. Без подсказки поле для системы —
/// обычный текст, и код приходится переписывать руками.
const List<String> nsgOneTimeCodeAutofillHints = [AutofillHints.oneTimeCode];

/// Поле нового пароля: менеджер паролей предлагает сгенерировать пароль и
/// сохраняет введённый, а не пытается подставить старый.
const List<String> nsgNewPasswordAutofillHints = [AutofillHints.newPassword];

/// Цифровая клавиатура для кода.
const TextInputType nsgOneTimeCodeKeyboardType = TextInputType.number;

/// Только цифры и не длиннее кода: вставка «549 636» или «549636.» из буфера
/// превращается в шесть цифр, а не в ошибку проверки.
List<TextInputFormatter> nsgOneTimeCodeInputFormatters() => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(nsgLoginCodeLength),
];

/// Проверка кода: ровно [nsgLoginCodeLength] цифр.
bool isNsgLoginCodeComplete(String? value) =>
    value != null && RegExp('^\\d{$nsgLoginCodeLength}\$').hasMatch(value);
