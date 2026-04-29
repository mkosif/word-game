import { AppColors, Settings } from '../common/Constants'
import { CURRENT_LEVEL_KEY, MAX_UNLOCKED_KEY } from '../model/LevelData'
import { PillButton } from '../components/PillButton'
import { StatsStore } from '../components/StatsStore'
import { GameState } from '../viewmodel/GameViewModel'

const SOUND_ENABLED_STORAGE_KEY: string = Settings.SOUND_ENABLED_KEY
const HAPTIC_ENABLED_STORAGE_KEY: string = Settings.HAPTIC_ENABLED_KEY
const IS_DARK_THEME_STORAGE_KEY: string = Settings.IS_DARK_THEME_KEY

interface ToggleRowOptions {
  icon: string
  label: string
  enabled: boolean
  onTap: () => void
}

@Component
export struct SettingsPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageLink(SOUND_ENABLED_STORAGE_KEY) soundEnabled: boolean = true
  @StorageLink(HAPTIC_ENABLED_STORAGE_KEY) hapticEnabled: boolean = true
  @StorageLink(IS_DARK_THEME_STORAGE_KEY) isDarkTheme: boolean = true
  @State showResetConfirm: boolean = false

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            Text('Settings')
              .fontSize(18)
              .fontColor(AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
          }
          .width('84%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 30, bottom: 10 })

          this.ToggleRow({ icon: '\uD83D\uDD14', label: 'Sound', enabled: this.soundEnabled, onTap: () => {
            this.soundEnabled = !this.soundEnabled
          }})

          this.ToggleRow({ icon: '\u25CC', label: 'Haptics', enabled: this.hapticEnabled, onTap: () => {
            this.hapticEnabled = !this.hapticEnabled
          }})

          this.ToggleRow({ icon: this.isDarkTheme ? '\uD83C\uDF19' : '\u2600', label: 'Dark', enabled: this.isDarkTheme, onTap: () => {
            this.isDarkTheme = !this.isDarkTheme
          }})

          if (this.showResetConfirm) {
            Column() {
              Text('Reset progress?')
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })

              Row() {
                Stack() {
                  PillButton('YES', '#FF5A5F', AppColors.WHITE, 58, 28)
                }.onClick(() => this.resetProgress())

                Stack() {
                  PillButton('NO', AppColors.GRAY_DARK, AppColors.WHITE, 58, 28)
                }.margin({ left: 10 }).onClick(() => {
                  this.showResetConfirm = false
                })
              }
            }
            .width('84%')
            .height(70)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(AppColors.LETTER_BG)
            .borderRadius(12)
            .margin({ bottom: 6 })
          } else {
            Text('\u21BA  Reset Progress')
              .fontSize(13)
              .fontColor('#FF5A5F')
              .fontWeight(FontWeight.Bold)
              .width('84%')
              .height(38)
              .textAlign(TextAlign.Center)
              .backgroundColor(AppColors.LETTER_BG)
              .borderRadius(12)
              .margin({ bottom: 6 })
              .onClick(() => {
                this.showResetConfirm = true
              })
          }

          Column() {
            Text('Words of Wonders')
              .fontSize(12)
              .fontColor(AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)

            Text('v1.0.0')
              .fontSize(10)
              .fontColor(AppColors.GRAY_LIGHT)
              .margin({ top: 2 })
          }
          .width('84%')
          .height(44)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(AppColors.LETTER_BG)
          .borderRadius(12)
          .margin({ bottom: 28 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(AppColors.BACKGROUND_DARK)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .backgroundColor(AppColors.BACKGROUND_DARK)
    }
    .hideTitleBar(true)
    .backgroundColor(AppColors.BACKGROUND_DARK)
  }

  @Builder
  private ToggleRow($$: ToggleRowOptions) {
    Row() {
      Text($$.icon)
        .fontSize(14)
        .width(24)
        .textAlign(TextAlign.Center)

      Text($$.label)
        .fontSize(13)
        .fontColor(AppColors.WHITE)
        .layoutWeight(1)
        .margin({ left: 8 })

      Stack() {
        Rect()
          .width(36)
          .height(20)
          .fill($$.enabled ? AppColors.SUCCESS_GREEN : AppColors.GRAY_DARK)
          .radius(10)
        Circle()
          .width(16)
          .height(16)
          .fill(AppColors.WHITE)
          .position({ x: $$.enabled ? 18 : 2, y: 2 })
      }
      .width(36)
      .height(20)
    }
    .width('84%')
    .height(38)
    .padding({ left: 10, right: 10 })
    .backgroundColor(AppColors.LETTER_BG)
    .borderRadius(12)
    .margin({ bottom: 6 })
    .onClick($$.onTap)
  }

  private resetProgress(): void {
    AppStorage.set(MAX_UNLOCKED_KEY, 1)
    AppStorage.set(CURRENT_LEVEL_KEY, 1)
    AppStorage.set<boolean>(GameState.TUTORIAL_DONE, false)
    StatsStore.reset()
    this.showResetConfirm = false
    this.navPathStack.clear()
  }
}
