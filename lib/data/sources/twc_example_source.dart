import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/request_envelope.dart';
import '../../core/network/transport/request_executor.dart';
import '../models/example_item.dart';
import '../models/jqgrid_response.dart';

class TwcExampleSource {
  TwcExampleSource({required RequestExecutor requestExecutor})
    : _requestExecutor = requestExecutor;

  final RequestExecutor _requestExecutor;

  Future<ApiResult<JqGridResponse<ExampleItem>>> fetchExamples(
    String headwordCollocationId,
    String collocationId, {
    int page = 1,
    int rows = 100,
  }) {
    final normalizedCollocationId = _normalizeCollocationId(collocationId);
    final headwordId = headwordCollocationId.split('.').take(2).join('.');
    return _requestExecutor.execute<JqGridResponse<ExampleItem>>(
      RequestEnvelope(
        method: RequestMethod.post,
        path:
            '${ApiEndpoints.example}$headwordCollocationId.$normalizedCollocationId/',
        formFields: <String, Object?>{
          '_search': false.toString(),
          'nd': DateTime.now().millisecondsSinceEpoch.toString(),
          'rows': rows,
          'page': page,
          'sidx': '',
          'sord': 'desc',
          'totalrows': 20000,
          'headword_collocation_id':
              '$headwordCollocationId.$normalizedCollocationId',
        },
        headers: {
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
        },
        responseKind: ResponseKind.json,
      ),
      decode: (raw) {
        final json = raw as Map<String, Object?>;
        final rowsJson = (json['rows'] as List<dynamic>? ?? const []);
        return JqGridResponse<ExampleItem>(
          page: (json['page'] as num?)?.toInt() ?? page,
          total: (json['total'] as num?)?.toInt() ?? 0,
          records: (json['records'] as num?)?.toInt(),
          rows: rowsJson
              .whereType<Map>()
              .map(
                (entry) => ExampleItem.fromJson(entry.cast<String, Object?>()),
              )
              .toList(growable: false),
        );
      },
    );
  }

  String _normalizeCollocationId(String collocationId) {
    final parts = collocationId.split('.');
    return parts.isEmpty ? collocationId : parts.last;
  }
}
