import { AppColors } from '../common/Constants'

@Component
export struct HintButton {
  @Prop isEnabled: boolean = true
  @Prop count: number = 3
  onTap?: () => void
  @State private scaleV: number = 1.0
  @State private glowV: number = 0.0
  @State private rotV: number = 0.0
  private animSeq: number = 0

  build() {
    Stack() {
      Circle()
        .width(30)
        .height(30)
        .fill('#00000033')
        .stroke(this.isEnabled ? AppColors.PRIMARY_GOLD : AppColors.GRAY_DARK)
        .strokeWidth(2)
        .opacity(this.isEnabled ? (0.82 + 0.18 * this.glowV) : 0.38)
        .shadow({
          radius: this.isEnabled ? (8 + 6 * this.glowV) : 0,
          color: this.isEnabled ? '#00000066' : Color.Transparent,
          offsetX: 0,
          offsetY: 2
        })

      Text('💡')
        .fontSize(16)
        .fontColor(this.isEnabled ? AppColors.PRIMARY_GOLD : AppColors.GRAY_DARK)
        .opacity(this.isEnabled ? 1 : 0.45)

      if (this.count > 0) {
        Text(this.count.toString())
          .fontSize(10)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .width(16)
          .height(16)
          .textAlign(TextAlign.Center)
          .backgroundColor('#111827DD')
          .borderRadius(8)
          .border({ width: 1, color: '#FFFFFF33' })
          .position({ x: 22, y: -4 })
      }
    }
    .width(34)
    .height(34)
    .backgroundColor('#00000000')
    .scale({ x: this.scaleV, y: this.scaleV })
    .rotate({ angle: this.rotV })
    .onClick(() => {
      if (!this.isEnabled) {
        return
      }

      this.playTapAnim()
      this.onTap?.()
    })
  }

  private playTapAnim(): void {
    this.animSeq += 1
    const id = this.animSeq

    this.scaleV = 1
    this.rotV = 0
    this.glowV = 0

    this.glowV = 1
    this.getUIContext().animateTo({ duration: 70, curve: Curve.EaseOut }, () => {
      this.scaleV = 1.08
    })

    setTimeout(() => {
      if (id !== this.animSeq) {
        return
      }
      this.getUIContext().animateTo({ duration: 60 }, () => {
        this.rotV = 0
      })
    }, 70)

    setTimeout(() => {
      if (id !== this.animSeq) {
        return
      }
      this.getUIContext().animateTo({ duration: 60 }, () => {
        this.rotV = -8
      })
    }, 130)

    setTimeout(() => {
      if (id !== this.animSeq) {
        return
      }
      this.getUIContext().animateTo({ duration: 50 }, () => {
        this.rotV = -8
      })
    }, 190)

    setTimeout(() => {
      if (id !== this.animSeq) {
        return
      }
      this.getUIContext().animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
        this.scaleV = 1
        this.rotV = 0
        this.glowV = 0
      })
    }, 270)
  }
}
