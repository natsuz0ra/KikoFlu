import { hdsMaterial, HdsTabs } from '@kit.UIDesignKit';
import { invokeNativeTopAction } from '../plugins/HarmonyChannel';
import { topIconResource } from './ImmersiveTopBarModel';

const SECONDARY_FILTER_MIN_WIDTH = 104;
const SECONDARY_FILTER_MAX_WIDTH = 152;
const SECONDARY_FILTER_BASE_WIDTH = 80;
const SECONDARY_FILTER_ASCII_WIDTH = 7;
const SECONDARY_FILTER_WIDE_WIDTH = 12;
const SECONDARY_MENU_WIDTH = 152;
const SECONDARY_SEARCH_WIDTH = 224;

@Component
struct HdsImmersiveCapsuleMaterial {
  @Prop targetWidth: number = 0;
  @State hostWidth: number = 1;

  private materialWidth(): number {
    return this.targetWidth > 0 ? this.targetWidth : this.hostWidth;
  }

  @Builder
  emptyMaterialTab() {
    Row()
      .width('100%')
      .height('100%')
  }

  build() {
    HdsTabs() {
      TabContent() {
      }
        .tabBar(this.emptyMaterialTab)
    }
    .scrollable(false)
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .barHeight(48)
    .barFloatingStyle({
      barWidth: {
        smallWidth: this.materialWidth(),
        mediumWidth: this.materialWidth(),
        largeWidth: this.materialWidth()
      },
      barSideMargin: 0,
      barBottomMargin: 0,
      gradientMask: {
        maskColor: Color.Transparent,
        maskHeight: 0
      },
      adaptToHandedness: false,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
      }
    })
    .width('100%')
    .height(48)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      if (this.targetWidth > 0) return;
      const width = Number(newValue.width);
      if (width > 0 && Math.abs(width - this.hostWidth) > 0.5) {
        this.hostWidth = width;
      }
    })
  }
}

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
  @StorageLink('topSecondaryModeSelected') secondaryModeSelected: boolean[] = [];
  @StorageLink('topSecondaryModeEnabled') secondaryModeEnabled: boolean[] = [];
  @StorageLink('topSecondarySelectedMode') secondarySelectedMode: number = 0;
  @StorageLink('topSecondaryLayout') secondaryLayout: string = 'menu';
  @StorageLink('topSecondaryTitle') secondaryTitle: string = '';
  @StorageLink('topSecondaryInputValue') secondaryInputValue: string = '';
  @StorageLink('topSecondaryInputHint') secondaryInputHint: string = '';
  @StorageLink('topSecondaryInputAction') secondaryInputAction: string = '';
  @StorageLink('topSecondaryToolIcons') secondaryToolIcons: string[] = [];
  @StorageLink('topSecondaryToolActions') secondaryToolActions: string[] = [];
  @StorageLink('topSecondaryToolSelected') secondaryToolSelected: boolean[] = [];
  @StorageLink('topSecondaryToolEnabled') secondaryToolEnabled: boolean[] = [];
  @StorageLink('topSecondaryVisible') secondaryVisible: boolean = false;
  @StorageLink('topCollapsed') collapsed: boolean = false;
  @StorageLink('shellSelectedColor') selectedColor: string = '#ff1677ff';
  @StorageLink('shellSelectedContainerColor') selectedContainerColor: string = '#241677ff';
  @StorageLink('shellUnselectedColor') unselectedColor: string = '#ff6b7280';
  @StorageLink('shellIsDark') isDark: boolean = false;

  private capsuleShadowColor(): string {
    return this.isDark ? '#00000000' : '#24000000';
  }

  private emit(action: string): void {
    invokeNativeTopAction(this.topBarPage, action);
  }

  private runToolAction(action: string): void {
    this.emit(action);
  }

  private emitValue(action: string, value: string): void {
    invokeNativeTopAction(this.topBarPage, action, value);
  }

  private estimatedTextWidth(label: string): number {
    let textWidth = 0;
    for (let index = 0; index < label.length; index++) {
      textWidth += label.charCodeAt(index) <= 0xFF
        ? SECONDARY_FILTER_ASCII_WIDTH : SECONDARY_FILTER_WIDE_WIDTH;
    }
    return textWidth;
  }

  private secondaryFilterWidth(): number {
    const label = this.secondarySelectedMode < this.secondaryModeLabels.length
      ? this.secondaryModeLabels[this.secondarySelectedMode] : '';
    const textWidth = this.estimatedTextWidth(label);
    return Math.min(
      SECONDARY_FILTER_MAX_WIDTH,
      Math.max(SECONDARY_FILTER_MIN_WIDTH, SECONDARY_FILTER_BASE_WIDTH + textWidth)
    );
  }

  private secondaryActionWidth(): number {
    const buttonWidth = this.secondaryModeActions.length * 40 + 8;
    const titleWidth = this.secondaryTitle === ''
      ? 0 : Math.min(96, this.estimatedTextWidth(this.secondaryTitle) + 12);
    return buttonWidth + titleWidth;
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
      HdsImmersiveCapsuleMaterial({ targetWidth: 48 })
      Image(topIconResource(this.topLeadingIcon))
        .width(20)
        .height(20)
        .fillColor(this.unselectedColor)
    }
    .width(48)
    .height(48)
    .borderRadius(24)
    .clip(true)
    .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
    .hitTestBehavior(HitTestMode.Transparent)
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
    .animation({ duration: 180, curve: Curve.EaseOut })
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
  secondaryModeButton(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Image(topIconResource(index < this.secondaryModeIcons.length ? this.secondaryModeIcons[index] : 'grid_view'))
        .width(20)
        .height(20)
        .fillColor(index < this.secondaryModeEnabled.length && this.secondaryModeEnabled[index]
          ? (index < this.secondaryModeSelected.length && this.secondaryModeSelected[index]
            ? this.selectedColor : this.unselectedColor)
          : '#526b7280')
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor(index < this.secondaryModeSelected.length && this.secondaryModeSelected[index]
      ? this.selectedContainerColor : Color.Transparent)
    .enabled(index < this.secondaryModeEnabled.length && this.secondaryModeEnabled[index])
    .onClick(() => {
      if (index < this.secondaryModeActions.length) this.emit(this.secondaryModeActions[index]);
    })
  }

  @Builder
  primaryRow() {
    Row({ space: 8 }) {
      if (this.topLeadingAction !== '') {
        this.leadingButton()
        Blank().layoutWeight(1)
      } else if (this.topModeLabels.length > 0) {
        Stack({ alignContent: Alignment.Center }) {
          HdsImmersiveCapsuleMaterial()
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
          .hitTestBehavior(HitTestMode.Transparent)
        }
        .height(48)
        .borderRadius(24)
        .clip(true)
        .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
        .hitTestBehavior(HitTestMode.Transparent)
        .layoutWeight(1)
      } else {
        Stack({ alignContent: Alignment.Center }) {
          HdsImmersiveCapsuleMaterial()
          Row() {
            Text(this.topTitle)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.unselectedColor)
          }
          .width('100%')
          .height(48)
          .padding({ left: 18, right: 18 })
          .hitTestBehavior(HitTestMode.Transparent)
        }
        .height(48)
        .borderRadius(24)
        .clip(true)
        .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
        .hitTestBehavior(HitTestMode.Transparent)
        .layoutWeight(1)
      }
      if (this.topToolActions.length > 0) {
        Stack({ alignContent: Alignment.Center }) {
          HdsImmersiveCapsuleMaterial({ targetWidth: this.topToolActions.length * 40 + 8 })
          Row() {
            ForEach(this.topToolActions, (_action: string, index: number) => {
              this.primaryToolButton(index)
            }, (_action: string, index: number) => `${this.topBarPage}_tool_${index}`)
          }
          .width('100%')
          .height(48)
          .padding(4)
          .justifyContent(FlexAlign.SpaceEvenly)
          .hitTestBehavior(HitTestMode.Transparent)
        }
        .width(this.topToolActions.length * 40 + 8)
        .height(48)
        .borderRadius(24)
        .clip(true)
        .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  secondaryMenuCapsule() {
    Stack({ alignContent: Alignment.Center }) {
      HdsImmersiveCapsuleMaterial({ targetWidth: this.secondaryFilterWidth() })
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
      .width('100%')
      .height(48)
      .padding({ left: 14, right: 10 })
      .hitTestBehavior(HitTestMode.Transparent)
      .bindMenu(this.secondaryMenu, { placement: Placement.BottomLeft })
    }
    .height(48)
    .width(this.secondaryFilterWidth())
    .borderRadius(24)
    .clip(true)
    .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  secondaryActionCapsule() {
    Stack({ alignContent: Alignment.Center }) {
      HdsImmersiveCapsuleMaterial({ targetWidth: this.secondaryActionWidth() })
      Row() {
        if (this.secondaryModeActions.length > 0) {
          this.secondaryModeButton(0)
        }
        if (this.secondaryTitle !== '') {
          Text(this.secondaryTitle)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.unselectedColor)
            .maxLines(1)
            .padding({ left: 2, right: 2 })
        }
        ForEach(this.secondaryModeActions, (_action: string, index: number) => {
          if (index > 0) {
            this.secondaryModeButton(index)
          }
        }, (_action: string, index: number) => `${this.topBarPage}_secondary_mode_${index}`)
      }
      .width('100%')
      .height(48)
      .padding(4)
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .height(48)
    .width(this.secondaryActionWidth())
    .borderRadius(24)
    .clip(true)
    .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  secondarySearchCapsule() {
    Stack({ alignContent: Alignment.Center }) {
      HdsImmersiveCapsuleMaterial({ targetWidth: SECONDARY_SEARCH_WIDTH })
      Row() {
        if (this.secondaryModeActions.length > 0) {
          this.secondaryModeButton(0)
        }
        TextInput({ text: this.secondaryInputValue, placeholder: this.secondaryInputHint })
          .height(40)
          .layoutWeight(1)
          .fontSize(14)
          .fontColor(this.unselectedColor)
          .placeholderColor(this.unselectedColor)
          .caretColor(this.selectedColor)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .enterKeyType(EnterKeyType.Search)
          .onChange((value: string) => {
            if (this.secondaryInputAction !== '') {
              this.emitValue(this.secondaryInputAction, value);
            }
          })
        if (this.secondaryModeActions.length > 1) {
          this.secondaryModeButton(1)
        }
      }
      .width('100%')
      .height(48)
      .padding(4)
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .height(48)
    .width(SECONDARY_SEARCH_WIDTH)
    .borderRadius(24)
    .clip(true)
    .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  secondaryLeftCapsule() {
    if (this.secondaryLayout === 'search') {
      this.secondarySearchCapsule()
    } else if (this.secondaryLayout === 'actions') {
      this.secondaryActionCapsule()
    } else {
      this.secondaryMenuCapsule()
    }
  }

  @Builder
  secondaryRow() {
    Row({ space: 8 }) {
      this.secondaryLeftCapsule()
      Blank().layoutWeight(1)
      if (this.secondaryToolActions.length > 0) {
        Stack({ alignContent: Alignment.Center }) {
          HdsImmersiveCapsuleMaterial({ targetWidth: this.secondaryToolActions.length * 40 + 8 })
          Row() {
            ForEach(this.secondaryToolActions, (_action: string, index: number) => {
              this.secondaryToolButton(index)
            }, (_action: string, index: number) => `${this.topBarPage}_secondary_tool_${index}`)
          }
          .width('100%')
          .height(48)
          .padding(4)
          .justifyContent(FlexAlign.SpaceEvenly)
          .hitTestBehavior(HitTestMode.Transparent)
        }
        .width(this.secondaryToolActions.length * 40 + 8)
        .height(48)
        .borderRadius(24)
        .clip(true)
        .shadow({ radius: 10, color: this.capsuleShadowColor(), offsetY: 3 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
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
