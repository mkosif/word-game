import { AppColors, Settings } from '../common/Constants'
import { CURRENT_LEVEL_KEY, MAX_UNLOCKED_KEY } from '../model/LevelData'
import { BackButton } from '../components/BackButton'
import { PillButton } from '../components/PillButton'
import { StatsStore } from '../components/StatsStore'
import { GameState } from '../viewmodel/GameViewModel'

@Component
export struct SettingsPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @State soundEnabled: boolean = AppStorage.get<boolean>(Settings.SOUND_ENABLED_KEY) ?? true
  @State isDarkTheme: boolean = AppStorage.get<boolean>(Settings.IS_DARK_THEME_KEY) ?? true
  @State showResetConfirm: boolean = false

  @Builder
  SoundToggleRow() {
    Row() {
      Text('\uD83D\uDD14').fontSize(15).width(22).textAlign(TextAlign.Center)

      Text('Sound').fontSize(13).fontColor(AppColors.WHITE).layoutWeight(1).margin({ left: 8 })

      Stack() {
        Rect().width(38).height(20)
          .fill(this.soundEnabled ? AppColors.SUCCESS_GREEN : AppColors.GRAY_DARK).radius(10)
        Circle().width(16).height(16).fill(AppColors.WHITE)
          .position({ x: this.soundEnabled ? 20 : 2, y: 2 })
      }.width(38).height(20)
    }
    .width('82%')
    .height(40)
    .padding({ left: 12, right: 10 })
    .backgroundColor(AppColors.LETTER_BG)
    .borderRadius(12)
    .margin({ bottom: 6 })
    .onClick(() => {
      this.soundEnabled = !this.soundEnabled
      AppStorage.set(Settings.SOUND_ENABLED_KEY, this.soundEnabled)
    })
  }

  @Builder
  ThemeToggleRow() {
    Row() {
      Text(this.isDarkTheme ? '\uD83C\uDF19' : '\u2600').fontSize(15).width(22).textAlign(TextAlign.Center)

      Text('Dark Theme').fontSize(13).fontColor(AppColors.WHITE).layoutWeight(1).margin({ left: 8 })

      Stack() {
        Rect().width(38).height(20)
          .fill(this.isDarkTheme ? AppColors.SUCCESS_GREEN : AppColors.GRAY_DARK).radius(10)
        Circle().width(16).height(16).fill(AppColors.WHITE)
          .position({ x: this.isDarkTheme ? 20 : 2, y: 2 })
      }.width(38).height(20)
    }
    .width('82%')
    .height(40)
    .padding({ left: 12, right: 10 })
    .backgroundColor(AppColors.LETTER_BG)
    .borderRadius(12)
    .margin({ bottom: 6 })
    .onClick(() => {
      this.isDarkTheme = !this.isDarkTheme
      AppStorage.set(Settings.IS_DARK_THEME_KEY, this.isDarkTheme)
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() { // Header
          Row() {
            BackButton({ btnSize: 32 })

            Text('Settings')
              .fontSize(16)
              .fontColor(AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)

            Text('').width(32)
          }.width('82%').margin({ top: 38, bottom: 12 })

          this.SoundToggleRow()

          this.ThemeToggleRow()

          // Reset progress
          if (this.showResetConfirm) {
            Column() {
              Text('Are you sure?').fontSize(12).fontColor(AppColors.WHITE).margin({ bottom: 10 })

              Row() {
                Stack() {
                  PillButton('Yes', '#FF5A5F', AppColors.WHITE, 62, 30)
                }.onClick(() => this.resetProgress())

                Stack() {
                  PillButton('No', AppColors.GRAY_DARK, AppColors.WHITE, 62, 30)
                }.margin({ left: 12 }).onClick(() => {
                  this.showResetConfirm = false
                })
              }
            }
            .width('82%')
            .padding({ top: 12, bottom: 12 })
            .backgroundColor(AppColors.LETTER_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 6 })
          } else {
            Text('\u21BA  Reset Progress')
              .fontSize(13)
              .fontColor('#FF5A5F')
              .width('82%')
              .height(40)
              .textAlign(TextAlign.Center)
              .backgroundColor(AppColors.LETTER_BG)
              .borderRadius(12)
              .margin({ bottom: 6 })
              .onClick(() => {
                this.showResetConfirm = true
              })
          }

          // About
          Column() {
            Text('Words of Wonders').fontSize(12).fontColor(AppColors.PRIMARY_GOLD).fontWeight(FontWeight.Bold)

            Text('v1.0.0').fontSize(11).fontColor(AppColors.GRAY_LIGHT).margin({ top: 2 })
          }
          .width('82%')
          .padding(10)
          .backgroundColor(AppColors.LETTER_BG)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 6 })

          Text('').height(40)
        }.alignItems(HorizontalAlign.Center).width('100%')
      }.width('100%').height('100%').backgroundColor(AppColors.BACKGROUND_DARK)
    }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND_DARK)
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