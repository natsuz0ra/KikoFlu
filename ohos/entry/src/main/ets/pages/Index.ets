import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';
import { deviceInfo } from '@kit.BasicServicesKit';
import { hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { ImmersiveTopBar } from '../immersive/ImmersiveTopBar';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';
const EVENT_NATIVE_TAB_SELECTED = 'EVENT_NATIVE_TAB_SELECTED';
const EVENT_NATIVE_BOTTOM_METRICS = 'EVENT_NATIVE_BOTTOM_METRICS';
const BOTTOM_NORMAL_AVOID_AREA_VALUE = 1;
const BOTTOM_SPECIAL_AVOID_AREA_VALUE = 12;

function navTabSymbol(index: number): Resource {
  switch (index) {
    case 0:
      return $r('sys.symbol.house_fill');
    case 1:
      return $r('sys.symbol.magnifyingglass');
    case 2:
      return $r('sys.symbol.heart_fill');
    default:
      return $r('sys.symbol.gearshape_fill');
  }
}

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink('useNativeTopBar') useNativeTopBar: boolean = false;
  @StorageLink('useNativeTabs') useNativeTabs: boolean = false;
  @StorageLink('shellBarsHidden') shellBarsHidden: boolean = false;
  @StorageLink('nativeShellSuppressed') nativeShellSuppressed: boolean = false;
  @StorageLink('nativeTabIndex') @Watch('onNativeTabIndexChanged') currentNavIndex: number = 0;
  @StorageLink('nativeTabLabels') nativeTabLabels: string[] = ['主页', '搜索', '我的', '设置'];
  @StorageLink('showUpdateBadge') showUpdateBadge: boolean = false;
  @StorageLink('shellBadgeColor') shellBadgeColor: string = '#ffff0000';
  @StorageLink('shellSelectedColor') shellSelectedColor: string = '#ff1677ff';
  @StorageLink('shellUnselectedColor') shellUnselectedColor: string = '#ff6b7280';
  @State statusBarHeight: number = 0;
  @State bottomAvoidAreaHeight: number = BOTTOM_SPECIAL_AVOID_AREA_VALUE;
  private navController: HdsTabsController = new HdsTabsController();
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

  onNativeTabIndexChanged(): void {
    this.navController.changeIndex(this.currentNavIndex);
  }

  private tabLabel(index: number): string {
    if (index >= 0 && index < this.nativeTabLabels.length) {
      return this.nativeTabLabels[index];
    }
    return '';
  }

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

  @Builder
  navTab(index: number) {
    Column({ space: 3 }) {
      if (index === 3 && this.showUpdateBadge) {
        Badge({
          value: '',
          position: BadgePosition.RightTop,
          style: { badgeSize: 8, badgeColor: this.shellBadgeColor }
        }) {
          SymbolGlyph(navTabSymbol(index))
            .fontSize(22)
            .fontColor([index === this.currentNavIndex
              ? this.shellSelectedColor : this.shellUnselectedColor])
        }
      } else {
        SymbolGlyph(navTabSymbol(index))
          .fontSize(22)
          .fontColor([index === this.currentNavIndex
            ? this.shellSelectedColor : this.shellUnselectedColor])
      }
      Text(this.tabLabel(index))
        .fontSize(10.5)
        .fontWeight(index === this.currentNavIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(index === this.currentNavIndex
          ? this.shellSelectedColor : this.shellUnselectedColor)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  nativeBottomTabs() {
    HdsTabs({ controller: this.navController }) {
      ForEach([0, 1, 2, 3], (index: number) => {
        TabContent() { }.tabBar(this.navTab(index))
      }, (index: number) => index.toString())
    }
    .onTabBarClick((index: number) => {
      this.currentNavIndex = index;
      this.context.eventHub.emit(EVENT_NATIVE_TAB_SELECTED, index);
    })
    .scrollable(false)
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .barHeight(56)
    .barFloatingStyle({
      barBottomMargin: this.bottomAvoidAreaHeight,
      adaptToHandedness: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.Bottom }) {
        FlutterPage({ viewId: this.viewId, xComponentRenderFit: RenderFit.TOP })
          .width('100%')
          .height('100%')
        if (this.useNativeTabs && deviceInfo.sdkApiVersion >= 23) {
          Column() {
            this.nativeBottomTabs()
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
