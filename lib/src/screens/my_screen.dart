import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_reviews_provider.dart';
import '../providers/my_tabs_display_provider.dart';
import '../providers/works_provider.dart' show LayoutType;
import '../utils/scroll_optimization.dart';
import '../providers/auth_provider.dart';
import '../utils/server_utils.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/works_grid_view.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../widgets/floating_feed_toolbar.dart';
import '../widgets/liquid_glass_layout.dart';
import '../widgets/download_fab.dart';
import '../services/download_service.dart';
import '../models/download_task.dart';
import 'downloads_screen.dart';
import 'local_downloads_screen.dart';
import 'subtitle_library_screen.dart';
import 'playlists_screen.dart';
import 'history_screen.dart';
import '../widgets/sort_dialog.dart';
import '../models/sort_options.dart';
import '../utils/subtitle_filter.dart';
import '../utils/system_ui_style.dart';
import '../widgets/status_bar_scroll_to_top.dart';
import '../widgets/navigation_tab_reselect.dart';
import '../platform/harmony_channel.dart';
import '../platform/harmony_secondary_toolbar.dart';
import '../platform/harmony_native_overlay.dart';
import '../platform/runtime_platform.dart';
import '../providers/settings_provider.dart';
export '../providers/my_reviews_provider.dart' show MyReviewLayoutType;

import '../../l10n/app_localizations.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key, required this.reselectController});

  final NavigationTabReselectController reselectController;

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  HarmonyNativeTopActionRegistration? _nativeTopActionRegistration;
  late TabController _tabController;
  final ValueNotifier<bool> _tabSwitcherVisible = ValueNotifier(true);
  bool _sortDialogOpen = false;
  int _lastTabIndex = 0;
  int _settledTabIndex = 0;
  bool _tabTransitionInProgress = false;
  final HarmonySecondaryToolbarController _downloadsToolbarController =
      HarmonySecondaryToolbarController(
        const HarmonySecondaryToolbarData(
          modeLabels: ['', ''],
          modeIcons: ['checklist', 'search'],
          modeActions: ['downloads_select', 'downloads_search'],
          modeSelected: [false, false],
          modeEnabled: [true, true],
          toolIcons: ['refresh', 'sort'],
          toolActions: ['downloads_refresh', 'downloads_sort'],
          toolSelected: [false, false],
          toolEnabled: [true, true],
        ),
      );
  final HarmonySecondaryToolbarController _subtitlesToolbarController =
      HarmonySecondaryToolbarController(
        const HarmonySecondaryToolbarData(
          modeLabels: ['', '', ''],
          modeIcons: ['arrow_back', 'checklist', 'search'],
          modeActions: [
            'subtitles_back',
            'subtitles_select',
            'subtitles_search',
          ],
          modeSelected: [false, false, false],
          modeEnabled: [false, true, true],
          toolIcons: ['refresh', 'info_outline'],
          toolActions: ['subtitles_refresh', 'subtitles_info'],
          toolSelected: [false, false],
          toolEnabled: [true, true],
        ),
      );
  HarmonySecondaryToolbarController? _activeSecondaryToolbarController;

  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁

  List<_TabInfo> _buildTabList(
    MyTabsDisplaySettings settings, {
    required double contentTop,
    required double collapsedToolbarTop,
    required bool useNativeToolbar,
  }) {
    final tabs = <_TabInfo>[];
    final authState = ref.watch(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    if (settings.showOnlineMarks) {
      tabs.add(
        _TabInfo(
          title: S.of(context).onlineMarks,
          icon: Icons.bookmark,
          index: 0,
          widget: _buildOnlineBookmarksTab(
            toolbarTop: contentTop,
            collapsedToolbarTop: collapsedToolbarTop,
          ),
          showFab: true,
          fabWidget: const DownloadFab(),
          hasSecondaryToolbar: true,
        ),
      );
    }

    // 历史记录
    tabs.add(
      _TabInfo(
        title: S.of(context).historyRecord,
        icon: Icons.history,
        index: tabs.length,
        widget: HistoryScreen(topInset: contentTop),
      ),
    );

    if (settings.showPlaylists && isOfficialServer) {
      tabs.add(
        _TabInfo(
          title: S.of(context).playlists,
          icon: Icons.playlist_play,
          index: 1,
          widget: PlaylistsScreen(topInset: contentTop),
        ),
      );
    }

    // 已下载始终显示
    tabs.add(
      _TabInfo(
        title: S.of(context).downloaded,
        icon: Icons.download_done,
        index: 2,
        widget: LocalDownloadsScreen(
          toolbarTop: contentTop,
          collapsedToolbarTop: collapsedToolbarTop,
          primaryToolbarVisible: _tabSwitcherVisible,
          nativeToolbarController: _downloadsToolbarController,
          useNativeToolbar: useNativeToolbar,
        ),
        hasSecondaryToolbar: true,
        secondaryToolbarController: _downloadsToolbarController,
        showFab: true,
        fabWidget: StreamBuilder<List<DownloadTask>>(
          stream: DownloadService.instance.tasksStream,
          builder: (context, snapshot) {
            final activeCount = DownloadService.instance.activeDownloadCount;
            return Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: FloatingActionButton(
                onPressed: _navigateToDownloads,
                tooltip: S.of(context).downloadTasks,
                child: const Icon(Icons.download),
              ),
            );
          },
        ),
      ),
    );

    if (settings.showSubtitleLibrary) {
      tabs.add(
        _TabInfo(
          title: S.of(context).subtitleLibrary,
          icon: Icons.subtitles,
          index: 3,
          widget: SubtitleLibraryScreen(
            toolbarTop: contentTop,
            collapsedToolbarTop: collapsedToolbarTop,
            primaryToolbarVisible: _tabSwitcherVisible,
            nativeToolbarController: _subtitlesToolbarController,
            useNativeToolbar: useNativeToolbar,
          ),
          hasSecondaryToolbar: true,
          secondaryToolbarController: _subtitlesToolbarController,
        ),
      );
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    HarmonyChannel.nativeTopBarActive.addListener(_handleNativeTopChanged);
    _nativeTopActionRegistration = HarmonyChannel.setNativeTopActionHandler(
      HarmonyTopBarPage.my,
      _handleNativeTopAction,
    );
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _tabController.animation?.addListener(_handleTabAnimation);
    _tabSwitcherVisible.addListener(_handleTopVisibilityChanged);
    _downloadsToolbarController.addListener(_handleChildToolbarChanged);
    _subtitlesToolbarController.addListener(_handleChildToolbarChanged);
    // 只在首次加载时获取数据，如果已有数据则不重新加载
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(myReviewsProvider.notifier);
      await notifier.preferencesReady;
      if (!mounted) return;
      final myState = ref.read(myReviewsProvider);
      if (myState.works.isEmpty) {
        notifier.load(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    HarmonyChannel.nativeTopBarActive.removeListener(_handleNativeTopChanged);
    _nativeTopActionRegistration?.dispose();
    _tabController.removeListener(_handleTabChanged);
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabSwitcherVisible.removeListener(_handleTopVisibilityChanged);
    _downloadsToolbarController.removeListener(_handleChildToolbarChanged);
    _subtitlesToolbarController.removeListener(_handleChildToolbarChanged);
    _downloadsToolbarController.dispose();
    _subtitlesToolbarController.dispose();
    _tabController.dispose();
    _tabSwitcherVisible.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
    ref.read(myReviewsProvider.notifier).refresh();
  }

  void _navigateToDownloads() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DownloadsScreen()));
  }

  void _handleTabChanged() {
    var needsRebuild = false;
    if (_tabController.index != _lastTabIndex) {
      _lastTabIndex = _tabController.index;
      _tabSwitcherVisible.value = true;
      needsRebuild = true;
    }
    if (_updateTabTransitionState()) needsRebuild = true;
    if (needsRebuild && mounted) setState(() {});
  }

  void _handleTabAnimation() {
    if (_updateTabTransitionState() && mounted) setState(() {});
  }

  bool _updateTabTransitionState() {
    final animationValue = _tabController.animation?.value;
    if (animationValue == null) return false;
    final nearestIndex = animationValue.round().clamp(
      0,
      _tabController.length - 1,
    );
    final atRest =
        !_tabController.indexIsChanging &&
        (animationValue - nearestIndex).abs() < 0.001;

    if (!atRest) {
      if (_tabTransitionInProgress) return false;
      _tabTransitionInProgress = true;
      return true;
    }

    if (!_tabTransitionInProgress && _settledTabIndex == nearestIndex) {
      return false;
    }
    _tabTransitionInProgress = false;
    _settledTabIndex = nearestIndex;
    _tabSwitcherVisible.value = true;
    return true;
  }

  void _handleNativeTopChanged() {
    if (mounted) setState(() {});
  }

  void _handleTopVisibilityChanged() {
    if (mounted) setState(() {});
  }

  void _handleChildToolbarChanged() {
    if (mounted) setState(() {});
  }

  void _handleNativeTopAction(HarmonyNativeTopAction event) {
    if (!mounted) return;
    if (event.action.startsWith('tab_')) {
      final index = int.tryParse(event.action.substring(4));
      if (index == null || index < 0 || index >= _tabController.length) return;
      _tabController.animateTo(index);
      return;
    }
    if (_activeSecondaryToolbarController?.dispatch(event) ?? false) {
      return;
    }
    if (event.action.startsWith('filter_')) {
      final index = int.tryParse(event.action.substring(7));
      if (index == null || index < 0 || index >= MyReviewFilter.values.length) {
        return;
      }
      ref
          .read(myReviewsProvider.notifier)
          .changeFilter(MyReviewFilter.values[index]);
      return;
    }
    switch (event.action) {
      case 'layout':
        ref.read(myReviewsProvider.notifier).toggleLayoutType();
        break;
      case 'subtitle':
        ref.read(myReviewsProvider.notifier).toggleSubtitleFilter();
        break;
      case 'sort':
        unawaited(_showSortDialog());
        break;
    }
  }

  String _nativeTabIcon(IconData icon) {
    if (icon == Icons.bookmark) return 'bookmark';
    if (icon == Icons.history) return 'history';
    if (icon == Icons.playlist_play) return 'playlist_play';
    if (icon == Icons.download) return 'download';
    if (icon == Icons.subtitles) return 'subtitles';
    return 'grid_view';
  }

  String _nativeFilterIcon(MyReviewFilter filter) => switch (filter) {
    MyReviewFilter.all => 'all_inclusive',
    MyReviewFilter.marked => 'bookmark',
    MyReviewFilter.listening => 'headphones',
    MyReviewFilter.listened => 'check_circle',
    MyReviewFilter.replay => 'replay',
    MyReviewFilter.postponed => 'schedule',
  };

  String _nativeLayoutIcon(MyReviewLayoutType layoutType) =>
      switch (layoutType) {
        MyReviewLayoutType.bigGrid => 'grid_3x3',
        MyReviewLayoutType.smallGrid => 'view_list',
        MyReviewLayoutType.list => 'view_agenda',
      };

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _tabSwitcherVisible.value = true;
      return false;
    }

    final scrolledPastHeader =
        notification.metrics.pixels - notification.metrics.minScrollExtent >=
        kTextTabBarHeight;

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0) {
      if (notification.scrollDelta! < 0) {
        _tabSwitcherVisible.value = true;
      } else if (scrolledPastHeader) {
        _tabSwitcherVisible.value = false;
      }
    } else if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          if (scrolledPastHeader) {
            _tabSwitcherVisible.value = false;
          }
        case ScrollDirection.forward:
          _tabSwitcherVisible.value = true;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  IconData _getLayoutIcon(MyReviewLayoutType layoutType) {
    switch (layoutType) {
      case MyReviewLayoutType.bigGrid:
        return Icons.grid_3x3;
      case MyReviewLayoutType.smallGrid:
        return Icons.view_list;
      case MyReviewLayoutType.list:
        return Icons.view_agenda;
    }
  }

  String _getLayoutTooltip(MyReviewLayoutType layoutType) {
    switch (layoutType) {
      case MyReviewLayoutType.bigGrid:
        return S.of(context).switchToSmallGrid;
      case MyReviewLayoutType.smallGrid:
        return S.of(context).switchToList;
      case MyReviewLayoutType.list:
        return S.of(context).switchToLargeGrid;
    }
  }

  IconData _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return mode == SubtitleFilterMode.withSubtitles
        ? Icons.closed_caption
        : Icons.closed_caption_disabled;
  }

  IconData _getFilterIcon(MyReviewFilter filter) {
    switch (filter) {
      case MyReviewFilter.all:
        return Icons.all_inclusive;
      case MyReviewFilter.marked:
        return Icons.bookmark;
      case MyReviewFilter.listening:
        return Icons.headphones;
      case MyReviewFilter.listened:
        return Icons.check_circle;
      case MyReviewFilter.replay:
        return Icons.replay;
      case MyReviewFilter.postponed:
        return Icons.schedule;
    }
  }

  Future<void> _showSortDialog() async {
    if (_sortDialogOpen) return;
    final state = ref.read(myReviewsProvider);
    _sortDialogOpen = true;
    try {
      await showWithNativeShellSuppressed<void>(
        context,
        () => showDialog<void>(
          context: context,
          builder: (context) => CommonSortDialog(
            title: S.of(context).sortOptions,
            currentOption: state.sortType,
            currentDirection: state.sortOrder,
            availableOptions: const [
              SortOrder.updatedAt,
              SortOrder.release,
              SortOrder.review,
              SortOrder.dlCount,
            ],
            onSort: (option, direction) {
              ref
                  .read(myReviewsProvider.notifier)
                  .changeSort(option, direction);
            },
          ),
        ),
      );
    } finally {
      _sortDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态

    final tabsSettings = ref.watch(myTabsDisplayProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);
    final tabSwitcherTop = FloatingToolbarLayout.toolbarTop(topPadding);
    final contentTop = FloatingToolbarLayout.contentTopAfterRows(topPadding);
    final collapsedToolbarTop = tabSwitcherTop;
    final requestNativeTopGlass =
        runtimePlatform.usesNativeHarmonyGlass &&
        ref.watch(liquidGlassTopBarProvider);
    final useNativeTopGlass =
        requestNativeTopGlass &&
        HarmonyChannel.isNativeTopBarActiveFor(HarmonyTopBarPage.my);
    final tabs = _buildTabList(
      tabsSettings,
      contentTop: contentTop,
      collapsedToolbarTop: collapsedToolbarTop,
      useNativeToolbar: useNativeTopGlass,
    );
    // 如果标签数量变化，需要重新创建 TabController
    if (_tabController.length != tabs.length) {
      final oldIndex = _tabController.index;
      _tabController.removeListener(_handleTabChanged);
      _tabController.animation?.removeListener(_handleTabAnimation);
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
      _tabController.addListener(_handleTabChanged);
      _tabController.animation?.addListener(_handleTabAnimation);
      // 尝试恢复之前的位置，但不超出新的范围
      if (oldIndex < tabs.length) {
        _tabController.index = oldIndex;
      }
      _lastTabIndex = _tabController.index;
      _settledTabIndex = _tabController.index;
      _tabTransitionInProgress = false;
    }

    final nativeTabIndex = _settledTabIndex.clamp(0, tabs.length - 1);
    final secondaryVisible = tabs[nativeTabIndex].hasSecondaryToolbar;
    _activeSecondaryToolbarController =
        tabs[nativeTabIndex].secondaryToolbarController;
    final myState = ref.watch(myReviewsProvider);
    if (requestNativeTopGlass) {
      final subtitleActive = SubtitleFilterMode.fromValue(
        myState.subtitleFilter,
      ).isActive;
      final secondaryData =
          _activeSecondaryToolbarController?.value ??
          HarmonySecondaryToolbarData(
            layout: HarmonySecondaryToolbarLayout.menu,
            modeLabels: MyReviewFilter.values
                .map((filter) => filter.localizedLabel(context))
                .toList(),
            modeIcons: MyReviewFilter.values.map(_nativeFilterIcon).toList(),
            modeActions: List.generate(
              MyReviewFilter.values.length,
              (index) => 'filter_$index',
            ),
            modeSelected: List.generate(
              MyReviewFilter.values.length,
              (index) => index == myState.filter.index,
            ),
            modeEnabled: List.filled(MyReviewFilter.values.length, true),
            selectedMode: myState.filter.index,
            toolIcons: [
              _nativeLayoutIcon(myState.layoutType),
              subtitleActive ? 'closed_caption' : 'closed_caption_disabled',
              'sort',
            ],
            toolActions: const ['layout', 'subtitle', 'sort'],
            toolSelected: [false, subtitleActive, false],
            toolEnabled: const [true, true, true],
          );
      HarmonyChannel.stageNativeTopBarData(
        page: HarmonyTopBarPage.my,
        modeLabels: tabs.map((tab) => tab.title).toList(),
        modeIcons: tabs.map((tab) => _nativeTabIcon(tab.icon)).toList(),
        modeActions: List.generate(tabs.length, (index) => 'tab_$index'),
        selectedMode: nativeTabIndex,
        toolIcons: const [],
        toolActions: const [],
        toolSelected: const [],
        toolEnabled: const [],
        secondaryModeLabels: secondaryData.modeLabels,
        secondaryModeIcons: secondaryData.modeIcons,
        secondaryModeActions: secondaryData.modeActions,
        secondaryModeSelected: secondaryData.modeSelected,
        secondaryModeEnabled: secondaryData.modeEnabled,
        secondarySelectedMode: secondaryData.selectedMode,
        secondaryLayout: secondaryData.layout.name,
        secondaryTitle: secondaryData.title,
        secondaryInputValue: secondaryData.inputValue,
        secondaryInputHint: secondaryData.inputHint,
        secondaryInputAction: secondaryData.inputAction,
        secondaryToolIcons: secondaryData.toolIcons,
        secondaryToolActions: secondaryData.toolActions,
        secondaryToolSelected: secondaryData.toolSelected,
        secondaryToolEnabled: secondaryData.toolEnabled,
        secondaryVisible: secondaryVisible,
        collapsed: !_tabSwitcherVisible.value,
        colors: harmonyShellColorsFromColorScheme(
          Theme.of(context).colorScheme,
        ),
      );
    }

    final systemOverlayStyle = transparentSystemBarsForBrightness(
      Theme.of(context).brightness,
    );

    return AnnotatedRegion(
          value: systemOverlayStyle,
          child: Scaffold(
            floatingActionButton: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final currentIndex = _tabController.index;
                if (currentIndex >= 0 && currentIndex < tabs.length) {
                  final currentTab = tabs[currentIndex];
                  if (currentTab.showFab && currentTab.fabWidget != null) {
                    return currentTab.fabWidget!;
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            body: LiquidGlassDockMediaQuery(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: TabBarView(
                        controller: _tabController,
                        children: tabs.map((tab) => tab.widget).toList(),
                      ),
                    ),
                  ),
                  if (!useNativeTopGlass)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ProgressiveTopBlur(height: topPadding + 12),
                    ),
                  if (!useNativeTopGlass)
                    Positioned(
                      top: tabSwitcherTop,
                      left: horizontalPadding,
                      right: horizontalPadding,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _tabSwitcherVisible,
                        builder: (context, visible, child) => IgnorePointer(
                          ignoring: !visible,
                          child: AnimatedSlide(
                            key: const ValueKey('my-tab-switcher'),
                            offset: visible ? Offset.zero : const Offset(0, -2),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: AnimatedOpacity(
                              opacity: visible ? 1 : 0,
                              duration: const Duration(milliseconds: 140),
                              child: child,
                            ),
                          ),
                        ),
                        child: FloatingToolbarSurface(
                          child: SizedBox(
                            height: 40,
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              splashBorderRadius: BorderRadius.circular(20),
                              tabs: tabs
                                  .map(
                                    (tab) => Tab(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(tab.icon, size: 18),
                                          const SizedBox(width: 6),
                                          Text(tab.title),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .scrollToTopOnStatusBar(_scrollController)
        .onNavigationTabReselect(
          controller: widget.reselectController,
          onReselect: _scrollToTopAndRefresh,
        );
  }

  Widget _buildOnlineBookmarksTab({
    required double toolbarTop,
    required double collapsedToolbarTop,
  }) {
    final state = ref.watch(myReviewsProvider);
    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);
    final nativeTopActive = HarmonyChannel.isNativeTopBarActiveFor(
      HarmonyTopBarPage.my,
    );
    final safeAreaTop = MediaQuery.paddingOf(context).top;
    final contentTop = FloatingToolbarLayout.contentTopAfterRows(
      safeAreaTop,
      rows: 2,
    );
    final refreshIndicatorEdgeOffset =
        FloatingToolbarLayout.contentTopAfterRows(
          safeAreaTop,
          rows: _tabSwitcherVisible.value ? 2 : 1,
        );

    return Stack(
      children: [
        Positioned.fill(
          child: _buildBody(
            state,
            topPadding: contentTop,
            refreshIndicatorEdgeOffset: nativeTopActive
                ? refreshIndicatorEdgeOffset
                : 0,
            refreshIndicatorDisplacement: nativeTopActive
                ? FloatingToolbarLayout.nativeRefreshIndicatorDisplacement
                : 40,
          ),
        ),
        if (!HarmonyChannel.isNativeTopBarActiveFor(HarmonyTopBarPage.my))
          FloatingToolbarPositionFollower(
            primaryToolbarVisible: _tabSwitcherVisible,
            visibleTop: toolbarTop,
            hiddenTop: collapsedToolbarTop,
            left: horizontalPadding,
            right: horizontalPadding,
            child: FloatingFeedToolbar(
              modeActions: [
                for (final filter in MyReviewFilter.values)
                  FloatingFeedModeAction(
                    icon: _getFilterIcon(filter),
                    label: filter.localizedLabel(context),
                    isSelected: state.filter == filter,
                    onPressed: () => ref
                        .read(myReviewsProvider.notifier)
                        .changeFilter(filter),
                  ),
              ],
              toolActions: [
                FloatingFeedToolAction(
                  icon: _getLayoutIcon(state.layoutType),
                  tooltip: _getLayoutTooltip(state.layoutType),
                  onPressed: () =>
                      ref.read(myReviewsProvider.notifier).toggleLayoutType(),
                ),
                FloatingFeedToolAction(
                  icon: _getSubtitleFilterIcon(state.subtitleFilter),
                  tooltip: SubtitleFilterMode.fromValue(
                    state.subtitleFilter,
                  ).localizedTooltip(context),
                  isSelected: SubtitleFilterMode.fromValue(
                    state.subtitleFilter,
                  ).isActive,
                  onPressed: () => ref
                      .read(myReviewsProvider.notifier)
                      .toggleSubtitleFilter(),
                ),
                FloatingFeedToolAction(
                  icon: Icons.sort,
                  tooltip: S.of(context).sort,
                  onPressed: _showSortDialog,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    MyReviewsState state, {
    double topPadding = 0,
    double refreshIndicatorEdgeOffset = 0,
    double refreshIndicatorDisplacement = 40,
  }) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).loadFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(myReviewsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final layoutType = switch (state.layoutType) {
      MyReviewLayoutType.bigGrid => LayoutType.bigGrid,
      MyReviewLayoutType.smallGrid => LayoutType.smallGrid,
      MyReviewLayoutType.list => LayoutType.list,
    };

    return WorksGridView(
      works: state.works,
      layoutType: layoutType,
      scrollController: _scrollController,
      physics: ScrollOptimization.physics,
      isLoading: state.isLoading,
      isRefreshing: state.isLoading && state.works.isNotEmpty,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: state.error,
      loadMoreError: state.loadMoreError,
      onRetry: () => ref.read(myReviewsProvider.notifier).refresh(),
      onRefresh: () => ref.read(myReviewsProvider.notifier).refresh(),
      refreshIndicatorEdgeOffset: refreshIndicatorEdgeOffset,
      refreshIndicatorDisplacement: refreshIndicatorDisplacement,
      pagination: VirtualizedPagination(
        currentPage: state.currentPage,
        pageSize: state.layoutType == MyReviewLayoutType.list
            ? state.pageSize
            : state.effectivePageSize,
        totalCount: state.totalCount,
        hasMore: state.hasMore,
        isLoading: state.isLoading || state.isRefreshing,
        onPreviousPage: ref.read(myReviewsProvider.notifier).previousPage,
        onNextPage: ref.read(myReviewsProvider.notifier).nextPage,
        onGoToPage: ref.read(myReviewsProvider.notifier).goToPage,
        nextPageOnOverscroll: true,
        scrollDuration: const Duration(milliseconds: 500),
        scrollCurve: Curves.easeInOut,
        showWhenEmpty: true,
      ),
      fillEmptyViewport: false,
      padding: state.layoutType == MyReviewLayoutType.list
          ? EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8)
          : MediaQuery.orientationOf(context) == Orientation.landscape
          ? EdgeInsets.fromLTRB(24, topPadding + 8, 24, 24)
          : EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8),
    );
  }
}

// Helper class to organize tab information
class _TabInfo {
  final String title;
  final IconData icon;
  final int index;
  final Widget widget;
  final bool showFab;
  final Widget? fabWidget;
  final bool hasSecondaryToolbar;
  final HarmonySecondaryToolbarController? secondaryToolbarController;

  const _TabInfo({
    required this.title,
    required this.icon,
    required this.index,
    required this.widget,
    this.showFab = false,
    this.fabWidget,
    this.hasSecondaryToolbar = false,
    this.secondaryToolbarController,
  });
}
