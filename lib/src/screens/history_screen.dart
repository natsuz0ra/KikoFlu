import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../widgets/history_work_card.dart';
import '../widgets/pagination_bar.dart';
import '../utils/scroll_optimization.dart';
import '../widgets/navigation_tab_reselect.dart';
import '../../l10n/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    required this.reselectController,
  });

  final NavigationTabReselectController reselectController;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final history = historyState.records;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: history.isEmpty && !historyState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context).noPlayHistory,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              cacheExtent: ScrollOptimization.cacheExtent,
              physics: ScrollOptimization.physics,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = history[index];
                        return HistoryWorkCard(record: record);
                      },
                      childCount: history.length,
                    ),
                  ),
                ),
                if (history.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80, top: 16),
                      child: PaginationBar(
                        currentPage: historyState.currentPage,
                        totalCount: historyState.totalCount,
                        pageSize: historyState.pageSize,
                        hasMore: historyState.hasMore,
                        isLoading: historyState.isLoading,
                        onGoToPage: (page) {
                          ref.read(historyProvider.notifier).goToPage(page);
                        },
                        onPreviousPage: () {
                          ref.read(historyProvider.notifier).previousPage();
                        },
                        onNextPage: () {
                          ref.read(historyProvider.notifier).nextPage();
                        },
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: history.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showClearConfirmation(context, ref),
              tooltip: S.of(context).clearHistory,
              child: const Icon(Icons.delete_outline),
            )
          : null,
    ).onNavigationTabReselect(
      controller: widget.reselectController,
      onReselect: () {
        _scrollToTop();
        ref.read(historyProvider.notifier).refresh();
      },
    );
  }

  Future<void> _showClearConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).clearHistoryTitle),
        content: Text(S.of(context).clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}
