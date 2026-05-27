import 'package:dio/dio.dart';

import 'csrf_manager.dart';

class CsrfInterceptor extends Interceptor {
  CsrfInterceptor(this._csrfManager);

  final CsrfManager _csrfManager;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipCsrfHeader'] == true) {
      handler.next(options);
      return;
    }
    var token = _csrfManager.token;
    if (token == null || token.isEmpty) {
      final uri = options.uri;
      await _csrfManager.refresh(uri);
      token = _csrfManager.token;
    }
    if (token != null && token.isNotEmpty) {
      options.headers.putIfAbsent('X-CSRFToken', () => token);
    }
    handler.next(options);
  }
}
