import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:url_launcher/url_launcher.dart';

class NsgSocialLoginWidget extends StatefulWidget {
  final NsgDataProvider provider;
  const NsgSocialLoginWidget({super.key, required this.provider});

  static WebViewEnvironment? webViewEnvironment;

  /// Инициализация WebView, необходимо выполнять при инициализации приложения
  static void init() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();
      assert(
        availableVersion != null,
        'Failed to find an installed WebView2 Runtime or non-stable Microsoft Edge installation.',
      );

      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(),
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
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

  @override
  void initState() {
    super.initState();

    assert(NsgSocialLoginWidget.webViewEnvironment != null);

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
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                webViewEnvironment: NsgSocialLoginWidget.webViewEnvironment,
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.provider.socialLoginUrl),
                ),
                initialSettings: settings,
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                  });
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
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
                  setState(() {
                    this.url = url.toString();
                  });
                },
                onReceivedError: (controller, request, error) {
                  pullToRefreshController?.endRefreshing();
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    pullToRefreshController?.endRefreshing();
                  }
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  if (url != null) {
                    widget.provider.socialLoginResponse.fromJson(
                      url.queryParameters,
                    );
                    if (widget.provider.socialLoginResponse.isEmpty != true) {
                      NsgNavigator.pop();
                      if (widget.provider.onVerifySocialLogin != null) {
                        widget.provider.onVerifySocialLogin!();
                      }
                    }
                  }

                  setState(() {
                    this.url = url.toString();
                  });
                },
                onConsoleMessage: (controller, consoleMessage) {
                  if (kDebugMode) {
                    print(consoleMessage);
                  }
                },
              ),
              progress < 1.0
                  ? LinearProgressIndicator(value: progress)
                  : Container(),
            ],
          ),
        ),
      ],
    );
  }
}
