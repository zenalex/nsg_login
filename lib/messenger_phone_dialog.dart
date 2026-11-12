import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nsg_login/messenger_phone_flow.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

class MessengerPhoneDialogText {
  const MessengerPhoneDialogText({
    required this.registerTitle,
    required this.recoveryTitle,
    required this.steps,
    required this.recoverySteps,
    required this.phoneHint,
    required this.invalidPhone,
    required this.waiting,
    required this.openAgain,
    required this.chooseOther,
    required this.cancel,
    this.enterCode = 'Ввести код',
    this.telegram = 'Telegram',
    this.max = 'MAX',
    this.unavailable =
        'Сейчас подтвердить номер не получается. Попробуйте ещё раз.',
  });

  final String registerTitle;
  final String recoveryTitle;
  final String steps;
  final String recoverySteps;
  final String phoneHint;
  final String invalidPhone;
  final String waiting;
  final String openAgain;
  final String chooseOther;
  final String cancel;
  final String enterCode;
  final String telegram;
  final String max;
  final String unavailable;
}

/// Диалог подтверждения номера. Кнопки мессенджера — тот же [SocialLoginButton],
/// что вход на экране логина. Отказ Begin/Poll остаётся текстом в диалоге.
class MessengerPhoneDialog extends StatefulWidget {
  const MessengerPhoneDialog({
    super.key,
    required this.intent,
    required this.text,
    required this.begin,
    required this.poll,
    required this.errorText,
    this.recovery,
    this.openUrl,
    this.phoneValid,
  });

  final MessengerPhoneIntent intent;
  final MessengerPhoneDialogText text;
  final Future<MessengerPhoneBeginResult> Function(String phone, String channel)
  begin;
  final Future<MessengerPhonePollResult> Function(
    String payload,
    bool Function() cancelled,
  )
  poll;
  final Future<MessengerPhoneRecoveryResult> Function(
    String phone,
    String channel,
  )?
  recovery;
  final String Function(int code) errorText;
  final Future<void> Function(String url)? openUrl;
  final bool Function(String phone)? phoneValid;

  @override
  State<MessengerPhoneDialog> createState() => _MessengerPhoneDialogState();
}

class _MessengerPhoneDialogState extends State<MessengerPhoneDialog> {
  final _phone = TextEditingController();
  final _phoneFormatter = PhoneInputFormatter();
  var _generation = 0;
  var _waiting = false;
  var _beginInFlight = false;
  String? _url;
  String? _error;
  String? _recoveryMessage;

  @override
  void dispose() {
    _generation++;
    _phone.dispose();
    super.dispose();
  }

  bool _cancelled(int generation) => !mounted || generation != _generation;

  bool _phoneOk(String value) {
    final check = widget.phoneValid;
    if (check != null) return check(value);
    return isPhoneValid(value) && value.length >= 9;
  }

  String _failure(int code) {
    final message = widget.errorText(code).trim();
    if (message.isNotEmpty) return message;
    return widget.text.unavailable;
  }

  Future<void> _choose(String channel) async {
    if (_waiting || _beginInFlight) return;
    final phone = _phone.text.trim();
    if (!_phoneOk(phone)) {
      setState(() => _error = widget.text.invalidPhone);
      return;
    }
    final generation = ++_generation;
    setState(() {
      _beginInFlight = true;
      _error = null;
    });
    if (widget.intent == MessengerPhoneIntent.recovery) {
      await _recover(phone, channel, generation);
      return;
    }
    await _access(phone, channel, generation);
  }

  Future<void> _recover(String phone, String channel, int generation) async {
    final request = widget.recovery;
    if (request == null) {
      if (_cancelled(generation)) return;
      setState(() {
        _beginInFlight = false;
        _error = widget.text.unavailable;
      });
      return;
    }
    MessengerPhoneRecoveryResult result;
    try {
      result = await request(phone, channel);
    } catch (_) {
      if (_cancelled(generation)) return;
      setState(() {
        _beginInFlight = false;
        _error = widget.text.unavailable;
      });
      return;
    }
    if (_cancelled(generation)) return;
    final url = result.url;
    if (url != null && messengerPhoneUrlAllowed(url)) {
      setState(() {
        _beginInFlight = false;
        _waiting = true;
        _url = url;
        _recoveryMessage = result.message;
        _error = null;
      });
      try {
        await widget.openUrl?.call(url);
      } catch (_) {
        if (_cancelled(generation)) return;
        setState(() => _error = widget.text.unavailable);
      }
      return;
    }
    if (mounted) {
      Navigator.of(
        context,
      ).pop(MessengerPhoneDialogOutcome.recovery(phone, result.message));
    }
  }

  void _enterCode() {
    final phone = _phone.text.trim();
    final message = _recoveryMessage;
    if (message == null) return;
    Navigator.of(
      context,
    ).pop(MessengerPhoneDialogOutcome.recovery(phone, message));
  }

  Future<void> _access(String phone, String channel, int generation) async {
    MessengerPhoneBeginResult begin;
    try {
      begin = await widget.begin(phone, channel);
    } catch (_) {
      begin = const MessengerPhoneBeginResult(errorCode: 50301);
    }
    if (_cancelled(generation)) return;
    if (!begin.ok || !messengerPhoneUrlAllowed(begin.url)) {
      setState(() {
        _beginInFlight = false;
        _error = _failure(begin.errorCode == 0 ? 50301 : begin.errorCode);
      });
      return;
    }
    setState(() {
      _beginInFlight = false;
      _waiting = true;
      _url = begin.url;
      _error = null;
    });
    try {
      await widget.openUrl?.call(begin.url);
    } catch (_) {
      if (_cancelled(generation)) return;
      setState(() => _error = widget.text.unavailable);
    }
    if (_cancelled(generation)) return;
    MessengerPhonePollResult poll;
    try {
      poll = await widget.poll(begin.payload, () => _cancelled(generation));
    } catch (_) {
      poll = const MessengerPhonePollResult(errorCode: 50301);
    }
    if (_cancelled(generation) || poll.cancelled) return;
    if (poll.confirmed) {
      if (mounted) {
        Navigator.of(context).pop(MessengerPhoneDialogOutcome.access(phone));
      }
      return;
    }
    setState(() {
      _waiting = false;
      _url = null;
      _error = _failure(poll.errorCode == 0 ? 50301 : poll.errorCode);
    });
  }

  void _stopWaiting() {
    _generation++;
    setState(() {
      _waiting = false;
      _beginInFlight = false;
      _url = null;
      _error = null;
    });
  }

  void _close() {
    _generation++;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final title = widget.intent == MessengerPhoneIntent.recovery
        ? text.recoveryTitle
        : text.registerTitle;
    final steps = widget.intent == MessengerPhoneIntent.recovery
        ? text.recoverySteps
        : text.steps;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            key: const ValueKey('messengerPhone.dialog'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(steps),
                const SizedBox(height: 12),
                if (_waiting) ...[
                  Text(
                    text.waiting,
                    key: const ValueKey('messengerPhone.waiting'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, key: const ValueKey('messengerPhone.error')),
                  ],
                  const SizedBox(height: 12),
                  if (widget.intent == MessengerPhoneIntent.recovery)
                    OutlinedButton(
                      key: const ValueKey('messengerPhone.enterCode'),
                      onPressed: _enterCode,
                      child: Text(text.enterCode),
                    ),
                  if (widget.intent == MessengerPhoneIntent.recovery)
                    const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('messengerPhone.openAgain'),
                    onPressed: _url == null
                        ? null
                        : () => widget.openUrl?.call(_url!),
                    child: Text(text.openAgain),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('messengerPhone.other'),
                    onPressed: _stopWaiting,
                    child: Text(text.chooseOther),
                  ),
                ] else ...[
                  TextFormField(
                    key: const ValueKey('messengerPhone.phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                    decoration: InputDecoration(hintText: text.phoneHint),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, key: const ValueKey('messengerPhone.error')),
                  ],
                  if (_beginInFlight) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox(
                        key: ValueKey('messengerPhone.begin'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: SocialLoginButton(
                      key: const ValueKey('messengerPhone.telegram'),
                      onTap: _beginInFlight ? () {} : () => _choose('telegram'),
                      logo: _brandIcon(_telegramSvg, 'Telegram'),
                      buttonText: text.telegram,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: SocialLoginButton(
                      key: const ValueKey('messengerPhone.max'),
                      onTap: _beginInFlight ? () {} : () => _choose('max'),
                      logo: _brandIcon(_maxSvg, 'MAX'),
                      buttonText: text.max,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('messengerPhone.cancel'),
                  onPressed: _close,
                  child: Text(text.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _brandIcon(String svg, String label) =>
    SvgPicture.string(svg, width: 20, height: 20, semanticsLabel: label);

const _telegramSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240.1 240.1">'
    '<linearGradient id="tgPhoneGrad" gradientUnits="userSpaceOnUse" x1="-838.041" y1="660.581" x2="-838.041" y2="660.3427" gradientTransform="matrix(1000 0 0 -1000 838161 660581)">'
    '<stop offset="0" stop-color="#2AABEE"/><stop offset="1" stop-color="#229ED9"/>'
    '</linearGradient>'
    '<circle fill="url(#tgPhoneGrad)" cx="120.1" cy="120.1" r="120.1"/>'
    '<path fill="#FFFFFF" d="M54.3,118.8c35-15.2,58.3-25.3,70-30.2c33.3-13.9,40.3-16.3,44.8-16.4c1,0,3.2,0.2,4.7,1.4c1.2,1,1.5,2.3,1.7,3.3s0.4,3.1,0.2,4.7c-1.8,19-9.6,65.1-13.6,86.3c-1.7,9-5,12-8.2,12.3c-7,0.6-12.3-4.6-19-9c-10.6-6.9-16.5-11.2-26.8-18c-11.9-7.8-4.2-12.1,2.6-19.1c1.8-1.8,32.5-29.8,33.1-32.3c0.1-0.3,0.1-1.5-0.6-2.1c-0.7-0.6-1.7-0.4-2.5-0.2c-1.1,0.2-17.9,11.4-50.6,33.5c-4.8,3.3-9.1,4.9-13,4.8c-4.3-0.1-12.5-2.4-18.7-4.4c-7.5-2.4-13.5-3.7-13-7.9C45.7,123.3,48.7,121.1,54.3,118.8z"/>'
    '</svg>';

const _maxSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">'
    '<defs>'
    '<linearGradient id="maxPhoneB"><stop offset="0" stop-color="#00f"/><stop offset="1" stop-opacity="0"/></linearGradient>'
    '<linearGradient id="maxPhoneA"><stop offset="0" stop-color="#4cf"/><stop offset=".662" stop-color="#53e"/><stop offset="1" stop-color="#93d"/></linearGradient>'
    '<linearGradient id="maxPhoneC" x1="117.847" x2="1000" y1="760.536" y2="500" gradientUnits="userSpaceOnUse" href="#maxPhoneA"/>'
    '<radialGradient id="maxPhoneD" cx="-87.392" cy="1166.116" r="500" fx="-87.392" fy="1166.116" gradientTransform="rotate(51.356 1551.478 559.3) scale(2.42703 1)" gradientUnits="userSpaceOnUse" href="#maxPhoneB"/>'
    '</defs>'
    '<rect width="1000" height="1000" fill="url(#maxPhoneC)" ry="249.681"/>'
    '<rect width="1000" height="1000" fill="url(#maxPhoneD)" ry="249.681"/>'
    '<path fill="#fff" d="M508.211 878.328c-75.007 0-109.864-10.95-170.453-54.75-38.325 49.275-159.686 87.783-164.979 21.9 0-49.456-10.95-91.248-23.36-136.873-14.782-56.21-31.572-118.807-31.572-209.508 0-216.626 177.754-379.597 388.357-379.597 210.785 0 375.947 171.001 375.947 381.604.707 207.346-166.595 376.118-373.94 377.224m3.103-571.585c-102.564-5.292-182.499 65.7-200.201 177.024-14.6 92.162 11.315 204.398 33.397 210.238 10.585 2.555 37.23-18.98 53.837-35.587a189.8 189.8 0 0 0 92.71 33.032c106.273 5.112 197.08-75.794 204.215-181.95 4.154-106.382-77.67-196.486-183.958-202.574Z"/>'
    '</svg>';
