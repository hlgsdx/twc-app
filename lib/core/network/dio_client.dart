import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'api_endpoints.dart';
import 'cookie/cookie_store.dart';
import 'csrf/csrf_interceptor.dart';
import 'csrf/csrf_manager.dart';
import 'interceptors/auth_header_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  DioClient._(this.dio, this.cookieStore);

  final Dio dio;
  final CookieStore cookieStore;

  static Future<DioClient> create({
    CookieStore? cookieStore,
    bool enableLogging = false,
  }) async {
    final store = cookieStore ?? CookieStore.inMemory();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUri.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const <String, Object?>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );

    final csrfManager = CsrfManager(store);
    dio.interceptors.addAll([
      CookieManager(store.jar),
      const AuthHeaderInterceptor(),
      CsrfInterceptor(csrfManager),
      if (enableLogging) const LoggingInterceptor(),
    ]);

    return DioClient._(dio, store);
  }
}
