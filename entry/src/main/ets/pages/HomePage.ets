import { AppColors, PageNames } from '../common/Constants'
import { CURRENT_LEVEL_KEY } from '../model/LevelData'
import { gameState } from '../viewmodel/GameViewModel'
import { PillButton } from '../components/PillButton'
import { GameIconButton } from '../components/GameIconButton'

@Component
export struct HomePage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageLink(CURRENT_LEVEL_KEY) currentLevelId: number = 1
  @State buttonScale: number = 1.0

  build() {
    Column() {
      Text('WORD').fontSize(22).fontColor(AppColors.PRIMARY_GOLD).fontWeight(FontWeight.Bold)

      Text('Game').fontSize(14).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium).margin({ bottom: 10 })

      Row() {
        GameIconButton({
          icon: '\u25A3',
          buttonSize: 34,
          strokeColor: AppColors.WHITE,
          onTap: () => {
            this.navPathStack.pushPathByName(PageNames.STATISTICS, null)
          }
        })

        Text('').width(44).height(34)

        Image($r('app.media.logo')).width(90).height(90).objectFit(ImageFit.Contain).translate({ x: -16, y: 0 })
          .backgroundColor(Color.Transparent)

        GameIconButton({
          icon: '\u2699',
          buttonSize: 34,
          strokeColor: AppColors.WHITE,
          onTap: () => {
            this.navPathStack.pushPathByName(PageNames.SETTINGS, null)
          }
        }).margin({ left: 10 })
      }.alignItems(VerticalAlign.Center).margin({ bottom: 12 })

      Stack() {
        PillButton(`LEVEL ${this.currentLevelId.toString()}`, AppColors.PRIMARY_GOLD, AppColors.BACKGROUND_DARK, 150, 42)
      }.scale({ x: this.buttonScale, y: this.buttonScale }).onClick(() => {
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
}
