import 'package:cookie_jar/cookie_jar.dart';

import '../cookie/cookie_store.dart';

class CsrfManager {
  CsrfManager(this._cookieStore);

  final CookieStore _cookieStore;
  String? _token;
  bool _consentAccepted = false;

  String? get token => _token;
  bool get hasConsent => _consentAccepted;

  Future<void> refresh(Uri uri) async {
    final cookies = await _cookieStore.loadForRequest(uri);
    _token = _readCookie(cookies, 'csrftoken');
    _consentAccepted = _readCookie(cookies, 'agreed') == 'true';
  }

  Future<void> seedFromCookies(Uri uri, List<Cookie> cookies) async {
    await _cookieStore.saveFromResponse(uri, cookies);
    _token = _readCookie(cookies, 'csrftoken');
    _consentAccepted = _readCookie(cookies, 'agreed') == 'true';
    if (_token == null) {
      await refresh(uri);
    }
  }

  String? _readCookie(List<Cookie> cookies, String name) {
    for (final cookie in cookies) {
      if (cookie.name == name) {
        return cookie.value;
      }
    }
    return null;
  }
}
