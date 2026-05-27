import 'package:dio/dio.dart';

class AuthHeaderInterceptor extends Interceptor {
  const AuthHeaderInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['skipDefaultHeaders'] == true) {
      handler.next(options);
      return;
    }
    options.headers.putIfAbsent('X-Requested-With', () => 'XMLHttpRequest');
    options.headers.putIfAbsent(
      'Accept',
      () => 'application/json, text/javascript, */*; q=0.01',
    );
    handler.next(options);
  }
}
