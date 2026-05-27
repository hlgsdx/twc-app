import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app/twc_app_services.dart';
import '../../core/widgets/twc_search_anchor_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.services});

  final TwcAppServices services;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    unawaited(widget.services.searchHistoryController.load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Text(
                        'Tsukuba Web Corpus',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                      ),
                      const Spacer(flex: 2),
                      TwcSearchAnchorBar(
                        searchController: _searchController,
                        historyController:
                            widget.services.searchHistoryController,
                        onSearchRequested: _submitSearch,
                        hintText: 'search here',
                        showSearchButton: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
