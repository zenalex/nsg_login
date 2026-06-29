import 'package:nsg_login/social_login/max_auth/max_session.dart';
import 'package:nsg_login/social_login/max_auth/max_user.dart';
import 'package:url_launcher/url_launcher.dart';

class MaxAuth {
  static const _oauthOrigins = <String>[
    'https://oauth.max.ru',
    'https://oauth.mail.ru',
  ];

  final MaxSession _session = MaxSession();
  final String phoneNumber;
  final String botId;
  final String botDomain;
  final String botUsername;
  final Duration timeout;

  MaxUser? _user;

  MaxAuth({
    required this.phoneNumber,
    required this.botId,
    required this.botUsername,
    required this.botDomain,
    this.timeout = const Duration(seconds: 60),
  });

  Future<void> launchMax() async {
    final launchCandidates = <Uri>[
      Uri.parse('https://web.max.ru/$botUsername?startapp=auth'),
      Uri.parse('https://web.max.ru/$botId?startapp=auth'),
      Uri.parse('https://web.max.ru/$botDomain?startapp=auth'),
      Uri.parse('https://web.max.ru'),
    ];

    for (final uri in launchCandidates) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }

    throw Exception('Could not open MAX');
  }

  Future<bool> initiateLogin() async {
    try {
      final cleanedPhone = phoneNumber
          .replaceAll(RegExp(r'\+'), '')
          .replaceAll(RegExp(r' '), '');
      for (final oauthOrigin in _oauthOrigins) {
        final headers = {
          'Content-Type': 'application/x-www-form-urlencoded',
          'origin': oauthOrigin,
        };
        try {
          final response = await _session.post(
            '$oauthOrigin/auth/request?bot_id=$botId&origin=$botDomain&embed=1',
            headers,
            'phone=$cleanedPhone',
          );
          return response.trim().toLowerCase() == 'true';
        } on Exception {
          // Try next OAuth origin if this one is unavailable.
        }
      }
      throw Exception('No available OAuth endpoint');
    } catch (e) {
      throw Exception('Failed to initiate login: $e');
    }
  }

  Future<bool> checkLoginStatus() async {
    try {
      for (final oauthOrigin in _oauthOrigins) {
        final headers = {
          'Content-length': '0',
          'Content-Type': 'application/x-www-form-urlencoded',
          'origin': oauthOrigin,
        };
        try {
          final response = await _session.post(
            '$oauthOrigin/auth/login?bot_id=$botId&origin=$botDomain&embed=1',
            headers,
            '',
          );
          return response.trim().toLowerCase() == 'true';
        } on Exception {
          // Try next OAuth origin if this one is unavailable.
        }
      }
      throw Exception('No available OAuth endpoint');
    } catch (e) {
      throw Exception('Failed to check login status: $e');
    }
  }

  Future<MaxUser?> getUserData() async {
    final isLoggedIn = await checkLoginStatus();
    if (!isLoggedIn) {
      final loginSuccess = await initiateLogin();
      if (!loginSuccess) {
        throw Exception('Re-authentication failed');
      }
    }

    try {
      var response = '';
      String? activeOauthOrigin;
      for (final oauthOrigin in _oauthOrigins) {
        try {
          response = await _session.get(
            '$oauthOrigin/auth?bot_id=$botId&origin=$botDomain&embed=1',
            {},
          );
          activeOauthOrigin = oauthOrigin;
          break;
        } on Exception {
          // Try next OAuth origin if this one is unavailable.
        }
      }
      if (activeOauthOrigin == null) {
        throw Exception('No available OAuth endpoint');
      }

      if (response.contains(
        'postMessage(JSON.stringify({event: \'auth_result\'',
      )) {
        final regex = RegExp(r'result: ({.*}), origin');
        final match = regex.firstMatch(response);

        if (match == null) {
          throw Exception('Failed to extract JSON data');
        }

        final jsonString = match.group(1)!;
        final userData = _parseUserData(jsonString);
        _user = MaxUser.fromJson(userData);
        return _user;
      }

      final confirmUrl = _extractConfirmUrl(response);
      if (confirmUrl == null) {
        throw Exception('Failed to extract confirm_url');
      }

      final confirmResponse = await _session.get(
        '$activeOauthOrigin$confirmUrl',
        {},
      );

      final confirmRegex = RegExp(r'result: ({.*}), origin');
      final confirmMatch = confirmRegex.firstMatch(confirmResponse);

      if (confirmMatch == null) {
        throw Exception('Failed to extract JSON data after confirmation');
      }

      final confirmJsonString = confirmMatch.group(1)!;
      final userData = _parseUserData(confirmJsonString);
      _user = MaxUser.fromJson(userData);
      return _user;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Map<String, dynamic> _parseUserData(String jsonString) {
    final userData = <String, dynamic>{};

    final idMatch = RegExp(r'"id":\s*"?(\d+)"?').firstMatch(jsonString);
    final firstNameMatch = RegExp(
      r'"first_name":\s*"(.*?)"',
    ).firstMatch(jsonString);
    final lastNameMatch = RegExp(
      r'"last_name":\s*"(.*?)"',
    ).firstMatch(jsonString);
    final usernameMatch = RegExp(
      r'"username":\s*"(.*?)"',
    ).firstMatch(jsonString);
    final photoUrlMatch = RegExp(
      r'"photo_url":\s*"(.*?)"',
    ).firstMatch(jsonString);
    final authDateMatch = RegExp(
      r'"auth_date":\s*"?(\d+)"?',
    ).firstMatch(jsonString);
    final hashMatch = RegExp(r'"hash":\s*"(.*?)"').firstMatch(jsonString);

    userData['id'] = idMatch?.group(1) ?? '';
    userData['first_name'] = firstNameMatch?.group(1) ?? '';
    userData['last_name'] = lastNameMatch?.group(1) ?? '';
    userData['username'] = usernameMatch?.group(1) ?? '';
    userData['photo_url'] = photoUrlMatch?.group(1) ?? '';
    userData['auth_date'] = authDateMatch?.group(1) ?? '';
    userData['hash'] = hashMatch?.group(1) ?? '';
    userData['raw_json'] = jsonString;

    return userData;
  }

  String? _extractConfirmUrl(String htmlResponse) {
    final match = RegExp(
      r"function confirmRequest[\s\S]*?confirm_url\s*=\s*'([^']+)'",
    ).firstMatch(htmlResponse);
    return match?.group(1);
  }
}
