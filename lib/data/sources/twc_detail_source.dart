import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/request_envelope.dart';
import '../../core/network/transport/request_executor.dart';
import '../models/headword_detail.dart';
import '../models/jqgrid_response.dart';
import '../models/pattern_group_node.dart';
import '../models/pattern_item.dart';

class TwcDetailSource {
  TwcDetailSource({required RequestExecutor requestExecutor})
    : _requestExecutor = requestExecutor;

  final RequestExecutor _requestExecutor;

  Future<ApiResult<HeadwordDetail>> fetchBasicInfo(String headwordId) {
    return _fetchDetailLike(ApiEndpoints.basicInfo(headwordId), headwordId);
  }

  Future<ApiResult<HeadwordShojikeiView>> fetchBasicInfoSj(
    String headwordId,
  ) {
    return _fetchView<HeadwordShojikeiView>(
      ApiEndpoints.basicInfoSj(headwordId),
      headwordId,
      (raw) => HeadwordShojikeiView.fromJson(raw),
    );
  }

  Future<ApiResult<HeadwordKatuyokeiView>> fetchBasicInfoKy(
    String headwordId,
  ) {
    return _fetchView<HeadwordKatuyokeiView>(
      ApiEndpoints.basicInfoKy(headwordId),
      headwordId,
      (raw) => HeadwordKatuyokeiView.fromJson(raw),
    );
  }

  Future<ApiResult<HeadwordJodoshisetuzokuView>> fetchBasicInfoJs(
    String headwordId,
  ) {
    return _fetchView<HeadwordJodoshisetuzokuView>(
      ApiEndpoints.basicInfoJs(headwordId),
      headwordId,
      (raw) => HeadwordJodoshisetuzokuView.fromJson(raw),
    );
  }

  Future<ApiResult<JqGridResponse<PatternItem>>> fetchPatternFrequencyOrder(
    String headwordId,
  ) {
    return _requestExecutor.execute<JqGridResponse<PatternItem>>(
      RequestEnvelope(
        method: RequestMethod.post,
        path: '${ApiEndpoints.patternFreqOrder}$headwordId/',
        headers: {
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
        },
        formFields: _defaultPagedForm(search: false, totalRows: 20000),
        responseKind: ResponseKind.json,
      ),
      decode: (raw) => _decodePatternItems(raw as Map<String, Object?>),
    );
  }

  Future<ApiResult<JqGridResponse<PatternGroupNode>>> fetchPatternGroup(
    String group,
    String headwordId,
  ) {
    return _requestExecutor.execute<JqGridResponse<PatternGroupNode>>(
      RequestEnvelope(
        method: RequestMethod.post,
        path: ApiEndpoints.patternGroup(group, headwordId),
        headers: {
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
        },
        formFields: _defaultPagedForm(search: false, totalRows: 10000),
        responseKind: ResponseKind.json,
      ),
      decode: (raw) => _decodePatternGroupNodes(raw as Map<String, Object?>),
    );
  }

  Future<ApiResult<HeadwordDetail>> _fetchDetailLike(
    String path,
    String headwordId,
  ) {
    return _fetchView<HeadwordDetail>(
      path,
      headwordId,
      (raw) => HeadwordDetail.fromJson(raw),
    );
  }

  Future<ApiResult<T>> _fetchView<T>(
    String path,
    String headwordId,
    T Function(Map<String, Object?> json) decode,
  ) {
    return _requestExecutor.execute<T>(
      RequestEnvelope(
        method: RequestMethod.get,
        path: path,
        headers: {
          'Accept': '*/*',
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
        },
        responseKind: ResponseKind.json,
      ),
      decode: (raw) => decode((raw as Map).cast<String, Object?>()),
    );
  }

  Map<String, Object?> _defaultPagedForm({
    required bool search,
    required int totalRows,
  }) {
    return <String, Object?>{
      '_search': search.toString(),
      'nd': DateTime.now().millisecondsSinceEpoch.toString(),
      'rows': 100,
      'page': 1,
      'sidx': 'freq',
      'sord': 'desc',
      'totalrows': totalRows,
    };
  }

  JqGridResponse<PatternItem> _decodePatternItems(Map<String, Object?> json) {
    final rowsJson = (json['rows'] as List<dynamic>? ?? const []);
    return JqGridResponse<PatternItem>(
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      records: (json['records'] as num?)?.toInt(),
      rows: rowsJson
          .whereType<Map>()
          .map((entry) => PatternItem.fromJson(entry.cast<String, Object?>()))
          .toList(growable: false),
    );
  }

  JqGridResponse<PatternGroupNode> _decodePatternGroupNodes(
    Map<String, Object?> json,
  ) {
    final rowsJson = (json['rows'] as List<dynamic>? ?? const []);
    return JqGridResponse<PatternGroupNode>(
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      records: (json['records'] as num?)?.toInt(),
      rows: rowsJson
          .whereType<Map>()
          .map(
            (entry) => PatternGroupNode.fromJson(entry.cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }
}
