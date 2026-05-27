import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/api_result.dart';
import '../../data/models/headword_detail.dart';
import '../../data/models/jqgrid_response.dart';
import '../../data/models/pattern_group_node.dart';
import '../../data/models/pattern_item.dart';
import '../../data/repositories/twc_repository.dart';

const List<String> kDetailPatternGroups = <String>[
  'a',
  'b',
  'c',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'z',
];

String detailPatternGroupLabel(String group) {
  return switch (group) {
    'a' => '名詞＋助詞',
    'b' => '名詞＋複合助詞',
    'c' => '名詞関連',
    'e' => '助動詞',
    'f' => '複合動詞',
    'g' => '近接動詞',
    'h' => '形容詞',
    'i' => '副詞',
    'j' => '形容詞連用形',
    'z' => '未分類',
    _ => group,
  };
}

class HeadwordDetailState {
  const HeadwordDetailState({
    required this.headwordId,
    required this.selectedTabIndex,
    required this.isBasicInfoLoading,
    required this.isShojikeiLoading,
    required this.isKatuyokeiLoading,
    required this.isJodoshisetuzokuLoading,
    required this.isPatternFrequencyLoading,
    required this.groupSections,
    this.basicInfo,
    this.basicInfoError,
    this.shojikei,
    this.shojikeiError,
    this.katuyokei,
    this.katuyokeiError,
    this.jodoshisetuzoku,
    this.jodoshisetuzokuError,
    this.patternFrequency = const <PatternItem>[],
    this.patternFrequencyError,
  });

  factory HeadwordDetailState.initial(String headwordId) {
    return HeadwordDetailState(
      headwordId: headwordId,
      selectedTabIndex: 0,
      isBasicInfoLoading: true,
      isShojikeiLoading: true,
      isKatuyokeiLoading: true,
      isJodoshisetuzokuLoading: true,
      isPatternFrequencyLoading: true,
      groupSections: {
        for (final group in kDetailPatternGroups)
          group: PatternGroupSectionState.initial(group),
      },
    );
  }

  final String headwordId;
  final int selectedTabIndex;
  final bool isBasicInfoLoading;
  final bool isShojikeiLoading;
  final bool isKatuyokeiLoading;
  final bool isJodoshisetuzokuLoading;
  final bool isPatternFrequencyLoading;
  final HeadwordDetail? basicInfo;
  final String? basicInfoError;
  final HeadwordShojikeiView? shojikei;
  final String? shojikeiError;
  final HeadwordKatuyokeiView? katuyokei;
  final String? katuyokeiError;
  final HeadwordJodoshisetuzokuView? jodoshisetuzoku;
  final String? jodoshisetuzokuError;
  final List<PatternItem> patternFrequency;
  final String? patternFrequencyError;
  final Map<String, PatternGroupSectionState> groupSections;

  bool get hasSummaryData =>
      basicInfo != null ||
      patternFrequency.isNotEmpty ||
      shojikei != null ||
      katuyokei != null ||
      jodoshisetuzoku != null;

  HeadwordDetailState copyWith({
    String? headwordId,
    int? selectedTabIndex,
    bool? isBasicInfoLoading,
    bool? isShojikeiLoading,
    bool? isKatuyokeiLoading,
    bool? isJodoshisetuzokuLoading,
    bool? isPatternFrequencyLoading,
    HeadwordDetail? basicInfo,
    bool clearBasicInfo = false,
    String? basicInfoError,
    bool clearBasicInfoError = false,
    HeadwordShojikeiView? shojikei,
    bool clearShojikei = false,
    String? shojikeiError,
    bool clearShojikeiError = false,
    HeadwordKatuyokeiView? katuyokei,
    bool clearKatuyokei = false,
    String? katuyokeiError,
    bool clearKatuyokeiError = false,
    HeadwordJodoshisetuzokuView? jodoshisetuzoku,
    bool clearJodoshisetuzoku = false,
    String? jodoshisetuzokuError,
    bool clearJodoshisetuzokuError = false,
    List<PatternItem>? patternFrequency,
    String? patternFrequencyError,
    bool clearPatternFrequencyError = false,
    Map<String, PatternGroupSectionState>? groupSections,
  }) {
    return HeadwordDetailState(
      headwordId: headwordId ?? this.headwordId,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isBasicInfoLoading: isBasicInfoLoading ?? this.isBasicInfoLoading,
      isShojikeiLoading: isShojikeiLoading ?? this.isShojikeiLoading,
      isKatuyokeiLoading: isKatuyokeiLoading ?? this.isKatuyokeiLoading,
      isJodoshisetuzokuLoading:
          isJodoshisetuzokuLoading ?? this.isJodoshisetuzokuLoading,
      isPatternFrequencyLoading:
          isPatternFrequencyLoading ?? this.isPatternFrequencyLoading,
      basicInfo: clearBasicInfo ? null : basicInfo ?? this.basicInfo,
      basicInfoError: clearBasicInfoError
          ? null
          : basicInfoError ?? this.basicInfoError,
      shojikei: clearShojikei ? null : shojikei ?? this.shojikei,
      shojikeiError: clearShojikeiError
          ? null
          : shojikeiError ?? this.shojikeiError,
      katuyokei: clearKatuyokei ? null : katuyokei ?? this.katuyokei,
      katuyokeiError: clearKatuyokeiError
          ? null
          : katuyokeiError ?? this.katuyokeiError,
      jodoshisetuzoku: clearJodoshisetuzoku
          ? null
          : jodoshisetuzoku ?? this.jodoshisetuzoku,
      jodoshisetuzokuError: clearJodoshisetuzokuError
          ? null
          : jodoshisetuzokuError ?? this.jodoshisetuzokuError,
      patternFrequency: patternFrequency ?? this.patternFrequency,
      patternFrequencyError: clearPatternFrequencyError
          ? null
          : patternFrequencyError ?? this.patternFrequencyError,
      groupSections: groupSections ?? this.groupSections,
    );
  }
}

class PatternGroupSectionState {
  const PatternGroupSectionState({
    required this.groupKey,
    required this.label,
    required this.isLoading,
    required this.isExpanded,
    required this.rows,
    this.errorMessage,
  });

  factory PatternGroupSectionState.initial(String groupKey) {
    return PatternGroupSectionState(
      groupKey: groupKey,
      label: detailPatternGroupLabel(groupKey),
      isLoading: true,
      isExpanded: true,
      rows: const <PatternGroupNode>[],
    );
  }

  final String groupKey;
  final String label;
  final bool isLoading;
  final bool isExpanded;
  final List<PatternGroupNode> rows;
  final String? errorMessage;

  PatternGroupSectionState copyWith({
    bool? isLoading,
    bool? isExpanded,
    List<PatternGroupNode>? rows,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PatternGroupSectionState(
      groupKey: groupKey,
      label: label,
      isLoading: isLoading ?? this.isLoading,
      isExpanded: isExpanded ?? this.isExpanded,
      rows: rows ?? this.rows,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class HeadwordDetailController extends ChangeNotifier {
  HeadwordDetailController(this._repository, this.headwordId)
    : state = HeadwordDetailState.initial(headwordId);

  final TwcRepository _repository;
  final String headwordId;
  HeadwordDetailState state;

  bool _loadStarted = false;
  int _requestToken = 0;

  Future<void> load() async {
    if (_loadStarted) {
      return;
    }
    _loadStarted = true;
    final token = ++_requestToken;

    state = state.copyWith(
      isBasicInfoLoading: true,
      isShojikeiLoading: true,
      isKatuyokeiLoading: true,
      isJodoshisetuzokuLoading: true,
      isPatternFrequencyLoading: true,
      clearBasicInfoError: true,
      clearShojikei: true,
      clearShojikeiError: true,
      clearKatuyokei: true,
      clearKatuyokeiError: true,
      clearJodoshisetuzoku: true,
      clearJodoshisetuzokuError: true,
      clearPatternFrequencyError: true,
    );
    _refreshGroupLoadingState();
    notifyListeners();

    final basicInfoFuture = _repository.fetchBasicInfo(headwordId);
    final shojikeiFuture = _repository.fetchBasicInfoSj(headwordId);
    final katuyokeiFuture = _repository.fetchBasicInfoKy(headwordId);
    final jodoshisetuzokuFuture = _repository.fetchBasicInfoJs(headwordId);
    final patternFrequencyFuture = _repository.fetchPatternFrequencyOrder(
      headwordId,
    );

    await Future.wait([
      _loadBasicInfo(token, basicInfoFuture),
      _loadPatternFrequency(token, patternFrequencyFuture),
    ]);

    if (token != _requestToken) {
      return;
    }

    unawaited(_loadShojikei(token, shojikeiFuture));
    unawaited(_loadKatuyokei(token, katuyokeiFuture));
    unawaited(_loadJodoshisetuzoku(token, jodoshisetuzokuFuture));
    unawaited(_loadPatternGroups(token));
  }

  void selectTab(int index) {
    if (state.selectedTabIndex == index) {
      return;
    }
    state = state.copyWith(selectedTabIndex: index);
    notifyListeners();
  }

  void toggleGroupSection(String groupKey) {
    final section = state.groupSections[groupKey];
    if (section == null) {
      return;
    }
    final updated = section.copyWith(isExpanded: !section.isExpanded);
    state = state.copyWith(
      groupSections: {...state.groupSections, groupKey: updated},
    );
    notifyListeners();
  }

  Future<void> retrySummary() async {
    _loadStarted = false;
    await load();
  }

  Future<void> retryGroup(String groupKey) async {
    final section = state.groupSections[groupKey];
    if (section == null) {
      return;
    }
    final token = _requestToken;
    state = state.copyWith(
      groupSections: {
        ...state.groupSections,
        groupKey: section.copyWith(isLoading: true, clearErrorMessage: true),
      },
    );
    notifyListeners();
    await _loadGroupSection(groupKey, token);
  }

  Future<void> _loadBasicInfo(
    int token,
    Future<ApiResult<HeadwordDetail>> future,
  ) async {
    final result = await future;
    if (token != _requestToken) {
      return;
    }
    result.fold(
      (data) {
        state = state.copyWith(
          basicInfo: data,
          isBasicInfoLoading: false,
          clearBasicInfoError: true,
        );
      },
      (ApiException error) {
        state = state.copyWith(
          isBasicInfoLoading: false,
          basicInfoError: error.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> _loadPatternFrequency(
    int token,
    Future<ApiResult<JqGridResponse<PatternItem>>> future,
  ) async {
    final result = await future;
    if (token != _requestToken) {
      return;
    }
    result.fold(
      (data) {
        state = state.copyWith(
          patternFrequency: data.rows,
          isPatternFrequencyLoading: false,
          clearPatternFrequencyError: true,
        );
      },
      (ApiException error) {
        state = state.copyWith(
          isPatternFrequencyLoading: false,
          patternFrequencyError: error.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> _loadShojikei(
    int token,
    Future<ApiResult<HeadwordShojikeiView>> future,
  ) async {
    final result = await future;
    if (token != _requestToken) {
      return;
    }
    result.fold(
      (data) {
        state = state.copyWith(
          shojikei: data,
          isShojikeiLoading: false,
          clearShojikeiError: true,
        );
      },
      (ApiException error) {
        state = state.copyWith(
          isShojikeiLoading: false,
          shojikeiError: error.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> _loadKatuyokei(
    int token,
    Future<ApiResult<HeadwordKatuyokeiView>> future,
  ) async {
    final result = await future;
    if (token != _requestToken) {
      return;
    }
    result.fold(
      (data) {
        state = state.copyWith(
          katuyokei: data,
          isKatuyokeiLoading: false,
          clearKatuyokeiError: true,
        );
      },
      (ApiException error) {
        state = state.copyWith(
          isKatuyokeiLoading: false,
          katuyokeiError: error.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> _loadJodoshisetuzoku(
    int token,
    Future<ApiResult<HeadwordJodoshisetuzokuView>> future,
  ) async {
    final result = await future;
    if (token != _requestToken) {
      return;
    }
    result.fold(
      (data) {
        state = state.copyWith(
          jodoshisetuzoku: data,
          isJodoshisetuzokuLoading: false,
          clearJodoshisetuzokuError: true,
        );
      },
      (ApiException error) {
        state = state.copyWith(
          isJodoshisetuzokuLoading: false,
          jodoshisetuzokuError: error.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> _loadPatternGroups(int token) async {
    final futures = <Future<void>>[
      for (final group in kDetailPatternGroups) _loadGroupSection(group, token),
    ];
    await Future.wait(futures);
  }

  Future<void> _loadGroupSection(String groupKey, int token) async {
    final result = await _repository.fetchPatternGroup(groupKey, headwordId);
    if (token != _requestToken) {
      return;
    }

    result.fold(
      (data) {
        final current = state.groupSections[groupKey];
        if (current == null) {
          return;
        }
        state = state.copyWith(
          groupSections: {
            ...state.groupSections,
            groupKey: current.copyWith(
              isLoading: false,
              rows: data.rows,
              clearErrorMessage: true,
            ),
          },
        );
        notifyListeners();
      },
      (ApiException error) {
        final current = state.groupSections[groupKey];
        if (current == null) {
          return;
        }
        state = state.copyWith(
          groupSections: {
            ...state.groupSections,
            groupKey: current.copyWith(
              isLoading: false,
              errorMessage: error.message,
            ),
          },
        );
        notifyListeners();
      },
    );
  }

  void _refreshGroupLoadingState() {
    state = state.copyWith(
      groupSections: {
        for (final entry in state.groupSections.entries)
          entry.key: entry.value.copyWith(
            isLoading: true,
            clearErrorMessage: true,
          ),
      },
    );
  }
}
