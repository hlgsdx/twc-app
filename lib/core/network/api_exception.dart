sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ApiTransportException extends ApiException {
  const ApiTransportException({
    required String message,
    required this.uri,
    required this.type,
  }) : super(message);

  final Uri? uri;
  final Object? type;
}

final class ApiHttpException extends ApiException {
  const ApiHttpException({
    required String message,
    required this.statusCode,
    required this.uri,
    this.body,
  }) : super(message);

  final int? statusCode;
  final Uri? uri;
  final Object? body;
}

final class ApiParseException extends ApiException {
  const ApiParseException({required String message, this.cause, this.uri})
    : super(message);

  final Object? cause;
  final Uri? uri;
}

final class ApiProtocolException extends ApiException {
  const ApiProtocolException(super.message);
}
