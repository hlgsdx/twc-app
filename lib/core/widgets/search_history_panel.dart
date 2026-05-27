import 'package:flutter/material.dart';

import '../../features/home/search_history_controller.dart';

class SearchHistoryPanel extends StatelessWidget {
  const SearchHistoryPanel({
    super.key,
    required this.controller,
    required this.visible,
    required this.onHistoryTap,
  });

  final SearchHistoryController controller;
  final bool visible;
  final ValueChanged<String> onHistoryTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.items;
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: controller.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                : entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '暂无搜索历史',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final item in entries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.history_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                          title: Text(item),
                          onTap: () => onHistoryTap(item),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
