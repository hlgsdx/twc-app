import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/api_result.dart';
import '../../data/models/headword_card.dart';
import '../../data/repositories/twc_repository.dart';

class SearchResultState {
  const SearchResultState({
    required this.query,
    required this.items,
    required this.page,
    required this.totalPages,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  factory SearchResultState.initial(String query) {
    return SearchResultState(
      query: query,
      items: const <HeadwordCard>[],
      page: 0,
      totalPages: 0,
      isInitialLoading: false,
      isLoadingMore: false,
      hasMore: false,
      errorMessage: null,
    );
  }

  final String query;
  final List<HeadwordCard> items;
  final int page;
  final int totalPages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  bool get isEmpty =>
      !isInitialLoading && items.isEmpty && errorMessage == null;

  SearchResultState copyWith({
    String? query,
    List<HeadwordCard>? items,
    int? page,
    int? totalPages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchResultState(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SearchResultController extends ChangeNotifier {
  SearchResultController({
    required TwcRepository repository,
    required String query,
    required this.showAll,
    int pageSize = 100,
  }) : _repository = repository,
       _pageSize = pageSize,
       state = SearchResultState.initial(query);

  final TwcRepository _repository;
  final int _pageSize;
  final bool showAll;
  SearchResultState state;

  bool _bootstrapped = false;
  bool _requestInFlight = false;
  int _requestToken = 0;

  Future<void> loadFirstPage() async {
    final nextQuery = state.query.trim();
    state = SearchResultState.initial(
      nextQuery,
    ).copyWith(isInitialLoading: true, clearError: true);
    notifyListeners();
    await _loadPage(page: 1, replace: true);
  }

  Future<void> loadNextPage() async {
    if (_requestInFlight || state.isInitialLoading || state.isLoadingMore) {
      return;
    }
    if (!state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    notifyListeners();
    await _loadPage(page: state.page + 1, replace: false);
  }

  Future<void> _loadPage({required int page, required bool replace}) async {
    final token = ++_requestToken;
    _requestInFlight = true;

    try {
      if (!_bootstrapped) {
        await _repository.bootstrapSession();
        _bootstrapped = true;
      }

      final result = showAll || state.query.trim().isEmpty
          ? await _repository.fetchHeadwordPage(page: page, rows: _pageSize)
          : await _repository.searchHeadwords(
              keyword: state.query,
              page: page,
              rows: _pageSize,
            );

      if (token != _requestToken) {
        return;
      }

      result.fold(
        (data) {
          final nextItems = replace
              ? data.rows
              : <HeadwordCard>[...state.items, ...data.rows];
          final totalPages = data.total <= 0 ? page : data.total;
          state = state.copyWith(
            items: nextItems,
            page: data.page,
            totalPages: totalPages,
            isInitialLoading: false,
            isLoadingMore: false,
            hasMore: data.page < totalPages,
            clearError: true,
          );
        },
        (ApiException error) {
          state = state.copyWith(
            isInitialLoading: false,
            isLoadingMore: false,
            errorMessage: error.message,
          );
        },
      );
    } catch (error) {
      if (token == _requestToken) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: error is ApiException
              ? error.message
              : 'Failed to load search results',
        );
      }
    } finally {
      _requestInFlight = false;
      notifyListeners();
    }
  }
}
