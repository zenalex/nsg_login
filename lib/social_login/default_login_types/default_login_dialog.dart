import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';
import 'package:nsg_controls/dialog/nsg_future_progress_exception.dart';
import 'package:nsg_controls/nsg_button.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_login/helpers.dart';

class DefaultSocialLoginDialog extends StatelessWidget {
  const DefaultSocialLoginDialog({
    super.key,
    this.title,
    this.logo,
    this.buttonText,
    required this.onButtonPressed,
    this.onAuthError,
    this.phoneController,
    this.showPhoneInput = true,
    this.inputDecoration,
    this.cursorColor,
  });

  final String? title;
  final String? buttonText;
  final Widget? logo;
  final bool showPhoneInput;
  final TextEditingController? phoneController;
  final FutureOr<void> Function(String phoneNumber) onButtonPressed;
  final void Function(dynamic error)? onAuthError;
  final InputDecoration? inputDecoration;
  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    var localPhoneController = phoneController ?? TextEditingController();
    return DefaultSocialLoginDialogBody(
      inputDecoration: inputDecoration,
      title: title,
      logo: logo,
      body: NsgButton(
        margin: const EdgeInsets.only(top: 4),
        text: buttonText,
        onPressed: () async {
          await nsgFutureProgressAndException(
            func: () async {
              try {
                await onButtonPressed(localPhoneController.text);
              } catch (e) {
                if (onAuthError != null) {
                  onAuthError!(e);
                } else {
                  rethrow;
                }
              }
            },
          );
        },
      ),
      phoneController: localPhoneController,
    );
  }
}

class DefaultSocialLoginDialogBody extends StatelessWidget {
  const DefaultSocialLoginDialogBody({
    super.key,
    this.title,
    this.logo,
    this.showPhoneInput = true,
    required this.body,
    required this.phoneController,
    this.inputDecoration,
    this.cursorColor,
  });

  final String? title;
  final Widget? logo;
  final bool showPhoneInput;
  final Widget body;
  final InputDecoration? inputDecoration;
  final TextEditingController phoneController;
  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    final inputDecorationBase =
        inputDecoration ??
        InputDecoration(
          contentPadding: const EdgeInsets.all(10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
            borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
            borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
            borderSide: BorderSide(color: nsgtheme.colorText, width: 1.0),
          ),
          filled: true,
          fillColor: nsgtheme.colorBase.b0,
          errorStyle: const TextStyle(fontSize: 12),
          hintStyle: TextStyle(color: nsgtheme.colorText.withAlpha(75)),
        );

    return Container(
      decoration: BoxDecoration(color: nsgtheme.colorMainBack, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              if (logo != null)
                Padding(
                  padding: const EdgeInsetsGeometry.only(top: 10, bottom: 20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [logo!]),
                ),
              Row(
                children: [
                  if (logo == null) Text(title ?? tran.login),
                  const Expanded(child: SizedBox()),
                  InkWell(
                    child: Icon(Icons.close, color: nsgtheme.colorTertiary.withAlpha(127)),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          Text(
            tran.enter_your_phone_number,
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
          ),
          if (showPhoneInput) const SizedBox(height: 12),
          if (showPhoneInput)
            TextFormField(
              controller: phoneController,
              cursorColor: cursorColor ?? nsgtheme.colorPrimary,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              style: TextStyle(color: nsgtheme.colorText),
              textAlign: TextAlign.center,
              decoration: inputDecorationBase.copyWith(hintText: tran.phone_number_in_international_format),
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }
}

class SocialLoginDialog {
  static FutureOr<T?> show<T>(BuildContext context, {required Widget Function(BuildContext dialogContext) builder}) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        constraints: const BoxConstraints(maxWidth: 400),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: builder(dialogContext),
      ),
    );
  }
}
