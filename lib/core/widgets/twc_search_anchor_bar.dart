import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/home/search_history_controller.dart';

class TwcSearchAnchorBar extends StatelessWidget {
  const TwcSearchAnchorBar({
    super.key,
    required this.searchController,
    required this.historyController,
    required this.onSearchRequested,
    this.hintText = 'search here',
    this.leading,
    this.showSearchButton = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.constraints,
  });

  final SearchController searchController;
  final SearchHistoryController historyController;
  final Future<void> Function(String query) onSearchRequested;
  final String hintText;
  final Widget? leading;
  final bool showSearchButton;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  static const searchButtonKey = Key('twc_search_submit_button');

  Future<void> _submit(String rawQuery) async {
    final query = rawQuery.trim();
    await onSearchRequested(query);
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      isFullScreen: false,
      shrinkWrap: true,
      searchController: searchController,
      barLeading: leading ?? const Icon(Icons.search_rounded),
      barTrailing: showSearchButton
          ? [
              IconButton(
                key: searchButtonKey,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Search',
                onPressed: () {
                  if (searchController.isAttached && searchController.isOpen) {
                    searchController.closeView(null);
                  }
                  unawaited(_submit(searchController.text));
                },
              ),
            ]
          : null,
      barHintText: hintText,
      barPadding: WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
      constraints:
          constraints ?? const BoxConstraints(minWidth: 0, minHeight: 56),
      viewConstraints: const BoxConstraints(maxHeight: 280),
      onSubmitted: (value) {
        if (searchController.isAttached && searchController.isOpen) {
          searchController.closeView(null);
        }
        unawaited(_submit(value));
      },
      suggestionsBuilder: (context, controller) async {
        if (historyController.isLoading) {
          return const <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          ];
        }

        final history = historyController.items;
        if (history.isEmpty) {
          return const <Widget>[];
        }

        return history.map((entry) {
          return ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(entry),
            onTap: () {
              controller.closeView(entry);
              unawaited(onSearchRequested(entry));
            },
          );
        });
      },
    );
  }
}
