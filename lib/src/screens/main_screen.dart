import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../../l10n/app_localizations.dart';
import '../providers/audio_provider.dart';
import '../providers/update_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import '../widgets/mini_player.dart';
import '../widgets/liquid_glass_layout.dart';
import '../widgets/navigation_tab_reselect.dart';
import 'works_screen.dart';
import 'search_screen.dart';
import 'my_screen.dart';
import 'settings_screen.dart';
import '../providers/settings_provider.dart';
import '../platform/harmony_channel.dart';
import '../platform/native_shell_route_observer.dart';
import '../platform/runtime_platform.dart';
import '../platform/search_input_focus.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _NativeShellRequest {
  const _NativeShellRequest({
    required this.bottomEnabled,
    required this.topEnabled,
    required this.topPage,
    required this.topDataRevision,
    required this.showUpdateBadge,
    required this.selectedIndex,
    required this.labels,
    required this.badgeColor,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final bool bottomEnabled;
  final bool topEnabled;
  final HarmonyTopBarPage? topPage;
  final int topDataRevision;
  final bool showUpdateBadge;
  final int selectedIndex;
  final List<String> labels;
  final Color badgeColor;
  final Color selectedColor;
  final Color unselectedColor;

  String get signature => <Object?>[
    bottomEnabled,
    topEnabled,
    topPage?.name,
    topDataRevision,
    showUpdateBadge,
    selectedIndex,
    ...labels,
    badgeColor.toARGB32(),
    selectedColor.toARGB32(),
    unselectedColor.toARGB32(),
  ].join('|');
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  static const int _homeTabIndex = 0;
  static const int _searchTabIndex = 1;
  static const int _myTabIndex = 2;
  static const int _settingsTabIndex = 3;

  // 使用 PageStorageBucket 来保存页面状态
  final PageStorageBucket _bucket = PageStorageBucket();
  final ValueNotifier<double> _liquidDockExtent = ValueNotifier(0);
  final _homeReselectController = NavigationTabReselectController();
  final _myReselectController = NavigationTabReselectController();
  bool _nativeSyncInFlight = false;
  bool _nativeSyncScheduled = false;
  bool _topDataRebuildScheduled = false;
  _NativeShellRequest? _pendingNativeShellRequest;
  String? _lastNativeShellRequest;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    HarmonyChannel.initialize();
    HarmonyChannel.onNativeTabSelected = _handleDestinationSelected;
    HarmonyChannel.nativeBottomBarActive.addListener(
      _handleNativeBottomActiveChanged,
    );
    HarmonyChannel.nativeBottomExtent.addListener(_handleNativeExtentChanged);
    HarmonyChannel.nativeTopDataRevision.addListener(_handleTopDataChanged);
    nativeShellRouteObserver.revision.addListener(_handleRouteStackChanged);
    searchInputFocused.addListener(_handleSearchInputFocusChanged);
    _screens = [
      WorksScreen(
        key: const PageStorageKey('works_screen'),
        reselectController: _homeReselectController,
      ),
      const SearchScreen(key: PageStorageKey('search_screen')),
      MyScreen(
        key: const PageStorageKey('my_screen'),
        reselectController: _myReselectController,
      ),
      const SettingsScreen(key: PageStorageKey('settings_screen')),
    ];
  }

  @override
  void dispose() {
    _pendingNativeShellRequest = null;
    HarmonyChannel.nativeTopBarActive.value = false;
    HarmonyChannel.nativeBottomBarActive.removeListener(
      _handleNativeBottomActiveChanged,
    );
    HarmonyChannel.nativeBottomBarActive.value = false;
    if (runtimePlatform.usesNativeHarmonyGlass) {
      unawaited(HarmonyChannel.setNativeBottomBar(false));
      unawaited(HarmonyChannel.setNativeTopBar(false));
    }
    HarmonyChannel.onNativeTabSelected = null;
    HarmonyChannel.nativeBottomExtent.removeListener(
      _handleNativeExtentChanged,
    );
    HarmonyChannel.nativeTopDataRevision.removeListener(_handleTopDataChanged);
    nativeShellRouteObserver.revision.removeListener(_handleRouteStackChanged);
    searchInputFocused.removeListener(_handleSearchInputFocusChanged);
    _liquidDockExtent.dispose();
    _homeReselectController.dispose();
    _myReselectController.dispose();
    super.dispose();
  }

  void _handleNativeExtentChanged() {
    if (!mounted || !HarmonyChannel.nativeBottomBarActive.value) return;
    setState(() {});
  }

  void _handleNativeBottomActiveChanged() {
    if (mounted) setState(() {});
  }

  void _handleRouteStackChanged() {
    if (mounted) setState(() {});
  }

  void _handleSearchInputFocusChanged() {
    if (mounted && _currentIndex == _searchTabIndex) setState(() {});
  }

  void _handleTopDataChanged() {
    if (!mounted || _topDataRebuildScheduled) return;
    _topDataRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _topDataRebuildScheduled = false;
      if (mounted) setState(() {});
    });
  }

  String _colorHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

  void _scheduleNativeShellSync({
    required bool bottomEnabled,
    required bool topEnabled,
    required HarmonyTopBarPage? topPage,
    required bool showUpdateBadge,
    required List<String> labels,
    required Color badgeColor,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    if (!runtimePlatform.usesNativeHarmonyGlass) return;
    final request = _NativeShellRequest(
      bottomEnabled: bottomEnabled,
      topEnabled: topEnabled,
      topPage: topPage,
      topDataRevision: HarmonyChannel.nativeTopDataRevision.value,
      showUpdateBadge: showUpdateBadge,
      selectedIndex: _currentIndex,
      labels: List.unmodifiable(labels),
      badgeColor: badgeColor,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
    );
    if (_pendingNativeShellRequest?.signature == request.signature) return;
    if (!_nativeSyncInFlight &&
        !_nativeSyncScheduled &&
        _lastNativeShellRequest == request.signature) {
      return;
    }
    _pendingNativeShellRequest = request;
    if (_nativeSyncInFlight || _nativeSyncScheduled) return;
    _nativeSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nativeSyncScheduled = false;
      if (!mounted) return;
      unawaited(_drainNativeShellSync());
    });
  }

  Future<void> _drainNativeShellSync() async {
    if (_nativeSyncInFlight) return;
    _nativeSyncInFlight = true;
    try {
      while (mounted && _pendingNativeShellRequest != null) {
        final request = _pendingNativeShellRequest!;
        _pendingNativeShellRequest = null;
        await _syncNativeShell(request);
        _lastNativeShellRequest = request.signature;
      }
    } finally {
      _nativeSyncInFlight = false;
      if (mounted && _pendingNativeShellRequest != null) {
        unawaited(_drainNativeShellSync());
      }
    }
  }

  Future<void> _syncNativeShell(_NativeShellRequest request) async {
    var bottomActive = false;
    var topActive = false;
    try {
      final capabilities = await HarmonyChannel.getCapabilities();
      final bottomSupported = capabilities?.bottomBar == true;
      final topSupported = capabilities?.topBar == true;

      if (request.bottomEnabled && bottomSupported) {
        final dataReady = await HarmonyChannel.setNativeBottomBarData(
          labels: request.labels,
          showUpdateBadge: request.showUpdateBadge,
          badgeColor: _colorHex(request.badgeColor),
          selectedColor: _colorHex(request.selectedColor),
          unselectedColor: _colorHex(request.unselectedColor),
        );
        final indexReady = await HarmonyChannel.setNativeTabIndex(
          request.selectedIndex,
        );
        final visible = await HarmonyChannel.setNativeBottomBar(true);
        bottomActive = dataReady && indexReady && visible;
        if (!bottomActive) await HarmonyChannel.setNativeBottomBar(false);
      } else {
        await HarmonyChannel.setNativeBottomBar(false);
      }

      if (request.topEnabled && request.topPage != null && topSupported) {
        topActive = await HarmonyChannel.activateNativeTopBar(request.topPage!);
        if (!topActive) await HarmonyChannel.setNativeTopBar(false);
      } else {
        HarmonyChannel.deactivateNativeTopBar();
        await HarmonyChannel.setNativeTopBar(false);
      }
    } catch (_) {
      await HarmonyChannel.setNativeBottomBar(false);
      await HarmonyChannel.setNativeTopBar(false);
    }

    // A newer rotation/theme/locale/tab request is already queued. Do not
    // publish an obsolete takeover state that would hide Flutter fallbacks.
    if (_pendingNativeShellRequest != null) return;
    if (!mounted) {
      await HarmonyChannel.setNativeBottomBar(false);
      await HarmonyChannel.setNativeTopBar(false);
      return;
    }
    HarmonyChannel.nativeTopBarActive.value = topActive;
    HarmonyChannel.nativeBottomBarActive.value = bottomActive;
  }

  List<NavigationDestination> _buildDestinations(
    BuildContext context,
    bool showUpdateBadge,
  ) {
    final s = S.of(context);
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: s.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_outlined),
        selectedIcon: const Icon(Icons.search),
        label: s.navSearch,
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
        label: s.navMy,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: showUpdateBadge,
          child: const Icon(Icons.settings_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: showUpdateBadge,
          child: const Icon(Icons.settings),
        ),
        label: s.navSettings,
      ),
    ];
  }

  void _handleDestinationSelected(int index) {
    if (_currentIndex == index) {
      if (index == _homeTabIndex) _homeReselectController.reselect();
      if (index == _myTabIndex) _myReselectController.reselect();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    unawaited(HarmonyChannel.setNativeTabIndex(index));

    if (index == _settingsTabIndex) {
      ref.read(settingsCacheRefreshTriggerProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shellRoute = ModalRoute.of(context);
    final keepsNativeShell = nativeShellRouteObserver.keepsShellVisibleFor(
      shellRoute,
    );
    final routeTopPage = nativeShellRouteObserver.nativeTopPageAbove(
      shellRoute,
    );
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final showUpdateBadge = ref.watch(showUpdateRedDotProvider);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final mainTopPage = switch (_currentIndex) {
      0 => HarmonyTopBarPage.works,
      1 => HarmonyTopBarPage.search,
      2 => HarmonyTopBarPage.my,
      _ => null,
    };
    final topPage = routeTopPage ?? (keepsNativeShell ? mainTopPage : null);
    final requestNativeTop =
        ref.watch(liquidGlassTopBarProvider) &&
        runtimePlatform.usesNativeHarmonyGlass &&
        !isLandscape &&
        topPage != null;
    final destinations = _buildDestinations(context, showUpdateBadge);
    final colorScheme = Theme.of(context).colorScheme;
    _scheduleNativeShellSync(
      bottomEnabled: keepsNativeShell && !isLandscape && useLiquidGlass,
      topEnabled: requestNativeTop,
      topPage: topPage,
      showUpdateBadge: showUpdateBadge,
      labels: destinations.map((destination) => destination.label).toList(),
      badgeColor: colorScheme.error,
      selectedColor: colorScheme.primary,
      unselectedColor: colorScheme.onSurfaceVariant,
    );
    final useNativeOhosBottom =
        keepsNativeShell &&
        !isLandscape &&
        HarmonyChannel.nativeBottomBarActive.value;

    if (isLandscape) {
      // 横屏布局：使用 NavigationRail
      final landscapeScaffold = Scaffold(
        body: Stack(
          children: [
            // 主内容区域
            Row(
              children: [
                // 侧边导航栏
                SafeArea(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: useLiquidGlass
                              ? const EdgeInsets.all(8)
                              : EdgeInsets.zero,
                          child: useLiquidGlass
                              ? Consumer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: _buildNavigationRail(destinations),
                                  ),
                                  builder: (context, ref, child) {
                                    return LiquidGlassContainer(
                                      shape:
                                          const LiquidGlassShape.roundedRectangle(
                                            28,
                                          ),
                                      fallbackIntensity: 0.86,
                                      child: child,
                                    );
                                  },
                                )
                              : _buildNavigationRail(destinations),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // 页面内容
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authProvider);
                      final isOfflineMode =
                          authState.currentUser != null &&
                          !authState.isLoggedIn &&
                          authState.error != null;

                      final pages = PageStorage(
                        bucket: _bucket,
                        child: IndexedStack(
                          index: _currentIndex,
                          children: List.generate(_screens.length, (index) {
                            return HeroMode(
                              enabled: index == _currentIndex,
                              child: _screens[index],
                            );
                          }),
                        ),
                      );
                      final miniPlayer = Consumer(
                        builder: (context, ref, child) {
                          final currentTrack = ref.watch(currentTrackProvider);
                          return currentTrack.when(
                            data: (track) => track != null
                                ? const MiniPlayer()
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      );

                      final content = useLiquidGlass
                          ? LiquidGlassDockOverlay(
                              onExtentChanged: (extent) {
                                if (_liquidDockExtent.value != extent) {
                                  _liquidDockExtent.value = extent;
                                }
                              },
                              dock: AnimatedSize(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.bottomCenter,
                                child: miniPlayer,
                              ),
                              child: pages,
                            )
                          : Column(
                              children: [
                                Expanded(child: pages),
                                miniPlayer,
                              ],
                            );

                      return Padding(
                        padding: EdgeInsets.only(top: isOfflineMode ? 30 : 0),
                        child: SafeArea(
                          top: false,
                          bottom: !useLiquidGlass,
                          child: content,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // 离线模式提示横幅（覆盖在顶部）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  final isOfflineMode =
                      authState.currentUser != null &&
                      !authState.isLoggedIn &&
                      authState.error != null;

                  if (!isOfflineMode) {
                    return const SizedBox.shrink();
                  }

                  final topPadding = MediaQuery.of(context).padding.top;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(12, topPadding + 4, 12, 4),
                    color: Colors.orange.shade800,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            S.of(context).offlineModeMessage,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final notifier = ref.read(authProvider.notifier);
                            await notifier.retryConnection();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            S.of(context).retry,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
      return useLiquidGlass
          ? LiquidGlassDockScope(
              notifier: _liquidDockExtent,
              child: landscapeScaffold,
            )
          : landscapeScaffold;
    }

    // 竖屏布局：液态玻璃模式把导航栏悬浮在页面内容上方，经典模式
    // 继续使用 Scaffold 的 bottomNavigationBar 插槽。
    final miniPlayer = Consumer(
      builder: (context, ref, child) {
        if (_currentIndex == _searchTabIndex &&
            (MediaQuery.viewInsetsOf(context).bottom > 0 ||
                searchInputFocused.value)) {
          return const SizedBox.shrink();
        }
        final currentTrack = ref.watch(currentTrackProvider);
        return currentTrack.when(
          data: (track) => track != null
              ? MiniPlayer(useNativeHarmonyStyle: useNativeOhosBottom)
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
    final bottomNavigation = Consumer(
      child: miniPlayer,
      builder: (context, ref, child) {
        return MainBottomNavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _handleDestinationSelected,
          destinations: destinations,
          liquidGlass: useLiquidGlass,
          fallbackGlassTransparency: ref.watch(
            fallbackGlassTransparencyProvider,
          ),
          showUpdateBadge: showUpdateBadge,
          onLayoutExtentChanged: (extent) {
            if (_liquidDockExtent.value != extent) {
              _liquidDockExtent.value = extent;
            }
          },
          miniPlayer: child!,
        );
      },
    );

    final portraitScaffold = Scaffold(
      body: Stack(
        children: [
          // 主内容
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              final isOfflineMode =
                  authState.currentUser != null &&
                  !authState.isLoggedIn &&
                  authState.error != null;

              return Padding(
                padding: EdgeInsets.only(top: isOfflineMode ? 30 : 0),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: LiquidGlassDockMediaQuery(
                    child: PageStorage(
                      bucket: _bucket,
                      child: IndexedStack(
                        index: _currentIndex,
                        children: List.generate(_screens.length, (index) {
                          return HeroMode(
                            enabled: index == _currentIndex,
                            child: _screens[index],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 离线模式提示横幅（覆盖在顶部）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authProvider);
                final isOfflineMode =
                    authState.currentUser != null &&
                    !authState.isLoggedIn &&
                    authState.error != null;

                if (!isOfflineMode) {
                  return const SizedBox.shrink();
                }

                final topPadding = MediaQuery.of(context).padding.top;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(12, topPadding + 4, 12, 4),
                  color: Colors.orange.shade800,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          S.of(context).offlineModeMessage,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final notifier = ref.read(authProvider.notifier);
                          await notifier.retryConnection();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          S.of(context).retry,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (useLiquidGlass && !useNativeOhosBottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(child: bottomNavigation),
            ),
          if (useNativeOhosBottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiquidGlassDockExtentReporter(
                onChanged: (extent) {
                  if (_liquidDockExtent.value != extent) {
                    _liquidDockExtent.value = extent;
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: HarmonyChannel.nativeBottomExtent.value,
                  ),
                  child: miniPlayer,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: useLiquidGlass || useNativeOhosBottom
          ? null
          : bottomNavigation,
    );
    return useLiquidGlass
        ? LiquidGlassDockScope(
            notifier: _liquidDockExtent,
            child: portraitScaffold,
          )
        : portraitScaffold;
  }

  Widget _buildNavigationRail(List<NavigationDestination> destinations) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleDestinationSelected,
      labelType: NavigationRailLabelType.selected,
      destinations: destinations
          .map(
            (dest) => NavigationRailDestination(
              icon: dest.icon,
              selectedIcon: dest.selectedIcon,
              label: Text(dest.label),
            ),
          )
          .toList(),
    );
  }
}
