import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app/twc_app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_result.dart';
import '../../data/models/context_snippet.dart';
import '../../data/models/example_item.dart';
import '../../data/repositories/twc_repository.dart';

class ExamplePage extends StatefulWidget {
  const ExamplePage({
    super.key,
    required this.services,
    required this.headwordId,
    required this.patternId,
    required this.collocationId,
    this.title,
  });

  final TwcAppServices services;
  final String headwordId;
  final String patternId;
  final String collocationId;
  final String? title;

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  late final ExampleController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = ExampleController(
      repository: widget.services.repository,
      headwordId: widget.headwordId,
      patternId: widget.patternId,
      collocationId: widget.collocationId,
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
            final title = widget.title ?? widget.collocationId;

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
    ExampleState state,
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
        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
          return _ExampleCard(
            item: item,
            onContextTap: () =>
                _showContextModal(context, widget.services.repository, item),
            onUrlActionsTap: () => _showExampleUrlActions(context, item),
          );
        },
      ),
    );
  }
}

class ExampleController extends ChangeNotifier {
  ExampleController({
    required TwcRepository repository,
    required this.headwordId,
    required this.patternId,
    required this.collocationId,
    int pageSize = 100,
  }) : _repository = repository,
       _pageSize = pageSize;

  final TwcRepository _repository;
  final String headwordId;
  final String patternId;
  final String collocationId;
  final int _pageSize;

  ExampleState state = ExampleState.initial();

  bool _requestInFlight = false;
  int _requestToken = 0;

  Future<void> loadFirstPage() async {
    state = ExampleState.initial().copyWith(
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
      final result = await _repository.fetchExamples(
        '$headwordId.$patternId',
        collocationId,
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
              : 'Failed to load examples',
        );
      }
    } finally {
      _requestInFlight = false;
      notifyListeners();
    }
  }
}

class ExampleState {
  const ExampleState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalRecords,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  factory ExampleState.initial() {
    return const ExampleState(
      items: <ExampleItem>[],
      page: 0,
      totalPages: 0,
      totalRecords: 0,
      isInitialLoading: false,
      isLoadingMore: false,
      hasMore: false,
      errorMessage: null,
    );
  }

  final List<ExampleItem> items;
  final int page;
  final int totalPages;
  final int totalRecords;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  ExampleState copyWith({
    List<ExampleItem>? items,
    int? page,
    int? totalPages,
    int? totalRecords,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExampleState(
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

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.item,
    required this.onContextTap,
    required this.onUrlActionsTap,
  });

  final ExampleItem item;
  final VoidCallback onContextTap;
  final VoidCallback onUrlActionsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onContextTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.example,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onUrlActionsTap,
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'URL actions',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (item.source.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    item.source,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showExampleUrlActions(
  BuildContext context,
  ExampleItem item,
) async {
  final url = item.url.trim();
  final messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final canAct = url.isNotEmpty;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('URLをコピー'),
                enabled: canAct,
                onTap: canAct
                    ? () async {
                        Navigator.of(sheetContext).pop();
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('URLをコピーしました')),
                          );
                        }
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser_rounded),
                title: const Text('ブラウザで開く'),
                enabled: canAct,
                onTap: canAct
                    ? () async {
                        Navigator.of(sheetContext).pop();
                        final uri = Uri.tryParse(url);
                        final opened =
                            uri != null &&
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                        if (context.mounted && !opened) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('ブラウザを開けませんでした')),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showContextModal(
  BuildContext context,
  TwcRepository repository,
  ExampleItem item,
) {
  final contextFuture = repository.fetchContext(
    fileId: item.fileid,
    sentenceNo: item.sentenceNo,
    targetSentenceId: item.sentenceid,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            top: 8,
          ),
          child: FutureBuilder<ApiResult<List<ContextSnippet>>>(
            future: contextFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              final result = snapshot.data;
              if (result == null) {
                return SizedBox(
                  height: 280,
                  child: Center(child: Text('Failed to load context')),
                );
              }
              return result.fold(
                (snippets) {
                  if (snippets.isEmpty) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: Text('No context snippets found')),
                    );
                  }

                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.example,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.source,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _ContextTextFlow(snippets: snippets),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                (error) => SizedBox(
                  height: 280,
                  child: Center(
                    child: Text(error.message, textAlign: TextAlign.center),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _ContextTextFlow extends StatelessWidget {
  const _ContextTextFlow({required this.snippets});

  final List<ContextSnippet> snippets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle =
        (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).copyWith(
          color: scheme.onSurface,
          height: 1.65,
          fontSize: 16,
        );

    final spans = <InlineSpan>[];
    for (var index = 0; index < snippets.length; index++) {
      final snippet = snippets[index];
      if (index > 0) {
        spans.add(const TextSpan(text: '\n'));
      }
      spans.add(
        TextSpan(
          text: snippet.text,
          style: baseStyle.copyWith(
            fontWeight: snippet.isTarget ? FontWeight.w700 : FontWeight.w400,
            decoration: snippet.isTarget
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationStyle: snippet.isTarget
                ? TextDecorationStyle.double
                : TextDecorationStyle.solid,
            decorationColor: snippet.isTarget ? scheme.primary : null,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
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
