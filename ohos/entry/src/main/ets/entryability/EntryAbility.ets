
import { FlutterAbility, FlutterEngine, MethodChannel } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import HarmonyChannel from '../plugins/HarmonyChannel';

const EVENT_NATIVE_TAB_SELECTED = 'EVENT_NATIVE_TAB_SELECTED';
const EVENT_NATIVE_TOP_ACTION = 'EVENT_NATIVE_TOP_ACTION';
const EVENT_NATIVE_BOTTOM_METRICS = 'EVENT_NATIVE_BOTTOM_METRICS';

export default class EntryAbility extends FlutterAbility {
  private harmonyChannel: HarmonyChannel = new HarmonyChannel();
  private flutterChannel: MethodChannel | null = null;
  private shellListenersRegistered: boolean = false;
  private nativeTabSelectedCallback = (index: number): void => {
    this.flutterChannel?.invokeMethod('onNativeTabSelected', { index: index });
  };
  private nativeTopActionCallback = (
    page: string,
    action: string
  ): void => {
    this.flutterChannel?.invokeMethod('onNativeTopAction', {
      page: page,
      action: action
    });
  };
  private nativeBottomMetricsCallback = (extent: number): void => {
    this.flutterChannel?.invokeMethod('onNativeBottomMetrics', { extent: extent });
  };

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // HarmonyChannel 是应用内插件，必须显式注册；生成注册文件会在构建时
    // 被 Flutter 覆盖，不能把手工接入放在 GeneratedPluginRegistrant 中。
    flutterEngine.getPlugins()?.add(this.harmonyChannel);
    this.flutterChannel = this.harmonyChannel.getChannel();
    this.registerShellEventListeners();
  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine): void {
    this.unregisterShellEventListeners();
    this.flutterChannel = null;
    flutterEngine.getPlugins()?.remove(this.harmonyChannel.getUniqueClassName());
    super.cleanUpFlutterEngine(flutterEngine);
  }

  private registerShellEventListeners(): void {
    if (this.shellListenersRegistered) {
      return;
    }
    this.context.eventHub.on(EVENT_NATIVE_TAB_SELECTED, this.nativeTabSelectedCallback);
    this.context.eventHub.on(EVENT_NATIVE_TOP_ACTION, this.nativeTopActionCallback);
    this.context.eventHub.on(EVENT_NATIVE_BOTTOM_METRICS, this.nativeBottomMetricsCallback);
    this.shellListenersRegistered = true;
  }

  private unregisterShellEventListeners(): void {
    if (!this.shellListenersRegistered) {
      return;
    }
    this.context.eventHub.off(EVENT_NATIVE_TAB_SELECTED, this.nativeTabSelectedCallback);
    this.context.eventHub.off(EVENT_NATIVE_TOP_ACTION, this.nativeTopActionCallback);
    this.context.eventHub.off(EVENT_NATIVE_BOTTOM_METRICS, this.nativeBottomMetricsCallback);
    this.shellListenersRegistered = false;
  }
}
