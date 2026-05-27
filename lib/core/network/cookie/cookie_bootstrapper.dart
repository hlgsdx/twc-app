import 'package:dio/dio.dart';

import '../api_endpoints.dart';
import 'cookie_store.dart';

class CookieBootstrapper {
  CookieBootstrapper({required Dio dio, required CookieStore cookieStore})
    : _dio = dio,
      _cookieStore = cookieStore;

  final Dio _dio;
  final CookieStore _cookieStore;

  Future<void> bootstrap({Uri? uri}) async {
    final target = uri ?? ApiEndpoints.searchUri;
    await _dio.getUri<dynamic>(
      target,
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, Object?>{
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Upgrade-Insecure-Requests': '1',
        },
        extra: const <String, Object?>{
          'skipDefaultHeaders': true,
          'skipCsrfHeader': true,
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    await _cookieStore.loadForRequest(target);
  }
}
