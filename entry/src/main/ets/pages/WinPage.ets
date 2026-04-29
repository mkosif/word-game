import { AppColors, difficultyBgColor } from '../common/Constants'
import { getTotalLevels } from '../model/LevelData'
import { gameState } from '../viewmodel/GameViewModel'
import { StatsStore } from '../components/StatsStore'
import { secureRandomNumber } from '../utils/SecureRandom'

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

@Component
export struct WinPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @State currentLevel: number = 1
  @State starScales: number[] = [0, 0, 0, 0, 0]
  @State earnedStars: number = 3
  @State bgColor: string = AppColors.BACKGROUND_DARK
  @State showConfetti: boolean = false
  @State confettiOpacity: number = 0
  @State scoreValue: number = 0
  @State wordsFound: number = 0
  @State wordsTotal: number = 0
  @State bonusFound: number = 0
  @State bonusTotal: number = 0
  @State completionTime: string = '--'
  @State fastestTime: string = '--'
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
    this.scoreValue = Math.round(this.levelScore)
    this.wordsFound = gameState.foundWords.length
    this.wordsTotal = gameState.wordSlots.length
    this.bonusFound = gameState.bonusWordsFound.length
    this.bonusTotal = gameState.currentLevel && gameState.currentLevel.bonusWords ?
      gameState.currentLevel.bonusWords.length : 0
    this.completionTime = this.formatDuration(StatsStore.getLastCompletedLevelMs())
    const fastest = StatsStore.getFastest()
    this.fastestTime = fastest && fastest.levelId === this.currentLevel ? this.formatDuration(fastest.durationMs) : '--'
    this.earnedStars = this.calcStars()
    this.bgColor = difficultyBgColor(gameState.currentLevel?.difficulty ?? 'medium')
    this.startStarReveal()
    this.startConfetti()
  }

  private startStarReveal(): void {
    const ui = this.getUIContext()
    const visibleStars = Math.min(3, this.earnedStars)

    for (let i = 0; i < visibleStars; i++) {
      const idx = i

      setTimeout(() => {
        const s1 = this.starScales.slice()
        s1[idx] = 1.42
        ui.animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
          this.starScales = s1
        })

        setTimeout(() => {
          const s2 = this.starScales.slice()
          s2[idx] = 0.94
          ui.animateTo({ duration: 80, curve: Curve.EaseIn }, () => {
            this.starScales = s2
          })

          setTimeout(() => {
            const s3 = this.starScales.slice()
            s3[idx] = 1.0
            ui.animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
              this.starScales = s3
            })
          }, 90)
        }, 130)
      }, 160 + idx * 170)
    }
  }

  aboutToDisappear(): void {
    this.stopConfetti()
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Text('WELL DONE')
            .fontSize(18)
            .fontColor(AppColors.SUCCESS_GREEN)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 2 })

          Row() {
            ForEach(this.mainStars, (starIndex: number) => {
              Text('\u2605')
                .fontSize(31)
                .fontColor(starIndex <= this.earnedStars ? AppColors.STAR_GOLD : AppColors.GRAY_DARK)
                .margin(2)
                .scale({ x: this.starScales[starIndex - 1], y: this.starScales[starIndex - 1] })
            }, (starIndex: number) => `star_ ${starIndex.toString()}`)
          }.margin({ bottom: 4 })

          Text(`Level ${this.currentLevel.toString()}`).fontSize(17).fontColor(AppColors.WHITE)

          Text('Completed').fontSize(12).fontColor(AppColors.GRAY_LIGHT).margin({ bottom: 6 })

          Row() {
            this.StatChip('Score', this.scoreValue.toString())
            this.StatChip('Time', this.completionTime)
            this.StatChip('Words', `${this.wordsFound.toString()}/${this.wordsTotal.toString()}`)
          }
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })

          // Buttons
          Column() {
            if (this.currentLevel < getTotalLevels()) {
              Stack() {
                this.WinActionButton('NEXT', AppColors.PRIMARY_GOLD, this.bgColor, 116, 36, 16)
              }.onClick(() => {
                gameState.loadLevel(this.currentLevel + 1)
                this.navPathStack.pop()
              })
            } else {
              Stack() {
                this.WinActionButton('HOME', AppColors.PRIMARY_GOLD, this.bgColor, 116, 36, 16)
              }.onClick(() => {
                this.navPathStack.clear()
              })
            }
          }
        }
        .justifyContent(FlexAlign.Start)
        .padding({ left: 0, right: 0 })
        .alignItems(HorizontalAlign.Center)
        .width(190)
        .height(190)
        .position({ x: 21, y: 26 })

        if (this.showConfetti) {
          Canvas(this.confettiCtx)
            .width(200)
            .height(200)
            .opacity(this.confettiOpacity)
            .onReady(() => {
              this.drawConfetti()
            })
            .position({ x: 0, y: 0 })
            .hitTestBehavior(HitTestMode.None)
        }
      }.width('100%').height('100%').backgroundColor(this.bgColor)

    }.hideTitleBar(true).backgroundColor(this.bgColor)
  }

  @Builder
  private StatChip(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(14)
        .fontColor(AppColors.WHITE)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(9)
        .fontColor(AppColors.GRAY_LIGHT)
    }
    .width(55)
    .height(35)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#00000040')
    .borderRadius(8)
    .margin({ left: 2, right: 2 })
  }

  @Builder
  private WinActionButton(text: string, fillColor: string, textColor: string, width: number, height: number,
    fontSize: number) {
    Stack() {
      Rect()
        .width(width)
        .height(height)
        .fill(fillColor)
        .radius(height / 2)
      Text(text)
        .fontSize(fontSize)
        .fontColor(textColor)
        .fontWeight(FontWeight.Bold)
    }
  }

  private formatDuration(durationMs: number): string {
    if (durationMs < 0) {
      return '--'
    }
    const totalSeconds = Math.max(0, Math.floor(durationMs / 1000))
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    if (minutes <= 0) {
      return `${seconds.toString()}s`
    }
    const secText = seconds < 10 ? `0${seconds.toString()}` : seconds.toString()
    return `${minutes.toString()}:${secText}`
  }

  private startConfetti(): void {
    this.confettiOpacity = 1
    this.showConfetti = true
    this.confettiParts = []
    const colors: string[] = [AppColors.PRIMARY_GOLD, AppColors.SUCCESS_GREEN, '#FF5A5F', '#4DA3FF', '#FFFFFF']

    for (let i = 0; i < 28; i++) {
      const angle = secureRandomNumber() * Math.PI * 2
      const speed = 1.1 + secureRandomNumber() * 2.1
      const x = 100 + (secureRandomNumber() - 0.5) * 18
      const y = 74 + (secureRandomNumber() - 0.5) * 10
      const vx = Math.cos(angle) * speed
      const vy = Math.sin(angle) * speed - 0.9
      const size = 2.5 + secureRandomNumber() * 3.5
      const vr = (secureRandomNumber() - 0.5) * 10
      const life = 42 + Math.floor(secureRandomNumber() * 24)
      const c = colors[Math.floor(secureRandomNumber() * colors.length)]
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
    }, 2600)
  }

  private stopConfetti(): void {
    this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
      this.confettiOpacity = 0
    })

    setTimeout(() => {
      if (this.confettiTimerId > 0) {
        clearInterval(this.confettiTimerId)
        this.confettiTimerId = 0
      }
      this.showConfetti = false
      this.confettiCtx?.clearRect(0, 0, 200, 200)
    }, 340)
  }

  private updateConfetti(): void {
    for (let i = 0; i < this.confettiParts.length; i++) {
      const p = this.confettiParts[i]
      if (p.life <= 0) {
        continue
      }

      p.vx += (secureRandomNumber() - 0.5) * 0.05
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
