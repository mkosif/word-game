import { AppColors } from '../common/Constants'

@Component
export struct BackButton {
  @Consume('navPathStack') navPathStack: NavPathStack
  @Prop btnSize: number = 32
  @Prop bgColor: string = AppColors.LETTER_BG
  onBack?: () => void

  build() {
    Text('\u2190')
      .fontSize(Math.round(this.btnSize * 0.56))
      .fontColor(AppColors.WHITE)
      .width(this.btnSize)
      .height(this.btnSize)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.bgColor)
      .borderRadius(this.btnSize / 2)
      .onClick(() => {
        if (this.onBack) {
          this.onBack()
        } else {
          this.navPathStack.pop()
        }
      })
  }
}
