import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

class ExperimentalFeaturesScreen extends ConsumerWidget {
  const ExperimentalFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomEnabled = ref.watch(liquidGlassNavigationProvider);
    final topEnabled = ref.watch(liquidGlassTopBarProvider);
    return SettingsSubpageScaffold(
      title: S.of(context).experimentalFeatures,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsInfoCard(
            icon: Icons.science_outlined,
            title: S.of(context).experimentalFeatures,
            child: Text(S.of(context).experimentalFeaturesDesc),
          ),
          const SizedBox(height: 16),
          SettingsSectionList(
            children: [
              SettingsSwitchTile(
                icon: Icons.vertical_align_top,
                title: S.of(context).liquidGlassTopBar,
                subtitle: S.of(context).liquidGlassTopBarDesc,
                value: topEnabled,
                onChanged: (value) => ref
                    .read(liquidGlassTopBarProvider.notifier)
                    .setEnabled(value),
              ),
              SettingsSwitchTile(
                icon: Icons.vertical_align_bottom,
                title: S.of(context).liquidGlassBottomBar,
                subtitle: S.of(context).liquidGlassBottomBarDesc,
                value: bottomEnabled,
                onChanged: (value) => ref
                    .read(liquidGlassNavigationProvider.notifier)
                    .setEnabled(value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
