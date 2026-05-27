import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path/path.dart' as p;

class CookieStore {
  CookieStore._(this.jar);

  final CookieJar jar;

  factory CookieStore.inMemory() => CookieStore._(CookieJar());

  static Future<CookieStore> persistent({Directory? directory}) async {
    final root = directory ?? Directory.systemTemp;
    final storagePath = p.join(root.path, 'twc_cookie_jar');
    final jar = PersistCookieJar(storage: FileStorage(storagePath));
    return CookieStore._(jar);
  }

  Future<List<Cookie>> loadForRequest(Uri uri) => jar.loadForRequest(uri);

  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) =>
      jar.saveFromResponse(uri, cookies);

  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) =>
      jar.delete(uri, withDomainSharedCookie);
}
