import '../../core/network/api_endpoints.dart';
import '../../core/network/cookie/cookie_bootstrapper.dart';

class TwcSessionSource {
  TwcSessionSource({required CookieBootstrapper cookieBootstrapper})
    : _cookieBootstrapper = cookieBootstrapper;

  final CookieBootstrapper _cookieBootstrapper;

  Future<void> bootstrap() {
    return _cookieBootstrapper.bootstrap(uri: ApiEndpoints.searchUri);
  }
}
