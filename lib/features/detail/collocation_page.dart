import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app/twc_app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_result.dart';
import '../../data/models/collocation_item.dart';
import '../../data/repositories/twc_repository.dart';

class CollocationPage extends StatefulWidget {
  const CollocationPage({
    super.key,
    required this.services,
    required this.headwordId,
    required this.patternId,
    this.title,
  });

  final TwcAppServices services;
  final String headwordId;
  final String patternId;
  final String? title;

  @override
  State<CollocationPage> createState() => _CollocationPageState();
}

class _CollocationPageState extends State<CollocationPage> {
  late final CollocationController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = CollocationController(
      repository: widget.services.repository,
      headwordId: widget.headwordId,
      patternId: widget.patternId,
    );
    _scrollController = ScrollController()..addListener(_handleScroll);
    unawaited(_controller.loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 240) {
      unawaited(_controller.loadNextPage());
    }
  }

  void _pop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/detail/${widget.headwordId}');
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
            final title = widget.title ?? widget.patternId;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pop,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CountChip(
                        text: state.totalRecords > 0
                            ? '${_formatNumber(state.totalRecords)}件'
                            : '${state.items.length}件',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TableHeader(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBody(context, state, scheme)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CollocationState state,
    ColorScheme scheme,
  ) {
    if (state.isInitialLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: _InlineError(
          message: state.errorMessage!,
          onRetry: _controller.loadFirstPage,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator.adaptive()),
              );
            }
            if (state.errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _InlineError(
                  message: state.errorMessage!,
                  onRetry: _controller.loadNextPage,
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final item = state.items[index];
          return _CollocationRow(
            item: item,
            onTap: () {
              final exampleCollocationId = item.collocationId.split('.').last;
              context.push(
                '/detail/${widget.headwordId}/collocations/${widget.patternId}/examples/$exampleCollocationId'
                '?title=${Uri.encodeComponent(item.collocation)}',
              );
            },
          );
        },
      ),
    );
  }
}

class CollocationController extends ChangeNotifier {
  CollocationController({
    required TwcRepository repository,
    required this.headwordId,
    required this.patternId,
    int pageSize = 100,
  }) : _repository = repository,
       _pageSize = pageSize;

  final TwcRepository _repository;
  final String headwordId;
  final String patternId;
  final int _pageSize;

  CollocationState state = CollocationState.initial();

  bool _requestInFlight = false;
  int _requestToken = 0;

  Future<void> loadFirstPage() async {
    state = CollocationState.initial().copyWith(
      isInitialLoading: true,
      clearError: true,
    );
    notifyListeners();
    await _loadPage(page: 1, replace: true);
  }

  Future<void> loadNextPage() async {
    if (_requestInFlight ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
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
      final result = await _repository.fetchCollocations(
        '$headwordId.$patternId',
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
              : [...state.items, ...data.rows];
          final totalPages = data.total <= 0 ? page : data.total;
          state = state.copyWith(
            items: nextItems,
            page: data.page,
            totalPages: totalPages,
            totalRecords: data.records ?? totalPages,
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
              : 'Failed to load collocations',
        );
      }
    } finally {
      _requestInFlight = false;
      notifyListeners();
    }
  }
}

class CollocationState {
  const CollocationState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalRecords,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  factory CollocationState.initial() {
    return const CollocationState(
      items: <CollocationItem>[],
      page: 0,
      totalPages: 0,
      totalRecords: 0,
      isInitialLoading: false,
      isLoadingMore: false,
      hasMore: false,
      errorMessage: null,
    );
  }

  final List<CollocationItem> items;
  final int page;
  final int totalPages;
  final int totalRecords;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  CollocationState copyWith({
    List<CollocationItem>? items,
    int? page,
    int? totalPages,
    int? totalRecords,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CollocationState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(flex: 6, child: Text('コロケーション', style: style)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('頻度', style: style),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('MI', style: style),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('LD', style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollocationRow extends StatelessWidget {
  const _CollocationRow({required this.item, required this.onTap});

  final CollocationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Text(
                item.collocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatNumber(item.freq),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  item.mi.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  item.logdice.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatNumber(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    buffer.write(raw[i]);
    final remaining = raw.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
