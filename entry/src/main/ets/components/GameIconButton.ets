import { AppColors } from '../common/Constants'

@Component
export struct GameIconButton {
  @Prop icon: string = ''
  @Prop buttonSize: number = 34
  @Prop isEnabled: boolean = true
  @Prop badge: string = ''
  @Prop strokeColor: string = AppColors.PRIMARY_GOLD
  onTap?: () => void
  @State private scaleV: number = 1

  build() {
    Stack() {
      Circle()
        .width(this.buttonSize)
        .height(this.buttonSize)
        .fill('#00000033')
        .stroke(this.isEnabled ? this.strokeColor : AppColors.GRAY_DARK)
        .strokeWidth(2)
        .opacity(this.isEnabled ? 0.92 : 0.38)
        .shadow({
          radius: this.isEnabled ? 8 : 0,
          color: this.isEnabled ? '#00000066' : Color.Transparent,
          offsetX: 0,
          offsetY: 2
        })

      Text(this.icon)
        .fontSize(Math.round(this.buttonSize * 0.48))
        .fontColor(this.isEnabled ? this.strokeColor : AppColors.GRAY_DARK)
        .fontWeight(FontWeight.Bold)
        .opacity(this.isEnabled ? 1 : 0.55)

      if (this.badge.length > 0) {
        Text(this.badge)
          .fontSize(9)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .width(16)
          .height(16)
          .textAlign(TextAlign.Center)
          .backgroundColor('#111827DD')
          .borderRadius(8)
          .border({ width: 1, color: '#FFFFFF33' })
          .position({ x: this.buttonSize - 12, y: -4 })
      }
    }
    .width(this.buttonSize + 4)
    .height(this.buttonSize + 4)
    .scale({ x: this.scaleV, y: this.scaleV })
    .onClick(() => {
      if (!this.isEnabled) {
        return
      }
      this.getUIContext().animateTo({ duration: 70, curve: Curve.EaseOut }, () => {
        this.scaleV = 0.92
      })
      setTimeout(() => {
        this.getUIContext().animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
          this.scaleV = 1
        })
      }, 70)
      this.onTap?.()
    })
  }
}
