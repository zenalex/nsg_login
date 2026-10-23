import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class NsgSocialLoginWidget extends StatefulWidget {
  /// Ссылка на авторизацию после request
  final String authUrl;

  /// Коллбек, где нужно вызвать верификацию авторизации
  final Future<void> Function(NsgSocialLoginResponse response) onVerify;
  const NsgSocialLoginWidget({
    super.key,
    required this.authUrl,
    required this.onVerify,
    this.externalLauncher,
  });

  final Future<bool> Function(Uri)? externalLauncher;
  static WebViewEnvironment? webViewEnvironment;
  static String? initializationFailureStage;
  static Future<bool>? _initialization;

  /// Optional capability: missing Runtime/plugin must not abort application boot.
  /// The returned Future includes all platform work; no async-void errors escape.
  static Future<bool> init({
    Future<String?> Function()? availableVersion,
    Future<WebViewEnvironment> Function()? createEnvironment,
    void Function(Object, StackTrace)? onError,
  }) => _initialization = _initialize(
    availableVersion: availableVersion,
    createEnvironment: createEnvironment,
    onError: onError,
  );

  static Future<bool> _initialize({
    Future<String?> Function()? availableVersion,
    Future<WebViewEnvironment> Function()? createEnvironment,
    void Function(Object, StackTrace)? onError,
  }) async {
    var stage = 'platform';
    initializationFailureStage = null;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        webViewEnvironment = null;
        stage = 'available_version';
        final version =
            await (availableVersion ?? WebViewEnvironment.getAvailableVersion)()
                .timeout(const Duration(seconds: 8));
        if (version == null || version.trim().isEmpty) {
          stage = 'runtime_missing';
          throw StateError('WebView2 Runtime unavailable');
        }
        stage = 'create_environment';
        webViewEnvironment =
            await (createEnvironment ??
                    () => WebViewEnvironment.create(
                      settings: WebViewEnvironmentSettings(),
                    ))()
                .timeout(const Duration(seconds: 8));
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        stage = 'android_debugging';
        await InAppWebViewController.setWebContentsDebuggingEnabled(
          kDebugMode,
        ).timeout(const Duration(seconds: 8));
      }
      return true;
    } catch (error, stack) {
      webViewEnvironment = null;
      initializationFailureStage = stage;
      // A reporting failure must not become a boot failure either.
      try {
        onError?.call(error, stack);
      } catch (_) {}
      return false;
    }
  }

  @override
  State<NsgSocialLoginWidget> createState() => _NsgSocialLoginWidgetState();
}

class _NsgSocialLoginWidgetState extends State<NsgSocialLoginWidget> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;

  bool isVerified = false;
  bool _preparingWindows =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  bool _external = false;
  bool _openingExternal = false;
  bool _externalFailed = false;

  Future<void> _prepareWindows() async {
    final ready =
        await (NsgSocialLoginWidget._initialization ??
            NsgSocialLoginWidget.init());
    if (!mounted) return;
    setState(() {
      _preparingWindows = false;
      _external = !ready || NsgSocialLoginWidget.webViewEnvironment == null;
    });
    if (_external) await _openExternal();
  }

  Future<void> _openExternal() async {
    if (_openingExternal) return;
    setState(() => _openingExternal = true);
    var opened = false;
    try {
      final uri = Uri.parse(widget.authUrl);
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        opened =
            await (widget.externalLauncher ??
                (value) => launchUrl(
                  value,
                  mode: LaunchMode.externalApplication,
                ))(uri);
      }
    } catch (_) {
      // The auth URL can contain credentials; never print launcher errors.
    }
    if (mounted) {
      setState(() {
        _openingExternal = false;
        _externalFailed = !opened;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_preparingWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareWindows());
    }

    pullToRefreshController =
        kIsWeb ||
            ![
              TargetPlatform.iOS,
              TargetPlatform.android,
            ].contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(color: Colors.blue),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_preparingWindows) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_external) {
      final t = NsgLoginLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_externalFailed) Text(t.try_another_login_method),
            TextButton.icon(
              key: const ValueKey('social-external-browser'),
              onPressed: _openingExternal ? null : _openExternal,
              icon: const Icon(Icons.open_in_browser),
              label: Text(t.enter),
            ),
            if (_openingExternal) const CircularProgressIndicator(),
          ],
        ),
      );
    }
    return InAppWebView(
      key: webViewKey,
      webViewEnvironment: NsgSocialLoginWidget.webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(widget.authUrl)),
      initialSettings: settings,
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        if (context.mounted) {
          setState(() {
            this.url = url.toString();
          });
        }
      },
      onPermissionRequest: (controller, request) async {
        return PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        );
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        var uri = navigationAction.request.url!;

        if (![
          // "http",
          "https",
          // "file",
          // "chrome",
          // "data",
          // "javascript",
          // "about",
        ].contains(uri.scheme)) {
          if (await canLaunchUrl(uri)) {
            // Launch the App
            await launchUrl(uri);
            // and cancel the request
            return NavigationActionPolicy.CANCEL;
          }
        }

        return NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) async {
        pullToRefreshController?.endRefreshing();
        if (context.mounted) {
          setState(() {
            this.url = url.toString();
          });
        }
      },
      onReceivedError: (controller, request, error) {
        pullToRefreshController?.endRefreshing();
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          pullToRefreshController?.endRefreshing();
        }
        if (context.mounted) {
          setState(() {
            this.progress = progress / 100;
          });
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        if (url != null) {
          final uri = Uri.parse(url.toString());
          final queryParams = uri.queryParameters;
          final fragmentParams = uri.fragment.isNotEmpty
              ? Uri.splitQueryString(uri.fragment)
              : <String, String>{};
          final params = queryParams.isNotEmpty ? queryParams : fragmentParams;
          var response = NsgSocialLoginResponse()..fromJson(params);
          if (kDebugMode) {
            debugPrint(
              '[NsgSocialLogin] callback url=${uri.origin}${uri.path}',
            );
            debugPrint(
              '[NsgSocialLogin] hasQuery=${queryParams.isNotEmpty} hasFragment=${fragmentParams.isNotEmpty} code=${response.code.isNotEmpty} state=${response.state.isNotEmpty} isEmpty=${response.isEmpty}',
            );
          }
          if (response.isEmpty != true && !isVerified) {
            isVerified = true;
            await widget.onVerify(response);
            if (context.mounted) Navigator.pop(context);
          }
        }
        if (context.mounted) {
          setState(() {
            this.url = url.toString();
          });
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (kDebugMode) {
          print(consoleMessage);
        }
      },
    );
  }
}
