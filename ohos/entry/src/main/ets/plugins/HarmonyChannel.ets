import { deviceInfo } from '@kit.BasicServicesKit';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

/** Flutter 与 ArkUI 沉浸光感外壳之间的通道实现。 */
export default class HarmonyChannel implements FlutterPlugin {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'HarmonyChannel';
  }

  getChannel(): MethodChannel | null {
    return this.channel;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'harmonyChannel');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'getNativeShellCapabilities':
        result.success({
          bottomBar: deviceInfo.sdkApiVersion >= 23,
          topBar: deviceInfo.sdkApiVersion >= 26,
          bottomExtent: AppStorage.get('nativeBottomExtent') as number ?? 68
        });
        break;
      case 'setShellTopBar':
        if (deviceInfo.sdkApiVersion < 26) {
          result.success(false);
          break;
        }
        const useNativeTopBar: boolean = call.argument('useNativeTopBar') ?? false;
        AppStorage.setOrCreate('useNativeTopBar', useNativeTopBar);
        result.success(true);
        break;
      case 'setShellBars':
        if (deviceInfo.sdkApiVersion < 23) {
          result.success(false);
          break;
        }
        AppStorage.setOrCreate('useNativeTabs', call.argument('useNativeTabs') ?? false);
        result.success(true);
        break;
      case 'setShellBarsHidden':
        const hidden: boolean = call.argument('hidden') ?? false;
        AppStorage.setOrCreate('shellBarsHidden', hidden);
        result.success(true);
        break;
      case 'setNativeShellSuppressed':
        AppStorage.setOrCreate('nativeShellSuppressed', call.argument('suppressed') ?? false);
        result.success(true);
        break;
      case 'setNativeTabIndex':
        AppStorage.setOrCreate('nativeTabIndex', call.argument('index') ?? 0);
        result.success(true);
        break;
      case 'setNativeBottomBarData':
        AppStorage.setOrCreate('nativeTabLabels', call.argument('labels') ?? []);
        AppStorage.setOrCreate('showUpdateBadge', call.argument('showUpdateBadge') ?? false);
        AppStorage.setOrCreate('shellBadgeColor', call.argument('badgeColor') ?? '#ffff0000');
        AppStorage.setOrCreate('shellSelectedColor', call.argument('selectedColor') ?? '#ff1677ff');
        AppStorage.setOrCreate('shellUnselectedColor', call.argument('unselectedColor') ?? '#ff6b7280');
        result.success(true);
        break;
      case 'setNativeTopBarData':
        const topBarPage: string = call.argument('topBarPage') ?? 'works';
        AppStorage.setOrCreate('topBarPage', topBarPage);
        AppStorage.setOrCreate('topTitle', call.argument('topTitle') ?? '');
        AppStorage.setOrCreate('topLeadingIcon', call.argument('leadingIcon') ?? '');
        AppStorage.setOrCreate('topLeadingAction', call.argument('leadingAction') ?? '');
        AppStorage.setOrCreate('topModeLabels', call.argument('modeLabels') ?? []);
        AppStorage.setOrCreate('topModeIcons', call.argument('modeIcons') ?? []);
        AppStorage.setOrCreate('topModeActions', call.argument('modeActions') ?? []);
        AppStorage.setOrCreate('topSelectedMode', call.argument('selectedMode') ?? 0);
        AppStorage.setOrCreate('topToolIcons', call.argument('toolIcons') ?? []);
        AppStorage.setOrCreate('topToolActions', call.argument('toolActions') ?? []);
        AppStorage.setOrCreate('topToolSelected', call.argument('toolSelected') ?? []);
        AppStorage.setOrCreate('topToolEnabled', call.argument('toolEnabled') ?? []);
        AppStorage.setOrCreate('topSecondaryModeLabels', call.argument('secondaryModeLabels') ?? []);
        AppStorage.setOrCreate('topSecondaryModeIcons', call.argument('secondaryModeIcons') ?? []);
        AppStorage.setOrCreate('topSecondaryModeActions', call.argument('secondaryModeActions') ?? []);
        AppStorage.setOrCreate('topSecondarySelectedMode', call.argument('secondarySelectedMode') ?? 0);
        AppStorage.setOrCreate('topSecondaryToolIcons', call.argument('secondaryToolIcons') ?? []);
        AppStorage.setOrCreate('topSecondaryToolActions', call.argument('secondaryToolActions') ?? []);
        AppStorage.setOrCreate('topSecondaryToolSelected', call.argument('secondaryToolSelected') ?? []);
        AppStorage.setOrCreate('topSecondaryToolEnabled', call.argument('secondaryToolEnabled') ?? []);
        AppStorage.setOrCreate('topSecondaryVisible', call.argument('secondaryVisible') ?? false);
        AppStorage.setOrCreate('topCollapsed', call.argument('topCollapsed') ?? false);
        AppStorage.setOrCreate('shellSelectedColor', call.argument('selectedColor') ?? '#ff1677ff');
        AppStorage.setOrCreate('shellSelectedContainerColor', call.argument('selectedContainerColor') ?? '#241677ff');
        AppStorage.setOrCreate('shellUnselectedColor', call.argument('unselectedColor') ?? '#ff6b7280');
        AppStorage.setOrCreate('topMaskStrongColor', call.argument('topMaskStrongColor') ?? '#cceff1f5');
        AppStorage.setOrCreate('topMaskWeakColor', call.argument('topMaskWeakColor') ?? '#24eff1f5');
        result.success(true);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
