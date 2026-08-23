import common from '@ohos.app.ability.common';
import { hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

const EVENT_NATIVE_TAB_SELECTED = 'EVENT_NATIVE_TAB_SELECTED';

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

@Component
export struct ImmersiveBottomBar {
  private context = getContext(this) as common.UIAbilityContext;
  private navController: HdsTabsController = new HdsTabsController();
  @Prop bottomAvoidAreaHeight: number = 0;
  @StorageLink('nativeTabIndex') @Watch('onNativeTabIndexChanged') currentNavIndex: number = 0;
  @StorageLink('nativeTabLabels') nativeTabLabels: string[] = ['主页', '搜索', '我的', '设置'];
  @StorageLink('showUpdateBadge') showUpdateBadge: boolean = false;
  @StorageLink('shellBadgeColor') shellBadgeColor: string = '#ffff0000';
  @StorageLink('shellSelectedColor') shellSelectedColor: string = '#ff1677ff';
  @StorageLink('shellUnselectedColor') shellUnselectedColor: string = '#ff6b7280';

  onNativeTabIndexChanged(): void {
    this.navController.changeIndex(this.currentNavIndex);
  }

  private tabLabel(index: number): string {
    if (index >= 0 && index < this.nativeTabLabels.length) {
      return this.nativeTabLabels[index];
    }
    return '';
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

  build() {
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
}
