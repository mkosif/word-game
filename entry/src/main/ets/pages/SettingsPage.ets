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
  @State hapticEnabled: boolean = AppStorage.get<boolean>(Settings.HAPTIC_ENABLED_KEY) ?? true
  @State isDarkTheme: boolean = AppStorage.get<boolean>(Settings.IS_DARK_THEME_KEY) ?? true
  @State showResetConfirm: boolean = false

  @Builder
  SettingIcon(icon: string) {
    Text(icon)
      .fontSize(14)
      .fontColor(AppColors.WHITE)
      .width(26)
      .height(26)
      .textAlign(TextAlign.Center)
      .backgroundColor('#00000033')
      .borderRadius(13)
  }

  @Builder
  ToggleControl(enabled: boolean) {
    Stack() {
      Rect().width(38).height(20)
        .fill(enabled ? AppColors.SUCCESS_GREEN : AppColors.GRAY_DARK).radius(10)
      Circle().width(16).height(16).fill(AppColors.WHITE)
        .position({ x: enabled ? 20 : 2, y: 2 })
    }.width(38).height(20)
  }

  @Builder
  SoundToggleRow() {
    Row() {
      this.SettingIcon('\uD83D\uDD14')

      Text('Sound').fontSize(13).fontColor(AppColors.WHITE).layoutWeight(1).margin({ left: 10 })

      this.ToggleControl(this.soundEnabled)
    }
    .width('82%')
    .height(44)
    .padding({ left: 10, right: 10 })
    .backgroundColor('#0000002E')
    .borderRadius(12)
    .margin({ bottom: 7 })
    .onClick(() => {
      this.soundEnabled = !this.soundEnabled
      AppStorage.set(Settings.SOUND_ENABLED_KEY, this.soundEnabled)
    })
  }

  @Builder
  HapticToggleRow() {
    Row() {
      this.SettingIcon('\u25CC')

      Text('Haptics').fontSize(13).fontColor(AppColors.WHITE).layoutWeight(1).margin({ left: 10 })

      this.ToggleControl(this.hapticEnabled)
    }
    .width('82%')
    .height(44)
    .padding({ left: 10, right: 10 })
    .backgroundColor('#0000002E')
    .borderRadius(12)
    .margin({ bottom: 7 })
    .onClick(() => {
      this.hapticEnabled = !this.hapticEnabled
      AppStorage.set(Settings.HAPTIC_ENABLED_KEY, this.hapticEnabled)
    })
  }

  @Builder
  ThemeToggleRow() {
    Row() {
      this.SettingIcon(this.isDarkTheme ? '\uD83C\uDF19' : '\u2600')

      Text('Dark Theme').fontSize(13).fontColor(AppColors.WHITE).layoutWeight(1).margin({ left: 10 })

      this.ToggleControl(this.isDarkTheme)
    }
    .width('82%')
    .height(44)
    .padding({ left: 10, right: 10 })
    .backgroundColor('#0000002E')
    .borderRadius(12)
    .margin({ bottom: 7 })
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

          Text('Preferences')
            .fontSize(10)
            .fontColor(AppColors.GRAY_LIGHT)
            .width('82%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 5 })

          this.SoundToggleRow()

          this.HapticToggleRow()

          this.ThemeToggleRow()

          // Reset progress
          Text('Progress')
            .fontSize(10)
            .fontColor(AppColors.GRAY_LIGHT)
            .width('82%')
            .textAlign(TextAlign.Start)
            .margin({ top: 6, bottom: 5 })

          if (this.showResetConfirm) {
            Column() {
              Text('Reset all progress?').fontSize(12).fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
                .margin({ bottom: 3 })
              Text('Levels, stats, and tutorial state will restart.')
                .fontSize(9)
                .fontColor(AppColors.GRAY_LIGHT)
                .textAlign(TextAlign.Center)
                .margin({ bottom: 10 })

              Row() {
                Stack() {
                  PillButton('RESET', '#FF5A5F', AppColors.WHITE, 74, 30)
                }.onClick(() => this.resetProgress())

                Stack() {
                  PillButton('CANCEL', AppColors.GRAY_DARK, AppColors.WHITE, 74, 30)
                }.margin({ left: 12 }).onClick(() => {
                  this.showResetConfirm = false
                })
              }
            }
            .width('82%')
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#0000002E')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 8 })
          } else {
            Row() {
              this.SettingIcon('\u21BA')
              Text('Reset Progress')
                .fontSize(13)
                .fontColor('#FF5A5F')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({ left: 10 })
              Text('!')
                .fontSize(12)
                .fontColor('#FF5A5F')
                .fontWeight(FontWeight.Bold)
                .width(20)
                .height(20)
                .textAlign(TextAlign.Center)
                .backgroundColor('#FF5A5F22')
                .borderRadius(10)
            }
              .width('82%')
              .height(44)
              .padding({ left: 10, right: 10 })
              .backgroundColor('#0000002E')
              .borderRadius(12)
              .margin({ bottom: 8 })
              .onClick(() => {
                this.showResetConfirm = true
              })
          }

          // About
          Text('About')
            .fontSize(10)
            .fontColor(AppColors.GRAY_LIGHT)
            .width('82%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 5 })

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
