import { AppColors, difficultyBgColor } from '../common/Constants'
import { getTotalLevels } from '../model/LevelData'
import { gameState } from '../viewmodel/GameViewModel'
import { BackButton } from '../components/BackButton'
import { PillButton } from '../components/PillButton'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'

class ConfettiPiece {
  x: number = 0
  y: number = 0
  vx: number = 0
  vy: number = 0
  rot: number = 0
  vr: number = 0
  size: number = 0
  life: number = 0
  color: string = '#FFFFFF'

  constructor(x: number, y: number, vx: number, vy: number, size: number, vr: number, life: number, color: string) {
    this.x = x
    this.y = y
    this.vx = vx
    this.vy = vy
    this.size = size
    this.vr = vr
    this.life = life
    this.rot = 0
    this.color = color
  }
}

function getRandomValue(): number {
  try {
    const random = cryptoFramework.createRandom();
    const randomBytes = random.generateRandomSync(4);
    const view = new DataView(randomBytes.data.buffer);
    const randomUint32 = view.getUint32(0, false);
    return randomUint32 / 4294967296;
  } catch (error) {
    console.error('Random generation error:', error);
    return 1
  }
}

@Component
export struct WinPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @State currentLevel: number = 1
  @State starScales: number[] = [0, 0, 0, 0, 0]
  @State earnedStars: number = 3
  @State bgColor: string = AppColors.BACKGROUND_DARK
  @State showConfetti: boolean = false
  @State confettiOpacity: number = 0
  private levelScore: number = 0
  private mainStars: number[] = [1, 2, 3]
  private bonusStars: number[] = [4, 5]
  private confettiSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private confettiCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.confettiSettings)
  private confettiTimerId: number = 0
  private confettiParts: ConfettiPiece[] = []

  aboutToAppear(): void {
    this.currentLevel = gameState.currentLevelId
    this.levelScore = gameState.levelScore
    this.earnedStars = this.calcStars()
    this.bgColor = difficultyBgColor(gameState.currentLevel?.difficulty ?? 'medium')
    this.startStarReveal()
    this.startConfetti()
  }

  private startStarReveal(): void {
    const ui = this.getUIContext()
    let scales: number[] = this.starScales.slice()
    let starScales: number[] = [];

    for (let i = 0; i < 5; i++) {
      const idx = i

      setTimeout(() => {
        const s1 = scales.slice()
        s1[idx] = 1.3
        scales = s1
        ui.animateTo({ duration: 150, curve: Curve.EaseIn }, () => {
          starScales = s1
        })

        setTimeout(() => {
          const s2 = scales.slice()
          s2[idx] = 1.0
          scales = s2
          ui.animateTo({ duration: 150, curve: Curve.EaseIn }, () => {
            starScales = s2
          })
        }, 250)
      }, 200 + idx * 250)
    }
    this.starScales = starScales
  }

  aboutToDisappear(): void {
    this.stopConfetti()
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Text('WELL DONE!')
            .fontSize(20)
            .fontColor(AppColors.SUCCESS_GREEN)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 6, bottom: 4 })

          Row() {
            ForEach(this.mainStars, (starIndex: number) => {
              Text('\u2605')
                .fontSize(36)
                .fontColor(starIndex <= this.earnedStars ? AppColors.STAR_GOLD : AppColors.GRAY_DARK)
                .margin(3)
                .scale({ x: this.starScales[starIndex - 1], y: this.starScales[starIndex - 1] })
            }, (starIndex: number) => `star_ ${starIndex.toString()}`)
          }.margin({ top: -4, bottom: -22 })

          Row() {
            ForEach(this.bonusStars, (starIndex: number) => {
              Text('\u2605')
                .fontSize(36)
                .fontColor(starIndex <= this.earnedStars ? AppColors.STAR_GOLD : 'transparent')
                .margin(3)
                .scale({ x: this.starScales[starIndex - 1], y: this.starScales[starIndex - 1] })
            }, (starIndex: number) => `star_ ${starIndex.toString()}`)
          }.margin({ bottom: 6 })

          Text(`Level ${this.currentLevel.toString()}`).fontSize(16).fontColor(AppColors.WHITE)

          Text('Completed').fontSize(12).fontColor(AppColors.GRAY_LIGHT).margin({ bottom: 6 })

          // Buttons
          Column() {
            if (this.currentLevel < getTotalLevels()) {
              Stack() {
                PillButton('NEXT', AppColors.PRIMARY_GOLD, this.bgColor, 120, 44)
              }.onClick(() => {
                gameState.loadLevel(this.currentLevel + 1)
                this.navPathStack.pop()
              }).margin({ bottom: 8 })
            }
          }
        }
        .justifyContent(FlexAlign.Center)
        .padding({ top: 20 })
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')

        if (this.showConfetti) {
          Canvas(this.confettiCtx)
            .width(200)
            .height(200)
            .opacity(this.confettiOpacity)
            .onReady(() => {
              this.drawConfetti()
            })
            .position({ x: 0, y: 0 })
        }
      }.width('100%').height('100%').backgroundColor(this.bgColor)

      BackButton({
        btnSize: 36, onBack: () => {
          this.navPathStack.clear()
        }
      }).position({ x: 24, y: 4 })
    }.hideTitleBar(true).backgroundColor(this.bgColor)
  }

  private startConfetti(): void {
    this.confettiOpacity = 1
    this.showConfetti = true
    this.confettiParts = []
    const w = 200
    const h = 200

    const colors: string[] = [AppColors.PRIMARY_GOLD, AppColors.SUCCESS_GREEN, '#FF5A5F', '#4DA3FF', '#FFFFFF']

    for (let i = 0; i < 24; i++) {
      const x = getRandomValue() * w
      const y = -10 - getRandomValue() * 40
      const vx = (getRandomValue() - 0.5) * 1.6
      const vy = 1.2 + getRandomValue() * 1.6
      const size = 3 + getRandomValue() * 4
      const vr = (getRandomValue() - 0.5) * 10
      const life = 60 + Math.floor(getRandomValue() * 25)
      const c = colors[Math.floor(getRandomValue() * colors.length)]
      this.confettiParts.push(new ConfettiPiece(x, y, vx, vy, size, vr, life, c))
    }

    if (this.confettiTimerId > 0) {
      clearInterval(this.confettiTimerId)
      this.confettiTimerId = 0
    }

    this.confettiTimerId = setInterval(() => {
      this.updateConfetti()
      this.drawConfetti()
    }, 33) as number

    setTimeout(() => {
      this.stopConfetti()
    }, 4200)
  }

  private stopConfetti(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.confettiOpacity = 0
    })

    setTimeout(() => {
      if (this.confettiTimerId > 0) {
        clearInterval(this.confettiTimerId)
        this.confettiTimerId = 0
      }
      this.showConfetti = false
      this.confettiCtx?.clearRect(0, 0, 200, 200)
    }, 260)
  }

  private updateConfetti(): void {
    for (let i = 0; i < this.confettiParts.length; i++) {
      const p = this.confettiParts[i]
      if (p.life <= 0) {
        continue
      }

      p.vx += (getRandomValue() - 0.5) * 0.05
      p.vy += 0.04
      p.x += p.vx
      p.y += p.vy
      p.rot += p.vr
      p.life -= 1
    }
  }

  private drawConfetti(): void {
    const ctx = this.confettiCtx
    ctx.clearRect(0, 0, 200, 200)

    for (let i = 0; i < this.confettiParts.length; i++) {
      const p = this.confettiParts[i]
      if (p.life <= 0) {
        continue
      }

      ctx.save()
      ctx.translate(p.x, p.y)
      ctx.rotate(p.rot * Math.PI / 180)
      ctx.fillStyle = p.color
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 1.6)
      ctx.restore()
    }
  }

  private calcStars(): number {
    if (this.levelScore >= 81) {
      return 5
    }
    if (this.levelScore >= 61) {
      return 4
    }
    if (this.levelScore >= 41) {
      return 3
    }
    if (this.levelScore >= 21) {
      return 2
    }
    if (this.levelScore >= 1) {
      return 1
    }
    return 0
  }
}