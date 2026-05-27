import 'package:dio/dio.dart';

enum RequestMethod { get, post }

enum ResponseKind { json, html, text }

class RequestEnvelope {
  const RequestEnvelope({
    required this.method,
    required this.path,
    this.queryParameters = const <String, Object?>{},
    this.formFields = const <String, Object?>{},
    this.headers = const <String, Object?>{},
    this.responseKind = ResponseKind.json,
    this.contentType,
    this.extra = const <String, Object?>{},
  });

  final RequestMethod method;
  final String path;
  final Map<String, Object?> queryParameters;
  final Map<String, Object?> formFields;
  final Map<String, Object?> headers;
  final ResponseKind responseKind;
  final String? contentType;
  final Map<String, Object?> extra;

  bool get hasBody => formFields.isNotEmpty;

  Options toOptions() {
    return Options(
      method: switch (method) {
        RequestMethod.get => 'GET',
        RequestMethod.post => 'POST',
      },
      headers: headers.map((key, value) => MapEntry(key, value)),
      responseType: switch (responseKind) {
        ResponseKind.json => ResponseType.json,
        ResponseKind.html || ResponseKind.text => ResponseType.plain,
      },
      contentType:
          contentType ??
          (hasBody
              ? '${Headers.formUrlEncodedContentType}; charset=UTF-8'
              : null),
      extra: extra.map((key, value) => MapEntry(key, value)),
    );
  }
}
