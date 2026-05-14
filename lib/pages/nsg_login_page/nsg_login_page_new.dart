import 'package:flutter/material.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/nsg_data_provider.dart';
import 'package:nsg_login/nsg_login_params.dart';
import 'package:nsg_login/pages/nsg_login_page/nsg_login_widget_new.dart';

class CallbackFunctionClass {
  void Function()? sendDataPressed;

  void sendData() {
    sendDataPressed?.call();
  }
}

class NsgLoginPageNew extends StatelessWidget {
  final NsgDataProvider provider;
  final NsgLoginParams Function() widgetParams;
  final String? initialEmail;

  NsgLoginPageNew({
    super.key,
    required this.provider,
    required this.widgetParams,
    this.initialEmail,
  });

  final callback = CallbackFunctionClass();

  void sendData() {
    callback.sendData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widgetParams().appbar ?? false) ? getAppBar(context) : null,
      body: Container(
        decoration: BoxDecoration(color: nsgtheme.colorMain.withAlpha(25)),
        child: LoginWidgetNew(
          this,
          provider,
          widgetParams: widgetParams(),
          initialEmail: initialEmail,
        ),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(title: const Text(''), centerTitle: true);
  }

  Widget getLogo() {
    return const Image(
      image: AssetImage('assets/images/logo.png', package: 'nsg_login'),
      width: 140.0,
      height: 140.0,
      alignment: Alignment.center,
    );
  }

  Widget getRememberMeCheckbox() {
    final initialValue = provider.saveToken;
    return NsgCheckBox(
      checkColor: nsgtheme.colorText,
      toggleInside: true,
      simple: true,
      margin: EdgeInsets.zero,
      label: widgetParams().textRememberUser,
      onPressed: (currentValue) {
        provider.saveToken = currentValue;
      },
      value: initialValue,
    );
  }

  Widget getBackground() {
    return const SizedBox.expand();
  }
}
