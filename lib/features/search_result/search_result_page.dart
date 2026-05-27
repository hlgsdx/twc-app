import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app/twc_app_services.dart';
import '../../core/widgets/loading_more_indicator.dart';
import '../../core/widgets/result_row.dart';
import '../../core/widgets/twc_search_anchor_bar.dart';
import '../search_result/search_result_controller.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({
    super.key,
    required this.services,
    required this.query,
    required this.showAll,
  });

  final TwcAppServices services;
  final String query;
  final bool showAll;

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late final SearchController _searchController;
  late final ScrollController _scrollController;
  late SearchResultController _controller;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _searchController.text = widget.query;
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller = _createController(
      query: widget.query,
      showAll: widget.showAll,
    );
    unawaited(widget.services.searchHistoryController.load());
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(covariant SearchResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query == widget.query &&
        oldWidget.showAll == widget.showAll) {
      return;
    }

    _controller.dispose();
    _controller = _createController(
      query: widget.query,
      showAll: widget.showAll,
    );
    _scheduleInitialLoad();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  SearchResultController _createController({
    required String query,
    required bool showAll,
  }) {
    return SearchResultController(
      repository: widget.services.repository,
      query: query,
      showAll: showAll,
    );
  }

  void _scheduleInitialLoad() {
    if (!(widget.showAll || widget.query.trim().isNotEmpty)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_controller.loadFirstPage());
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter < 240) {
      unawaited(_controller.loadNextPage());
    }
  }

  Future<void> _submitSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isNotEmpty) {
      await widget.services.searchHistoryController.record(query);
    }

    if (!mounted) {
      return;
    }

    if (query.isEmpty) {
      context.go('/headwordlist_all');
    } else {
      context.go('/search?q=${Uri.encodeComponent(query)}');
    }
  }

  void _popOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _popOrHome,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TwcSearchAnchorBar(
                          searchController: _searchController,
                          historyController:
                              widget.services.searchHistoryController,
                          onSearchRequested: _submitSearch,
                          hintText: 'search here',
                          showSearchButton: false,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showAll)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'All headwords',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else if (state.query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Search results for “${state.query}”',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchResultState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state.isInitialLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _buildErrorState(
        context,
        message: state.errorMessage!,
        onRetry: _controller.loadFirstPage,
      );
    }

    if (state.items.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _controller.loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (state.isLoadingMore) {
              return const LoadingMoreIndicator(
                message: 'Loading more results',
              );
            }
            if (state.errorMessage != null) {
              return _InlineError(
                message: state.errorMessage!,
                onRetry: _controller.loadNextPage,
              );
            }
            if (!state.hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No more results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final item = state.items[index];
          return ResultRow(
            item: item,
            onTap: () {
              context.push('/detail/${item.headwordId}');
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context, {
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
