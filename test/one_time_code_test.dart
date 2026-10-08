import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/one_time_code.dart';

/// NSG-SOFT/futbolista-tasks#3088: поле кода подтверждения.
TextEditingValue _format(String input) {
  var value = TextEditingValue(
    text: input,
    selection: TextSelection.collapsed(offset: input.length),
  );
  for (final formatter in nsgOneTimeCodeInputFormatters()) {
    value = formatter.formatEditUpdate(TextEditingValue.empty, value);
  }
  return value;
}

void main() {
  test('подсказки: одноразовый код и новый пароль', () {
    expect(nsgOneTimeCodeAutofillHints, [AutofillHints.oneTimeCode]);
    expect(nsgNewPasswordAutofillHints, [AutofillHints.newPassword]);
    expect(nsgOneTimeCodeKeyboardType, TextInputType.number);
  });

  test('вставка кода с пробелами и хвостом сводится к шести цифрам', () {
    expect(_format('549 636').text, '549636');
    expect(_format('549636.').text, '549636');
    expect(_format('5496367').text, '549636');
    expect(_format('код 549-636').text, '549636');
  });

  test('код полон только при ровно шести цифрах', () {
    expect(isNsgLoginCodeComplete('549636'), isTrue);
    expect(isNsgLoginCodeComplete('54963'), isFalse);
    expect(isNsgLoginCodeComplete('5496366'), isFalse);
    expect(isNsgLoginCodeComplete('54963a'), isFalse);
    expect(isNsgLoginCodeComplete(''), isFalse);
    expect(isNsgLoginCodeComplete(null), isFalse);
  });

  // Именно эту конфигурацию движок получает в TextInput.setClient: веб по ней
  // ставит <input autocomplete="one-time-code" name="one-time-code">
  // (flutter_web_sdk: text_editing/autofill_hint.dart, AutofillInfo.applyToDomElement),
  // iOS — textContentType = oneTimeCode.
  testWidgets('поле кода отдаёт движку oneTimeCode и цифровую клавиатуру', (tester) async {
    final configs = <Map<String, dynamic>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (call) async {
      if (call.method == 'TextInput.setClient') {
        configs.add(Map<String, dynamic>.from((call.arguments as List)[1] as Map));
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null));

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  key: const ValueKey('code'),
                  autofillHints: nsgOneTimeCodeAutofillHints,
                  keyboardType: nsgOneTimeCodeKeyboardType,
                  inputFormatters: nsgOneTimeCodeInputFormatters(),
                ),
                TextFormField(obscureText: true, autofillHints: nsgNewPasswordAutofillHints),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('code')));
    await tester.pump();

    expect(configs, isNotEmpty);
    final config = configs.last;
    expect((config['autofill'] as Map)['hints'], ['oneTimeCode']);
    expect((config['inputType'] as Map)['name'], 'TextInputType.number');
    // Группа: код и новый пароль уходят системе одной формой.
    final fields = (config['fields'] as List).cast<Map>();
    final hints = fields.map((f) => (f['autofill'] as Map)['hints']).toList();
    expect(hints, containsAll([
      ['oneTimeCode'],
      ['newPassword'],
    ]));
  });
}
