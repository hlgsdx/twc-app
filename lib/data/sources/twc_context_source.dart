import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/request_envelope.dart';
import '../../core/network/transport/request_executor.dart';

class TwcContextSource {
  TwcContextSource({required RequestExecutor requestExecutor})
    : _requestExecutor = requestExecutor;

  final RequestExecutor _requestExecutor;

  Future<ApiResult<String>> fetchContextHtml({
    required String fileId,
    required int sentenceNo,
  }) {
    return _requestExecutor.execute<String>(
      RequestEnvelope(
        method: RequestMethod.get,
        path: ApiEndpoints.contextByLocation(fileId, sentenceNo),
        headers: const <String, Object?>{
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        },
        responseKind: ResponseKind.html,
        extra: const <String, Object?>{
          'skipDefaultHeaders': true,
          'skipCsrfHeader': true,
        },
      ),
      decode: (raw) => raw?.toString() ?? '',
    );
  }
}
