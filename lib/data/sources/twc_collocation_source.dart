import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/request_envelope.dart';
import '../../core/network/transport/request_executor.dart';
import '../models/collocation_item.dart';
import '../models/jqgrid_response.dart';

class TwcCollocationSource {
  TwcCollocationSource({required RequestExecutor requestExecutor})
    : _requestExecutor = requestExecutor;

  final RequestExecutor _requestExecutor;

  Future<ApiResult<JqGridResponse<CollocationItem>>> fetchCollocations(
    String headwordCollocationId, {
    int page = 1,
    int rows = 100,
  }) {
    final headwordId = headwordCollocationId.split('.').take(2).join('.');
    return _requestExecutor.execute<JqGridResponse<CollocationItem>>(
      RequestEnvelope(
        method: RequestMethod.post,
        path: '${ApiEndpoints.collocation}$headwordCollocationId/',
        formFields: <String, Object?>{
          '_search': true.toString(),
          'nd': DateTime.now().millisecondsSinceEpoch.toString(),
          'rows': rows,
          'page': page,
          'sidx': 'freq',
          'sord': 'desc',
          'totalrows': 20000,
          'headword_collocation_id': headwordCollocationId,
          'search': true.toString(),
        },
        headers: {
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
        },
        responseKind: ResponseKind.json,
      ),
      decode: (raw) {
        final json = raw as Map<String, Object?>;
        final rowsJson = (json['rows'] as List<dynamic>? ?? const []);
        return JqGridResponse<CollocationItem>(
          page: (json['page'] as num?)?.toInt() ?? page,
          total: (json['total'] as num?)?.toInt() ?? 0,
          records: (json['records'] as num?)?.toInt(),
          rows: rowsJson
              .whereType<Map>()
              .map(
                (entry) =>
                    CollocationItem.fromJson(entry.cast<String, Object?>()),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
