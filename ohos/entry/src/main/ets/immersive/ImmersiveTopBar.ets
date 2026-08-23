import { invokeNativeTopAction } from '../plugins/HarmonyChannel';
import { immersiveMaterial, topIconResource } from './ImmersiveTopBarModel';

const SECONDARY_FILTER_MIN_WIDTH = 104;
const SECONDARY_FILTER_MAX_WIDTH = 152;
const SECONDARY_FILTER_BASE_WIDTH = 80;
const SECONDARY_FILTER_ASCII_WIDTH = 7;
const SECONDARY_FILTER_WIDE_WIDTH = 12;
const SECONDARY_MENU_WIDTH = 152;

@Component
export struct ImmersiveTopBar {
  @Prop statusBarHeight: number = 0;
  @StorageLink('topBarPage') topBarPage: string = 'works';
  @StorageLink('topTitle') topTitle: string = '';
  @StorageLink('topLeadingIcon') topLeadingIcon: string = '';
  @StorageLink('topLeadingAction') topLeadingAction: string = '';
  @StorageLink('topModeLabels') topModeLabels: string[] = [];
  @StorageLink('topModeIcons') topModeIcons: string[] = [];
  @StorageLink('topModeActions') topModeActions: string[] = [];
  @StorageLink('topSelectedMode') topSelectedMode: number = 0;
  @StorageLink('topToolIcons') topToolIcons: string[] = [];
  @StorageLink('topToolActions') topToolActions: string[] = [];
  @StorageLink('topToolSelected') topToolSelected: boolean[] = [];
  @StorageLink('topToolEnabled') topToolEnabled: boolean[] = [];
  @StorageLink('topSecondaryModeLabels') secondaryModeLabels: string[] = [];
  @StorageLink('topSecondaryModeIcons') secondaryModeIcons: string[] = [];
  @StorageLink('topSecondaryModeActions') secondaryModeActions: string[] = [];
  @StorageLink('topSecondarySelectedMode') secondarySelectedMode: number = 0;
  @StorageLink('topSecondaryToolIcons') secondaryToolIcons: string[] = [];
  @StorageLink('topSecondaryToolActions') secondaryToolActions: string[] = [];
  @StorageLink('topSecondaryToolSelected') secondaryToolSelected: boolean[] = [];
  @StorageLink('topSecondaryToolEnabled') secondaryToolEnabled: boolean[] = [];
  @StorageLink('topSecondaryVisible') secondaryVisible: boolean = false;
  @StorageLink('topCollapsed') collapsed: boolean = false;
  @StorageLink('shellSelectedColor') selectedColor: string = '#ff1677ff';
  @StorageLink('shellSelectedContainerColor') selectedContainerColor: string = '#241677ff';
  @StorageLink('shellUnselectedColor') unselectedColor: string = '#ff6b7280';
  @StorageLink('topMaskStrongColor') topMaskStrongColor: string = '#cceff1f5';
  @StorageLink('topMaskWeakColor') topMaskWeakColor: string = '#24eff1f5';

  private emit(action: string): void {
    invokeNativeTopAction(this.topBarPage, action);
  }

  private runToolAction(action: string): void {
    this.emit(action);
  }

  private secondaryFilterWidth(): number {
    const label = this.secondarySelectedMode < this.secondaryModeLabels.length
      ? this.secondaryModeLabels[this.secondarySelectedMode] : '';
    let textWidth = 0;
    for (let index = 0; index < label.length; index++) {
      textWidth += label.charCodeAt(index) <= 0xFF
        ? SECONDARY_FILTER_ASCII_WIDTH : SECONDARY_FILTER_WIDE_WIDTH;
    }
    return Math.min(
      SECONDARY_FILTER_MAX_WIDTH,
      Math.max(SECONDARY_FILTER_MIN_WIDTH, SECONDARY_FILTER_BASE_WIDTH + textWidth)
    );
  }

  @Builder
  secondaryMenu() {
    Menu() {
      ForEach(this.secondaryModeLabels, (label: string, index: number) => {
        MenuItem({
          startIcon: topIconResource(index < this.secondaryModeIcons.length
            ? this.secondaryModeIcons[index] : 'grid_view'),
          content: label
        })
          .selected(index === this.secondarySelectedMode)
          .selectIcon(true)
          .onClick(() => {
            const action = index < this.secondaryModeActions.length ? this.secondaryModeActions[index] : '';
            if (action !== '') this.emit(action);
          })
      }, (label: string, index: number) => `${this.topBarPage}_secondary_menu_${index}_${label}`)
    }
    .width(SECONDARY_MENU_WIDTH)
  }

  @Builder
  leadingButton() {
    Stack({ alignContent: Alignment.Center }) {
      Image(topIconResource(this.topLeadingIcon))
        .width(20)
        .height(20)
        .fillColor(this.unselectedColor)
    }
    .width(48)
    .height(48)
    .borderRadius(24)
    .systemMaterial(immersiveMaterial())
    .onClick(() => this.emit(this.topLeadingAction))
  }

  @Builder
  primaryModeButton(index: number) {
    Row({ space: 5 }) {
      Image(topIconResource(index < this.topModeIcons.length ? this.topModeIcons[index] : 'grid_view'))
        .width(17)
        .height(17)
        .fillColor(index === this.topSelectedMode ? this.selectedColor : this.unselectedColor)
      Text(index < this.topModeLabels.length ? this.topModeLabels[index] : '')
        .fontSize(12)
        .fontWeight(index === this.topSelectedMode ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(index === this.topSelectedMode ? this.selectedColor : this.unselectedColor)
    }
    .height(40)
    .padding({ left: 9, right: 9 })
    .borderRadius(20)
    .backgroundColor(index === this.topSelectedMode ? this.selectedContainerColor : Color.Transparent)
    .onClick(() => {
      if (index < this.topModeActions.length) this.emit(this.topModeActions[index]);
    })
  }

  @Builder
  primaryToolButton(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Image(topIconResource(index < this.topToolIcons.length ? this.topToolIcons[index] : 'grid_view'))
        .width(20)
        .height(20)
        .fillColor(index < this.topToolEnabled.length && this.topToolEnabled[index]
          ? (index < this.topToolSelected.length && this.topToolSelected[index]
            ? this.selectedColor : this.unselectedColor)
          : '#526b7280')
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor(index < this.topToolSelected.length && this.topToolSelected[index]
      ? this.selectedContainerColor : Color.Transparent)
    .enabled(index < this.topToolEnabled.length && this.topToolEnabled[index])
    .onClick(() => {
      if (index < this.topToolActions.length) this.runToolAction(this.topToolActions[index]);
    })
  }

  @Builder
  secondaryToolButton(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Image(topIconResource(index < this.secondaryToolIcons.length ? this.secondaryToolIcons[index] : 'grid_view'))
        .width(20)
        .height(20)
        .fillColor(index < this.secondaryToolEnabled.length && this.secondaryToolEnabled[index]
          ? (index < this.secondaryToolSelected.length && this.secondaryToolSelected[index]
            ? this.selectedColor : this.unselectedColor)
          : '#526b7280')
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor(index < this.secondaryToolSelected.length && this.secondaryToolSelected[index]
      ? this.selectedContainerColor : Color.Transparent)
    .enabled(index < this.secondaryToolEnabled.length && this.secondaryToolEnabled[index])
    .onClick(() => {
      if (index < this.secondaryToolActions.length) this.runToolAction(this.secondaryToolActions[index]);
    })
  }

  @Builder
  primaryRow() {
    Row({ space: 8 }) {
      if (this.topLeadingAction !== '') {
        this.leadingButton()
        Blank().layoutWeight(1)
      } else if (this.topModeLabels.length > 0) {
        Scroll() {
          Row() {
            ForEach(this.topModeLabels, (_label: string, index: number) => {
              this.primaryModeButton(index)
            }, (_label: string, index: number) => `${this.topBarPage}_${index}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(48)
        .padding(4)
        .borderRadius(24)
        .systemMaterial(immersiveMaterial())
        .layoutWeight(1)
      } else {
        Row() {
          Text(this.topTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.unselectedColor)
        }
        .height(48)
        .padding({ left: 18, right: 18 })
        .borderRadius(24)
        .systemMaterial(immersiveMaterial())
        .layoutWeight(1)
      }
      if (this.topToolActions.length > 0) {
        Row() {
          ForEach(this.topToolActions, (_action: string, index: number) => {
            this.primaryToolButton(index)
          }, (_action: string, index: number) => `${this.topBarPage}_tool_${index}`)
        }
        .width(this.topToolActions.length * 40 + 8)
        .height(48)
        .padding(4)
        .justifyContent(FlexAlign.SpaceEvenly)
        .borderRadius(24)
        .systemMaterial(immersiveMaterial())
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  secondaryRow() {
    Row({ space: 8 }) {
      Row({ space: 6 }) {
        Image(topIconResource(this.secondarySelectedMode < this.secondaryModeIcons.length
          ? this.secondaryModeIcons[this.secondarySelectedMode] : 'grid_view'))
          .width(18)
          .height(18)
          .fillColor(this.selectedColor)
        Text(this.secondarySelectedMode < this.secondaryModeLabels.length
          ? this.secondaryModeLabels[this.secondarySelectedMode] : '')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Image(topIconResource('arrow_drop_down'))
          .width(18)
          .height(18)
          .fillColor(this.selectedColor)
      }
      .height(48)
      .padding({ left: 14, right: 10 })
      .width(this.secondaryFilterWidth())
      .borderRadius(24)
      .systemMaterial(immersiveMaterial())
      .bindMenu(this.secondaryMenu, { placement: Placement.BottomLeft })
      Blank().layoutWeight(1)
      if (this.secondaryToolActions.length > 0) {
        Row() {
          ForEach(this.secondaryToolActions, (_action: string, index: number) => {
            this.secondaryToolButton(index)
          }, (_action: string, index: number) => `${this.topBarPage}_secondary_tool_${index}`)
        }
        .width(this.secondaryToolActions.length * 40 + 8)
        .height(48)
        .padding(4)
        .justifyContent(FlexAlign.SpaceEvenly)
        .borderRadius(24)
        .systemMaterial(immersiveMaterial())
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
      }
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.topMaskStrongColor, 0],
            [this.topMaskWeakColor, 0.72],
            [Color.Transparent, 1]
          ]
        })
        .hitTestBehavior(HitTestMode.Transparent)
      Column() {
        this.primaryRow()
      }
        .margin({ top: this.statusBarHeight + 8 })
        .translate({ y: this.secondaryVisible && this.collapsed ? -56 : 0 })
        .opacity(this.secondaryVisible && this.collapsed ? 0 : 1)
        .animation({ duration: 180, curve: Curve.EaseOut })
      if (this.secondaryVisible) {
        Column() {
          this.secondaryRow()
        }
          .margin({ top: this.statusBarHeight + (this.collapsed ? 8 : 64) })
          .animation({ duration: 180, curve: Curve.EaseOut })
      }
    }
    .width('100%')
    .height(this.statusBarHeight + (this.secondaryVisible && !this.collapsed ? 120 : 72))
  }
}
