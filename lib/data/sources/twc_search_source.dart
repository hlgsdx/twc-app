import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/parsers/jqgrid_filter_encoder.dart';
import '../../core/network/request_envelope.dart';
import '../../core/network/transport/request_executor.dart';
import '../models/headword_card.dart';
import '../models/jqgrid_response.dart';

class TwcSearchSource {
  TwcSearchSource({
    required RequestExecutor requestExecutor,
    JqGridFilterEncoder? filterEncoder,
  }) : _requestExecutor = requestExecutor,
       _filterEncoder = filterEncoder ?? const JqGridFilterEncoder();

  final RequestExecutor _requestExecutor;
  final JqGridFilterEncoder _filterEncoder;

  Future<ApiResult<JqGridResponse<HeadwordCard>>> fetchHeadwordList({
    required bool search,
    required int page,
    required int rows,
    String? sidx,
    String? sord,
    int? totalRows,
    String? keyword,
  }) {
    final formFields = <String, Object?>{
      '_search': search.toString(),
      'nd': DateTime.now().millisecondsSinceEpoch.toString(),
      'rows': rows,
      'page': page,
      ...?(sidx == null ? null : <String, Object?>{'sidx': sidx}),
      ...?(sord == null ? null : <String, Object?>{'sord': sord}),
      ...?(totalRows == null
          ? null
          : <String, Object?>{'totalrows': totalRows}),
      ...?((keyword == null || keyword.isEmpty)
          ? null
          : <String, Object?>{
              'filters': _filterEncoder.encodeExactHeadword(keyword),
            }),
    };

    return _requestExecutor.execute<JqGridResponse<HeadwordCard>>(
      RequestEnvelope(
        method: RequestMethod.post,
        path: ApiEndpoints.headwordListAll,
        headers: const <String, Object?>{
          'Referer': 'https://tsukubawebcorpus.jp/search/',
        },
        formFields: formFields,
        responseKind: ResponseKind.json,
      ),
      decode: (raw) {
        final json = raw as Map<String, Object?>;
        final rowsJson = (json['rows'] as List<dynamic>? ?? const []);
        return JqGridResponse<HeadwordCard>(
          page: (json['page'] as num?)?.toInt() ?? page,
          total: (json['total'] as num?)?.toInt() ?? 0,
          records: (json['records'] as num?)?.toInt(),
          rows: rowsJson
              .whereType<Map>()
              .map(
                (entry) => HeadwordCard.fromJson(entry.cast<String, Object?>()),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
