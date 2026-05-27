import '../../core/network/api_exception.dart';
import '../../core/network/api_result.dart';
import '../../core/network/parsers/html_fragment_parser.dart';
import '../models/collocation_item.dart';
import '../models/context_snippet.dart';
import '../models/example_item.dart';
import '../models/headword_card.dart';
import '../models/headword_detail.dart';
import '../models/jqgrid_response.dart';
import '../models/pattern_group_node.dart';
import '../models/pattern_item.dart';
import '../sources/twc_collocation_source.dart';
import '../sources/twc_context_source.dart';
import '../sources/twc_detail_source.dart';
import '../sources/twc_example_source.dart';
import '../sources/twc_search_source.dart';
import '../sources/twc_session_source.dart';

abstract class TwcRepository {
  Future<void> bootstrapSession();

  Future<ApiResult<JqGridResponse<HeadwordCard>>> fetchHeadwordPage({
    required int page,
    required int rows,
  });

  Future<ApiResult<JqGridResponse<HeadwordCard>>> searchHeadwords({
    required String keyword,
    required int page,
    required int rows,
  });

  Future<ApiResult<HeadwordDetail>> fetchBasicInfo(String headwordId);

  Future<ApiResult<HeadwordShojikeiView>> fetchBasicInfoSj(String headwordId);

  Future<ApiResult<HeadwordKatuyokeiView>> fetchBasicInfoKy(String headwordId);

  Future<ApiResult<HeadwordJodoshisetuzokuView>> fetchBasicInfoJs(
    String headwordId,
  );

  Future<ApiResult<JqGridResponse<PatternItem>>> fetchPatternFrequencyOrder(
    String headwordId,
  );

  Future<ApiResult<JqGridResponse<PatternGroupNode>>> fetchPatternGroup(
    String group,
    String headwordId,
  );

  Future<ApiResult<HeadwordDetailBundle>> fetchHeadwordDetail(
    String headwordId,
  );

  Future<ApiResult<JqGridResponse<CollocationItem>>> fetchCollocations(
    String headwordCollocationId, {
    int page,
    int rows,
  });

  Future<ApiResult<JqGridResponse<ExampleItem>>> fetchExamples(
    String headwordCollocationId,
    String collocationId, {
    int page,
    int rows,
  });

  Future<ApiResult<List<ContextSnippet>>> fetchContext({
    required String fileId,
    required int sentenceNo,
    String? targetSentenceId,
  });
}

class RemoteTwcRepository implements TwcRepository {
  RemoteTwcRepository({
    required TwcSessionSource sessionSource,
    required TwcSearchSource searchSource,
    required TwcDetailSource detailSource,
    required TwcCollocationSource collocationSource,
    required TwcExampleSource exampleSource,
    required TwcContextSource contextSource,
  }) : _sessionSource = sessionSource,
       _searchSource = searchSource,
       _detailSource = detailSource,
       _collocationSource = collocationSource,
       _exampleSource = exampleSource,
       _contextSource = contextSource;

  final TwcSessionSource _sessionSource;
  final TwcSearchSource _searchSource;
  final TwcDetailSource _detailSource;
  final TwcCollocationSource _collocationSource;
  final TwcExampleSource _exampleSource;
  final TwcContextSource _contextSource;
  final HtmlFragmentParser _contextParser = const HtmlFragmentParser();

  @override
  Future<void> bootstrapSession() => _sessionSource.bootstrap();

  @override
  Future<ApiResult<JqGridResponse<HeadwordCard>>> fetchHeadwordPage({
    required int page,
    required int rows,
  }) {
    return _searchSource.fetchHeadwordList(
      search: true,
      page: page,
      rows: rows,
      sidx: 'freq',
      sord: 'desc',
      totalRows: 100000,
    );
  }

  @override
  Future<ApiResult<JqGridResponse<HeadwordCard>>> searchHeadwords({
    required String keyword,
    required int page,
    required int rows,
  }) {
    return _searchSource.fetchHeadwordList(
      search: true,
      page: page,
      rows: rows,
      sidx: 'freq',
      sord: 'desc',
      totalRows: 100000,
      keyword: keyword,
    );
  }

  @override
  Future<ApiResult<HeadwordDetail>> fetchBasicInfo(String headwordId) {
    return _detailSource.fetchBasicInfo(headwordId);
  }

  @override
  Future<ApiResult<HeadwordShojikeiView>> fetchBasicInfoSj(String headwordId) {
    return _detailSource.fetchBasicInfoSj(headwordId);
  }

  @override
  Future<ApiResult<HeadwordKatuyokeiView>> fetchBasicInfoKy(String headwordId) {
    return _detailSource.fetchBasicInfoKy(headwordId);
  }

  @override
  Future<ApiResult<HeadwordJodoshisetuzokuView>> fetchBasicInfoJs(
    String headwordId,
  ) {
    return _detailSource.fetchBasicInfoJs(headwordId);
  }

  @override
  Future<ApiResult<JqGridResponse<PatternItem>>> fetchPatternFrequencyOrder(
    String headwordId,
  ) {
    return _detailSource.fetchPatternFrequencyOrder(headwordId);
  }

  @override
  Future<ApiResult<JqGridResponse<PatternGroupNode>>> fetchPatternGroup(
    String group,
    String headwordId,
  ) {
    return _detailSource.fetchPatternGroup(group, headwordId);
  }

  @override
  Future<ApiResult<HeadwordDetailBundle>> fetchHeadwordDetail(
    String headwordId,
  ) async {
    final basicInfoFuture = fetchBasicInfo(headwordId);
    final shojikeiFuture = _detailSource.fetchBasicInfoSj(headwordId);
    final katuyokeiFuture = _detailSource.fetchBasicInfoKy(headwordId);
    final jodoshisetuzokuFuture = _detailSource.fetchBasicInfoJs(headwordId);
    final patternFreqFuture = fetchPatternFrequencyOrder(headwordId);

    const groups = ['a', 'b', 'c', 'e', 'f', 'g', 'h', 'i', 'j', 'z'];
    final groupFutures = {
      for (final group in groups) group: fetchPatternGroup(group, headwordId),
    };

    final issues = <ApiException>[];

    final basicInfoResult = await basicInfoFuture;
    final basicInfo = basicInfoResult.fold((data) => data, (error) {
      issues.add(error);
      return null;
    });

    final views = HeadwordDetailViews(
      shojikei: await _unwrapDetailView(shojikeiFuture, issues),
      katuyokei: await _unwrapDetailView(katuyokeiFuture, issues),
      jodoshisetuzoku: await _unwrapDetailView(jodoshisetuzokuFuture, issues),
    );

    final patternFrequencyResult = await patternFreqFuture;
    final patternFrequency = patternFrequencyResult.fold((data) => data.rows, (
      error,
    ) {
      issues.add(error);
      return <PatternItem>[];
    });

    final patternGroups = <String, List<PatternGroupNode>>{};
    for (final entry in groupFutures.entries) {
      final result = await entry.value;
      result.fold(
        (data) => patternGroups[entry.key] = data.rows,
        (error) => issues.add(error),
      );
    }

    return ApiSuccess(
      HeadwordDetailBundle(
        headwordId: headwordId,
        basicInfo: basicInfo,
        basicInfoViews: views,
        patternFrequency: patternFrequency,
        patternGroups: patternGroups,
        issues: issues,
      ),
    );
  }

  Future<T?> _unwrapDetailView<T>(
    Future<ApiResult<T>> future,
    List<ApiException> issues,
  ) async {
    final result = await future;
    return result.fold((data) => data, (error) {
      issues.add(error);
      return null;
    });
  }

  @override
  Future<ApiResult<JqGridResponse<CollocationItem>>> fetchCollocations(
    String headwordCollocationId, {
    int page = 1,
    int rows = 100,
  }) {
    return _collocationSource.fetchCollocations(
      headwordCollocationId,
      page: page,
      rows: rows,
    );
  }

  @override
  Future<ApiResult<JqGridResponse<ExampleItem>>> fetchExamples(
    String headwordCollocationId,
    String collocationId, {
    int page = 1,
    int rows = 100,
  }) {
    return _exampleSource.fetchExamples(
      headwordCollocationId,
      collocationId,
      page: page,
      rows: rows,
    );
  }

  @override
  Future<ApiResult<List<ContextSnippet>>> fetchContext({
    required String fileId,
    required int sentenceNo,
    String? targetSentenceId,
  }) async {
    final result = await _contextSource.fetchContextHtml(
      fileId: fileId,
      sentenceNo: sentenceNo,
    );
    return result.fold(
      (html) => ApiSuccess(
        _contextParser.parseContext(
          html,
          targetSentenceId: targetSentenceId ?? 'S$sentenceNo',
        ),
      ),
      ApiFailure<List<ContextSnippet>>.new,
    );
  }
}
