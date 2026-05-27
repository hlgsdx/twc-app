import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../api_result.dart';
import '../request_envelope.dart';

class RequestExecutor {
  RequestExecutor(this._dio);

  final Dio _dio;

  Future<ApiResult<T>> execute<T>(
    RequestEnvelope envelope, {
    required T Function(Object? raw) decode,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        envelope.path,
        data: envelope.hasBody ? envelope.formFields : null,
        queryParameters: envelope.queryParameters,
        options: envelope.toOptions(),
      );

      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        return ApiFailure<T>(
          ApiHttpException(
            message: 'Unexpected HTTP status $statusCode',
            statusCode: statusCode,
            uri: response.realUri,
            body: response.data,
          ),
        );
      }

      return ApiSuccess<T>(decode(response.data));
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        return ApiFailure<T>(
          ApiHttpException(
            message: error.message ?? 'HTTP request failed',
            statusCode: response.statusCode,
            uri: response.realUri,
            body: response.data,
          ),
        );
      }

      return ApiFailure<T>(
        ApiTransportException(
          message: error.message ?? 'Transport error',
          uri: error.requestOptions.uri,
          type: error.type,
        ),
      );
    } catch (error) {
      return ApiFailure<T>(
        ApiParseException(message: 'Failed to decode response', cause: error),
      );
    }
  }
}
