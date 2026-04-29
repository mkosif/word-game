import { AppColors, PageNames } from '../common/Constants'
import { CURRENT_LEVEL_KEY } from '../model/LevelData'
import { gameState } from '../viewmodel/GameViewModel'
import { PillButton } from '../components/PillButton'
import App from '@system.app'

@Component
export struct HomePage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageLink(CURRENT_LEVEL_KEY) currentLevelId: number = 1
  @State buttonScale: number = 1.0
  private buttonPulseTimerId: number = 0

  aboutToAppear(): void {
    this.startButtonPulse()
  }

  aboutToDisappear(): void {
    if (this.buttonPulseTimerId > 0) {
      clearInterval(this.buttonPulseTimerId)
      this.buttonPulseTimerId = 0
    }
  }

  build() {
    Column() {
      Text('WORD')
        .fontSize(22)
        .fontColor(AppColors.PRIMARY_GOLD)
        .fontWeight(FontWeight.Bold)

      Text('Game').fontSize(14).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium).margin({ bottom: 10 })

      // Logo centered, gear balanced by invisible spacer on the left
      Row() {
        Text('📊')
          .fontSize(16)
          .fontColor(AppColors.WHITE)
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.LETTER_BG)
          .borderRadius(17)
          .translate({ x: 0, y: 0 })
          .onClick(() => {
            this.navPathStack.pushPathByName(PageNames.STATISTICS, null)
          })

        Text('').width(44).height(34)

        Image($r('app.media.logo')).width(90).height(90).objectFit(ImageFit.Contain).translate({ x: -16, y: 0 })
          .backgroundColor(Color.Transparent)

        Text('\u2699')
          .fontSize(20)
          .fontColor(AppColors.WHITE)
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.LETTER_BG)
          .borderRadius(17)
          .margin({ left: 10 })
          .onClick(() => {
            this.navPathStack.pushPathByName(PageNames.SETTINGS, null)
          })
      }.alignItems(VerticalAlign.Center).margin({ bottom: 12 })

      Stack() {
        PillButton(`LEVEL ${this.currentLevelId.toString()}`, AppColors.PRIMARY_GOLD, AppColors.BACKGROUND_DARK, 150, 42)
      }
      .translate({ y: -15 })
      .scale({ x: this.buttonScale, y: this.buttonScale }).onClick(() => {
        this.getUIContext().animateTo({ duration: 100 }, () => {
          this.buttonScale = 0.9
        })
        setTimeout(() => {
          this.getUIContext().animateTo({ duration: 100 }, () => {
            this.buttonScale = 1.0
          })
          gameState.loadLevel(this.currentLevelId)
          this.navPathStack.pushPathByName(PageNames.GAME, null)
        }, 100)
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND_DARK)
  }

  private startButtonPulse(): void {
    this.buttonPulseTimerId = setInterval(() => {
      this.getUIContext().animateTo({ duration: 520, curve: Curve.EaseInOut }, () => {
        this.buttonScale = 1.04
      })
      setTimeout(() => {
        this.getUIContext().animateTo({ duration: 520, curve: Curve.EaseInOut }, () => {
          this.buttonScale = 1.0
        })
      }, 540)
    }, 1500) as number
  }

}
