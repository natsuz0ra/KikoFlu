import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ImmersiveBottomBar } from '../immersive/ImmersiveBottomBar';
import { ImmersiveTopBar } from '../immersive/ImmersiveTopBar';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';
const EVENT_NATIVE_BOTTOM_METRICS = 'EVENT_NATIVE_BOTTOM_METRICS';
const BOTTOM_NORMAL_AVOID_AREA_VALUE = 1;
const BOTTOM_SPECIAL_AVOID_AREA_VALUE = 12;

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink('useNativeTopBar') useNativeTopBar: boolean = false;
  @StorageLink('useNativeTabs') useNativeTabs: boolean = false;
  @StorageLink('shellBarsHidden') shellBarsHidden: boolean = false;
  @StorageLink('nativeShellSuppressed') nativeShellSuppressed: boolean = false;
  @State statusBarHeight: number = 0;
  @State bottomAvoidAreaHeight: number = BOTTOM_SPECIAL_AVOID_AREA_VALUE;
  private win: window.Window | null = null;
  private appeared: boolean = false;
  private avoidAreaChangeCallback = (data: window.AvoidAreaOptions): void => {
    if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
      this.statusBarHeight = this.getUIContext().px2vp(data.area.topRect.height);
    }
    if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      this.updateBottomAvoidArea(data.area.bottomRect.height);
    }
  };

  private updateBottomAvoidArea(heightPx: number): void {
    this.bottomAvoidAreaHeight = heightPx === 0
      ? BOTTOM_SPECIAL_AVOID_AREA_VALUE
      : this.getUIContext().px2vp(heightPx) + BOTTOM_NORMAL_AVOID_AREA_VALUE;
    const extent = this.bottomAvoidAreaHeight + 56;
    AppStorage.setOrCreate('nativeBottomExtent', extent);
    this.context.eventHub.emit(EVENT_NATIVE_BOTTOM_METRICS, extent);
  }

  aboutToAppear(): void {
    this.appeared = true;
    window.getLastWindow(this.context).then((w: window.Window) => {
      if (!this.appeared) return;
      this.win = w;
      const topArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.statusBarHeight = this.getUIContext().px2vp(topArea.topRect.height);
      const bottomArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.updateBottomAvoidArea(bottomArea.bottomRect.height);
      w.on('avoidAreaChange', this.avoidAreaChangeCallback);
    }).catch((err: Object) => {
      console.error('Index', `getLastWindow failed: ${err}`);
    });
  }

  aboutToDisappear(): void {
    this.appeared = false;
    this.win?.off('avoidAreaChange', this.avoidAreaChangeCallback);
    this.win = null;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.Bottom }) {
        FlutterPage({ viewId: this.viewId, xComponentRenderFit: RenderFit.TOP })
          .width('100%')
          .height('100%')
        if (this.useNativeTabs && deviceInfo.sdkApiVersion >= 23) {
          Column() {
            ImmersiveBottomBar({ bottomAvoidAreaHeight: this.bottomAvoidAreaHeight })
          }
          .hitTestBehavior(HitTestMode.Transparent)
          .width('100%')
          .height(this.bottomAvoidAreaHeight + 56)
          .visibility(this.shellBarsHidden || this.nativeShellSuppressed
            ? Visibility.None : Visibility.Visible)
        }
      }
      .width('100%')
      .height('100%')
      if (this.useNativeTopBar && !this.shellBarsHidden &&
        !this.nativeShellSuppressed && deviceInfo.sdkApiVersion >= 26) {
        ImmersiveTopBar({ statusBarHeight: this.statusBarHeight })
      }
    }
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
