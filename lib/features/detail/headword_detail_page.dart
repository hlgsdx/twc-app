import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app/twc_app_services.dart';
import '../../data/models/headword_detail.dart';
import '../../data/models/pattern_group_node.dart';
import '../../data/models/pattern_item.dart';
import '../headword_detail/headword_detail_controller.dart';

class HeadwordDetailPage extends StatefulWidget {
  const HeadwordDetailPage({
    super.key,
    required this.services,
    required this.headwordId,
  });

  final TwcAppServices services;
  final String headwordId;

  @override
  State<HeadwordDetailPage> createState() => _HeadwordDetailPageState();
}

class _HeadwordDetailPageState extends State<HeadwordDetailPage> {
  late final HeadwordDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HeadwordDetailController(
      widget.services.repository,
      widget.headwordId,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _popOrHome() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
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
            final headword = state.basicInfo?.headword ?? state.headwordId;
            final freqText = state.basicInfo == null
                ? '…'
                : _formatNumber(state.basicInfo!.freq);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _popOrHome,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          headword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FrequencyChip(text: '頻度 $freqText'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailTabSelector(
                    selectedIndex: state.selectedTabIndex,
                    labels: const ['グループ別', 'パターン頻度順', '基本'],
                    onSelected: _controller.selectTab,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: IndexedStack(
                      index: state.selectedTabIndex,
                      children: [
                        _GroupTab(
                          controller: _controller,
                          state: state,
                          onPatternTap: (node) {
                            context.push(
                              '/detail/${state.headwordId}/collocations/${node.id}'
                              '?title=${Uri.encodeComponent(node.name)}',
                            );
                          },
                        ),
                        _PatternFrequencyTab(
                          patternFrequency: state.patternFrequency,
                          isLoading: state.isPatternFrequencyLoading,
                          errorMessage: state.patternFrequencyError,
                          onRetry: _controller.retrySummary,
                          onPatternTap: (item) {
                            context.push(
                              '/detail/${state.headwordId}/collocations/${item.id}'
                              '?title=${Uri.encodeComponent(item.name)}',
                            );
                          },
                        ),
                        _BasicInfoTab(
                          headwordId: state.headwordId,
                          basicInfo: state.basicInfo,
                          isLoading: state.isBasicInfoLoading,
                          errorMessage: state.basicInfoError,
                          shojikei: state.shojikei,
                          shojikeiError: state.shojikeiError,
                          isShojikeiLoading: state.isShojikeiLoading,
                          katuyokei: state.katuyokei,
                          katuyokeiError: state.katuyokeiError,
                          isKatuyokeiLoading: state.isKatuyokeiLoading,
                          jodoshisetuzoku: state.jodoshisetuzoku,
                          jodoshisetuzokuError: state.jodoshisetuzokuError,
                          isJodoshisetuzokuLoading:
                              state.isJodoshisetuzokuLoading,
                          onRetry: _controller.retrySummary,
                        ),
                      ],
                    ),
                  ),
                  if (state.hasSummaryData &&
                      (state.patternFrequencyError != null || state.basicInfoError != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Some sections failed to load, but the loaded summary remains available.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailTabSelector extends StatelessWidget {
  const _DetailTabSelector({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: _TabChip(
                  label: labels[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.text});

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

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.controller,
    required this.state,
    required this.onPatternTap,
  });

  final HeadwordDetailController controller;
  final HeadwordDetailState state;
  final ValueChanged<PatternGroupNode> onPatternTap;

  @override
  Widget build(BuildContext context) {
    final sections = state.groupSections.values.toList(growable: false);
    if (!state.hasSummaryData &&
        sections.every((section) => section.isLoading)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = sections[index];
        return _PatternGroupCard(
          section: section,
          onToggleExpanded: () =>
              controller.toggleGroupSection(section.groupKey),
          onPatternTap: onPatternTap,
          onRetry: () => controller.retryGroup(section.groupKey),
        );
      },
    );
  }
}

class _PatternGroupCard extends StatelessWidget {
  const _PatternGroupCard({
    required this.section,
    required this.onToggleExpanded,
    required this.onPatternTap,
    required this.onRetry,
  });

  final PatternGroupSectionState section;
  final VoidCallback onToggleExpanded;
  final ValueChanged<PatternGroupNode> onPatternTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = section.rows
        .where((row) => row.level == 0)
        .toList(growable: false);
    final maxFreq = rows.isEmpty
        ? 1
        : rows.map((row) => row.freq).fold<int>(1, (a, b) => a > b ? a : b);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(
                      section.isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (section.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator.adaptive()),
            ] else if (section.errorMessage != null) ...[
              const SizedBox(height: 12),
              _InlineSectionError(
                message: section.errorMessage!,
                onRetry: onRetry,
              ),
            ] else if (section.isExpanded) ...[
              const SizedBox(height: 14),
              _GroupTableHeader(),
              const SizedBox(height: 8),
              for (final row in rows) ...[
                _PatternGroupRow(
                  node: row,
                  maxFreq: maxFreq,
                  onTap: () => onPatternTap(row),
                ),
                const Divider(height: 1),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Text(
                '${rows.length} patterns',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(flex: 5, child: Text('パターン', style: style)),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('頻度', style: style),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('比率', style: style),
          ),
        ),
      ],
    );
  }
}

class _PatternGroupRow extends StatelessWidget {
  const _PatternGroupRow({
    required this.node,
    required this.maxFreq,
    required this.onTap,
  });

  final PatternGroupNode node;
  final int maxFreq;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final widthFraction = maxFreq == 0
        ? 0.0
        : (node.freq / maxFreq).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatNumber(node.freq),
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPercent(node.percentage),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 10,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: widthFraction,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternFrequencyTab extends StatelessWidget {
  const _PatternFrequencyTab({
    required this.patternFrequency,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onPatternTap,
  });

  final List<PatternItem> patternFrequency;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<PatternItem> onPatternTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && patternFrequency.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (errorMessage != null && patternFrequency.isEmpty) {
      return Center(
        child: _InlineSectionError(message: errorMessage!, onRetry: onRetry),
      );
    }

    final maxFreq = patternFrequency.isEmpty
        ? 1
        : patternFrequency
              .map((item) => item.freq)
              .fold<int>(1, (a, b) => a > b ? a : b);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: patternFrequency.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = patternFrequency[index];
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => onPatternTap(item),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatNumber(item.freq),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: item.freq / maxFreq,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BasicInfoTab extends StatelessWidget {
  const _BasicInfoTab({
    required this.headwordId,
    required this.basicInfo,
    required this.isLoading,
    required this.errorMessage,
    required this.shojikei,
    required this.shojikeiError,
    required this.isShojikeiLoading,
    required this.katuyokei,
    required this.katuyokeiError,
    required this.isKatuyokeiLoading,
    required this.jodoshisetuzoku,
    required this.jodoshisetuzokuError,
    required this.isJodoshisetuzokuLoading,
    required this.onRetry,
  });

  final String headwordId;
  final HeadwordDetail? basicInfo;
  final bool isLoading;
  final String? errorMessage;
  final HeadwordShojikeiView? shojikei;
  final String? shojikeiError;
  final bool isShojikeiLoading;
  final HeadwordKatuyokeiView? katuyokei;
  final String? katuyokeiError;
  final bool isKatuyokeiLoading;
  final HeadwordJodoshisetuzokuView? jodoshisetuzoku;
  final String? jodoshisetuzokuError;
  final bool isJodoshisetuzokuLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && basicInfo == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (errorMessage != null && basicInfo == null) {
      return Center(
        child: _InlineSectionError(message: errorMessage!, onRetry: onRetry),
      );
    }

    final detail = basicInfo;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _BasicInfoCard(
          title: detail.headword.isEmpty ? headwordId : detail.headword,
          rows: [
            _BasicInfoRow(label: '頻度', value: _formatNumber(detail.freq)),
            _BasicInfoRow(label: '読み', value: detail.yomi),
            _BasicInfoRow(label: '活用種類', value: detail.katuyonoshurui),
            _BasicInfoRow(label: '品詞補足', value: detail.pos2 ?? '—'),
          ],
        ),
        const SizedBox(height: 12),
        _MetricPercentageListSection<ShojikeiItem>(
          title: '書字形',
          items: shojikei?.shojikei ?? const <ShojikeiItem>[],
          isLoading: isShojikeiLoading,
          errorMessage: shojikeiError,
          onRetry: onRetry,
          labelBuilder: (item) => item.name,
          frequencyBuilder: (item) => item.freq,
          percentageBuilder: (item) => item.percentage,
        ),
        const SizedBox(height: 12),
        _MetricPercentageListSection<KatuyokeiItem>(
          title: '活用形',
          items: katuyokei?.katuyokei ?? const <KatuyokeiItem>[],
          isLoading: isKatuyokeiLoading,
          errorMessage: katuyokeiError,
          onRetry: onRetry,
          labelBuilder: (item) => item.name,
          frequencyBuilder: (item) => item.freq,
          percentageBuilder: (item) => item.percentage,
        ),
        const SizedBox(height: 12),
        _GroupedMetricSection<JodoshisetuzokuItem, JodoshisetuzokuDoshiItem>(
          title: '後続助動詞の割合',
          items: jodoshisetuzoku?.setuzoku ?? const <JodoshisetuzokuItem>[],
          isLoading: isJodoshisetuzokuLoading,
          errorMessage: jodoshisetuzokuError,
          onRetry: onRetry,
          groupLabelBuilder: (item) => item.name,
          groupFrequencyBuilder: (item) => item.jodoshiFreq,
          groupPercentageBuilder: (item) => num.tryParse(item.jodoshiPercentage) ?? 0,
          childRowsBuilder: (item) => item.doshiJodoshi,
          childLabelBuilder: (item) => item.name,
          childFrequencyBuilder: (item) => item.freq,
        ),
      ],
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({required this.title, required this.rows});

  final String title;
  final List<_BasicInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            for (final row in rows) ...[
              _BasicInfoLine(row: row),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _BasicInfoLine extends StatelessWidget {
  const _BasicInfoLine({required this.row});

  final _BasicInfoRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(row.value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _MetricPercentageListSection<T> extends StatelessWidget {
  const _MetricPercentageListSection({
    required this.title,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.labelBuilder,
    required this.frequencyBuilder,
    required this.percentageBuilder,
  });

  final String title;
  final List<T> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final String Function(T item) labelBuilder;
  final int Function(T item) frequencyBuilder;
  final num Function(T item) percentageBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SummarySectionCard(
      title: title,
      leadingIcon: Icons.expand_more_rounded,
      isLoading: isLoading && items.isEmpty,
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: items.isEmpty
          ? const _SectionEmptyMessage()
          : Column(
              children: [
                for (final item in items) ...[
                  _MetricPercentageRow(
                    label: labelBuilder(item),
                    freq: frequencyBuilder(item),
                    percentage: percentageBuilder(item),
                    fillColor: scheme.primaryContainer,
                    borderColor: scheme.outlineVariant,
                  ),
                  if (item != items.last) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _GroupedMetricSection<TGroup, TChild> extends StatelessWidget {
  const _GroupedMetricSection({
    required this.title,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.groupLabelBuilder,
    required this.groupFrequencyBuilder,
    required this.groupPercentageBuilder,
    required this.childRowsBuilder,
    required this.childLabelBuilder,
    required this.childFrequencyBuilder,
  });

  final String title;
  final List<TGroup> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final String Function(TGroup item) groupLabelBuilder;
  final int Function(TGroup item) groupFrequencyBuilder;
  final num Function(TGroup item) groupPercentageBuilder;
  final List<TChild> Function(TGroup item) childRowsBuilder;
  final String Function(TChild item) childLabelBuilder;
  final int Function(TChild item) childFrequencyBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SummarySectionCard(
      title: title,
      leadingIcon: Icons.expand_more_rounded,
      isLoading: isLoading && items.isEmpty,
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: items.isEmpty
          ? const _SectionEmptyMessage()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  _GroupedMetricSectionGroup<TChild>(
                    label: groupLabelBuilder(item),
                    frequency: groupFrequencyBuilder(item),
                    percentage: groupPercentageBuilder(item),
                    childRows: childRowsBuilder(item),
                    childLabelBuilder: childLabelBuilder,
                    childFrequencyBuilder: childFrequencyBuilder,
                    fillColor: scheme.surfaceContainer,
                    borderColor: scheme.outlineVariant,
                    childFillColor: scheme.primary,
                  ),
                  if (item != items.last) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _SummarySectionCard extends StatelessWidget {
  const _SummarySectionCard({
    required this.title,
    required this.leadingIcon,
    required this.child,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final String title;
  final IconData leadingIcon;
  final Widget child;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.surfaceContainerLow, width: 2.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(color: scheme.surfaceContainerLow),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(leadingIcon, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : errorMessage != null
                    ? _InlineSectionError(
                        message: errorMessage!,
                        onRetry: onRetry,
                      )
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPercentageRow extends StatelessWidget {
  const _MetricPercentageRow({
    required this.label,
    required this.freq,
    required this.percentage,
    required this.fillColor,
    required this.borderColor,
  });

  final String label;
  final int freq;
  final num percentage;
  final Color fillColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final percentText = _formatPercent(percentage);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 88,
          child: Text(
            _formatNumber(freq),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 126,
          child: _PercentBadge(
            text: percentText,
            fillFraction: _percentageFraction(percentage),
            fillColor: fillColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({
    required this.text,
    required this.fillFraction,
    required this.fillColor,
    required this.borderColor,
  });

  final String text;
  final double fillFraction;
  final Color fillColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * fillFraction.clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: fillWidth, color: fillColor),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupedMetricSectionGroup<TChild> extends StatelessWidget {
  const _GroupedMetricSectionGroup({
    required this.label,
    required this.frequency,
    required this.percentage,
    required this.childRows,
    required this.childLabelBuilder,
    required this.childFrequencyBuilder,
    required this.fillColor,
    required this.borderColor,
    required this.childFillColor,
  });

  final String label;
  final int frequency;
  final num percentage;
  final List<TChild> childRows;
  final String Function(TChild item) childLabelBuilder;
  final int Function(TChild item) childFrequencyBuilder;
  final Color fillColor;
  final Color borderColor;
  final Color childFillColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxChildFreq = childRows.isEmpty
        ? 1
        : childRows
              .map(childFrequencyBuilder)
              .fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: Text(
                  _formatNumber(frequency),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 126,
                child: _PercentBadge(
                  text: _formatPercent(percentage),
                  fillFraction: _percentageFraction(percentage),
                  fillColor: scheme.surfaceContainerHighest,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            children: [
              for (final row in childRows) ...[
                _JodoshisetuzokuChildRow<TChild>(
                  row: row,
                  maxFreq: maxChildFreq,
                  labelBuilder: childLabelBuilder,
                  frequencyBuilder: childFrequencyBuilder,
                  fillColor: childFillColor,
                ),
                if (row != childRows.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JodoshisetuzokuChildRow<TChild> extends StatelessWidget {
  const _JodoshisetuzokuChildRow({
    required this.row,
    required this.maxFreq,
    required this.labelBuilder,
    required this.frequencyBuilder,
    required this.fillColor,
  });

  final TChild row;
  final int maxFreq;
  final String Function(TChild item) labelBuilder;
  final int Function(TChild item) frequencyBuilder;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final widthFraction = maxFreq == 0 ? 0.0 : frequencyBuilder(row) / maxFreq;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            labelBuilder(row),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 88,
          child: Text(
            _formatNumber(frequencyBuilder(row)),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widthFraction.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  height: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyMessage extends StatelessWidget {
  const _SectionEmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'データがありません',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BasicInfoRow {
  const _BasicInfoRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _InlineSectionError extends StatelessWidget {
  const _InlineSectionError({required this.message, required this.onRetry});

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

String _formatPercent(num value) {
  if (value is int || value == value.roundToDouble()) {
    return '${value.toInt()}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

double _percentageFraction(num value) {
  final raw = value.toDouble();
  if (!raw.isFinite) {
    return 0.0;
  }
  // The corpus endpoints expose percentage-like values on a 0-100 scale,
  // sometimes as integers and sometimes as decimals. Treat the raw number as
  // a percentage in all cases so `1` always means 1%, not 100%.
  return (raw / 100).clamp(0.0, 1.0);
}
