import { AppColors, AppSizes, difficultyBgColor, GameLayout, PageNames } from '../common/Constants'
import { GameState, gameState, LetterItem, WordSlot } from '../viewmodel/GameViewModel'
import { CURRENT_LEVEL_KEY, DEFAULT_LEVEL_LAYOUT, LevelLayout } from '../model/LevelData'
import { HintButton } from '../components/HintButton'
import { BackButton } from '../components/BackButton'
import { soundManager, SoundNames } from '../common/SoundManager'
import { hapticManager, HapticNames } from '../common/HapticManager'
import { StatsStore } from '../components/StatsStore'
import { window } from '@kit.ArkUI'

class LinePoint {
  x: number = 0
  y: number = 0

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}

class CrosswordCell {
  isActive: boolean = false
  row: number = -1
  col: number = -1
  slotIndex: number = -1
  letterIndex: number = -1
  letter: string = ''
  isFound: boolean = false
  isRevealed: boolean = false
  revealedIndexes: number[] = []

  isLetterRevealed(): boolean {
    if (this.isRevealed) {
      return true
    }
    for (let i = 0; i < this.revealedIndexes.length; i++) {
      if (this.revealedIndexes[i] === this.letterIndex) {
        return true
      }
    }
    return false
  }
}

class CrosswordRow {
  cells: CrosswordCell[] = []
  id: string = ''
}

@Component
export struct GamePage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageLink(CURRENT_LEVEL_KEY)
  @Watch('onActiveLevelChanged')
  activeLevelId: number = 1
  @State letters: LetterItem[] = []
  @State currentWord: string = ''
  @State wordSlots: WordSlot[] = []
  @State showError: boolean = false
  @State showSuccess: boolean = false
  @State linePoints: LinePoint[] = []
  @State currentTouchX: number = 0
  @State currentTouchY: number = 0
  @State isDragging: boolean = false
  @State hintCount: number = 3
  @State bonusWordsFound: number = 0
  @State bonusWordsTotal: number = 0
  @State showTutorial: boolean = false
  @State hintPosX: number = 0
  @State hintPosY: number = 0
  @State bonusPosX: number = 0
  @State bonusPosY: number = 0
  @State shufflePosX: number = 0
  @State shufflePosY: number = 0
  @State letterPos: number[] = []
  @State pressedLetterId: string = ''
  @State snapLetterId: string = ''
  @State snapLetterScale: number = 1
  @State wrongFlash: boolean = false
  @State wrongShakeX: number = 0
  @State successFlashSlotIndex: number = -1
  @State successFlashOn: boolean = false
  @State showBonusPopup: boolean = false
  @State bonusWordFound: string = ''
  @State bonusPopupScale: number = 0
  @State bonusPopupOpacity: number = 0
  @State lineFeedback: string = 'normal'
  @State feedbackLetterIds: number[] = []
  @State hintFlashKeys: string[] = []
  @State hintFlashOn: boolean = false
  @State hintFlashPhase: number = 0
  @State revealedCellKeys: string[] = []
  @State bgColor: string = AppColors.BACKGROUND_DARK
  @State crosswordRows: CrosswordRow[] = []
  @State crosswordCellSize: number = 20
  @State crosswordFontSize: number = 13
  @State crosswordRevision: number = 0
  @State crosswordOffsetY: number = DEFAULT_LEVEL_LAYOUT.crosswordOffsetY
  private pageEnterMs: number = 0
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private bonusCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private bonusCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.bonusCanvasSettings)
  private ignoreCurrentPan: boolean = false
  private lastHintTapMs: number = 0
  private hintFlashSeq: number = 0
  private revealedLevelId: number = 0
  private lineAnimTimerId: number = 0
  private readonly LETTER_CENTER: number = GameLayout.LETTER_SIZE / 2
  private readonly CANVAS_SIZE: number = AppSizes.SCREEN_SIZE
  private readonly TOUCH_THRESHOLD: number = GameLayout.TOUCH_THRESHOLD + 4

  get isTutorialDone(): boolean {
    return AppStorage.get<boolean>(GameState.TUTORIAL_DONE) ?? false
  }

  set isTutorialDone(v: boolean) {
    AppStorage.set<boolean>(GameState.TUTORIAL_DONE, v)
  }

  aboutToAppear(): void {
    this.setGestureBackEnabled(false)
    gameState.ensureTutorialOnFirstLaunch()
    this.pageEnterMs = Date.now()
    this.refreshState()
  }

  aboutToDisappear(): void {
    this.stopLineAnimationLoop()
    this.setGestureBackEnabled(true)
    const delta = Date.now() - this.pageEnterMs
    StatsStore.addPlayTimeMs(delta)
  }

  private setGestureBackEnabled(enabled: boolean): void {
    const context = this.getUIContext().getHostContext()
    if (!context) {
      console.warn('[GamePage] host context unavailable')
      return
    }
    window.getLastWindow(context).then((mainWindow: window.Window) => {
      mainWindow.setGestureBackEnabled(enabled).catch((error: Error) => {
        console.warn(`[GamePage] setGestureBackEnabled(${enabled}) failed: ${JSON.stringify(error)}`)
      })
    }).catch((error: Error) => {
      console.warn(`[GamePage] getLastWindow failed: ${JSON.stringify(error)}`)
    })
  }

  refreshState(): void {
    this.currentWord = gameState.currentWord
    this.showError = gameState.showError
    this.showTutorial = gameState.showTutorial
    const newLetters: LetterItem[] = []
    for (let i = 0; i < gameState.letters.length; i++) {
      newLetters.push(gameState.letters[i].clone())
    }
    this.letters = newLetters
    const newSlots: WordSlot[] = []
    for (let i = 0; i < gameState.wordSlots.length; i++) {
      newSlots.push(gameState.wordSlots[i].clone())
    }
    this.wordSlots = newSlots
    this.syncRevealedCellKeys()
    this.updateLinePoints()
    this.hintCount = gameState.hintCount
    this.bonusWordsFound = gameState.bonusWordsFound.length
    this.bonusWordsTotal =
      gameState.currentLevel && gameState.currentLevel.bonusWords ? gameState.currentLevel.bonusWords.length : 0
    this.syncLevelLayout()
    this.hintPosX = gameState.hintPos[0]
    this.hintPosY = gameState.hintPos[1]
    this.bonusPosX = gameState.bonusPos[0]
    this.bonusPosY = gameState.bonusPos[1]
    this.shufflePosX = gameState.shufflePos[0]
    this.shufflePosY = gameState.shufflePos[1]
    this.drawBonusIndicator()
    this.syncLetterPos()
    this.crosswordRows = this.buildCrosswordGrid()
    this.crosswordRevision += 1
    this.bgColor = difficultyBgColor(gameState.currentLevel?.difficulty ?? 'medium')
  }

  syncLetterPos(): void {
    const pos: number[] = []
    for (let i = 0; i < this.letters.length; i++) {
      pos.push(this.letters[i].x)
      pos.push(this.letters[i].y)
    }
    this.letterPos = pos
  }

  onActiveLevelChanged(): void {
    this.resetTransientUiState()
    this.refreshState()
  }

  private resetTransientUiState(): void {
    this.clearFeedback()
    this.showSuccess = false
    this.showError = false
    this.wrongFlash = false
    this.wrongShakeX = 0
    this.successFlashSlotIndex = -1
    this.successFlashOn = false
    this.showBonusPopup = false
    this.bonusPopupScale = 0
    this.bonusPopupOpacity = 0
    this.hintFlashSeq += 1
    this.hintFlashKeys = []
    this.hintFlashOn = false
    this.hintFlashPhase = 0
    this.pressedLetterId = ''
    this.snapLetterId = ''
    this.snapLetterScale = 1
  }

  private syncLevelLayout(): void {
    const layout: LevelLayout = gameState.currentLevel?.layout ?? DEFAULT_LEVEL_LAYOUT
    this.crosswordOffsetY = layout.crosswordOffsetY
  }

  drawBonusIndicator(): void {
    if (this.bonusWordsTotal <= 0) {
      return
    }
    const size = 30
    const center = size / 2
    const radius = 12
    this.bonusCanvasCtx.clearRect(0, 0, size, size)
    this.bonusCanvasCtx.beginPath()
    this.bonusCanvasCtx.arc(center, center, radius, 0, 2 * Math.PI)
    this.bonusCanvasCtx.strokeStyle = AppColors.GRAY_DARK
    this.bonusCanvasCtx.lineWidth = 3
    this.bonusCanvasCtx.stroke()

    if (this.bonusWordsFound > 0) {
      const progress = this.bonusWordsFound / this.bonusWordsTotal
      const startAngle = -Math.PI / 2
      const endAngle = startAngle + (2 * Math.PI * progress)
      this.bonusCanvasCtx.beginPath()
      this.bonusCanvasCtx.arc(center, center, radius, startAngle, endAngle)
      this.bonusCanvasCtx.strokeStyle = AppColors.SUCCESS_GREEN
      this.bonusCanvasCtx.lineWidth = 3
      this.bonusCanvasCtx.lineCap = 'round'
      this.bonusCanvasCtx.stroke()
    }
  }

  updateLinePoints(): void {
    const points: LinePoint[] = []
    for (let i = 0; i < gameState.selectedLetters.length; i++) {
      const letter = gameState.selectedLetters[i]
      points.push(new LinePoint(letter.x + this.LETTER_CENTER, letter.y + this.LETTER_CENTER))
    }
    this.linePoints = points
  }

  drawLines(): void { // Clear canvas
    this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    if (this.linePoints.length === 0) {
      return
    }
    this.canvasContext.lineCap = 'round'
    this.canvasContext.lineJoin = 'round'
    if (this.lineFeedback === 'wrong') {
      this.canvasContext.strokeStyle = '#FF5252'
    } else if (this.lineFeedback === 'success') {
      this.canvasContext.strokeStyle = AppColors.LINE_GREEN
    } else if (this.linePoints.length > 1) {
      const first = this.linePoints[0]
      const last = this.linePoints[this.linePoints.length - 1]
      const gradient = this.canvasContext.createLinearGradient(first.x, first.y, last.x, last.y)
      gradient.addColorStop(0, '#FFE08A')
      gradient.addColorStop(1, AppColors.PRIMARY_GOLD)
      this.canvasContext.strokeStyle = gradient
    } else {
      this.canvasContext.strokeStyle = '#FFE08A'
    }
    const minW = 1.4
    const maxW = 3
    const totalSegments = Math.max(1, this.linePoints.length - 1)
    this.canvasContext.shadowColor = this.lineFeedback === 'wrong' ? '#FF5252' :
      (this.lineFeedback === 'success' ? AppColors.LINE_GREEN : AppColors.PRIMARY_GOLD)
    this.canvasContext.shadowBlur = this.lineFeedback === 'normal' ? 5 : 9

    this.drawLineGlow()

    for (let i = 1; i < this.linePoints.length; i++) {
      const p0 = this.linePoints[i - 1]
      const p1 = this.linePoints[i]
      const t = (i - 1) / totalSegments
      const w = (this.lineFeedback === 'normal' ? minW : 3) + (maxW - minW) * Math.sin(Math.PI * t)
      this.canvasContext.lineWidth = w
      this.canvasContext.beginPath()
      this.canvasContext.moveTo(p0.x, p0.y)
      this.canvasContext.lineTo(p1.x, p1.y)
      this.canvasContext.stroke()
    }
    if (this.isDragging && this.lineFeedback === 'normal' && this.linePoints.length > 0) {
      const last = this.linePoints[this.linePoints.length - 1]
      this.canvasContext.lineWidth = 1.6
      this.canvasContext.beginPath()
      this.canvasContext.moveTo(last.x, last.y)
      this.canvasContext.lineTo(this.currentTouchX, this.currentTouchY)
      this.canvasContext.stroke()
      this.drawLiveLineTip()
    }
    for (let i = 0; i < this.linePoints.length; i++) {
      const point = this.linePoints[i]
      this.canvasContext.beginPath()
      this.canvasContext.arc(point.x, point.y, this.lineFeedback === 'normal' ? 2.2 : 3.2, 0, 2 * Math.PI)
      this.canvasContext.fillStyle = this.lineFeedback === 'wrong' ? '#FF5252' :
        (this.lineFeedback === 'success' ? AppColors.LINE_GREEN : '#FFE08A')
      this.canvasContext.fill()
    }
    this.canvasContext.shadowBlur = 0
    this.canvasContext.shadowColor = 'transparent'
  }

  private drawLineGlow(): void {
    if (this.linePoints.length < 2) {
      return
    }
    const glowColor = this.lineFeedback === 'wrong' ? '#FF525226' :
      (this.lineFeedback === 'success' ? '#76FF0326' : '#F5A62328')
    this.canvasContext.save()
    this.canvasContext.lineCap = 'round'
    this.canvasContext.lineJoin = 'round'
    this.canvasContext.strokeStyle = glowColor
    this.canvasContext.lineWidth = this.lineFeedback === 'normal' ? 3.5 : 5
    this.canvasContext.shadowColor = glowColor
    this.canvasContext.shadowBlur = 6
    this.canvasContext.beginPath()
    this.canvasContext.moveTo(this.linePoints[0].x, this.linePoints[0].y)
    for (let i = 1; i < this.linePoints.length; i++) {
      this.canvasContext.lineTo(this.linePoints[i].x, this.linePoints[i].y)
    }
    this.canvasContext.stroke()
    this.canvasContext.restore()
  }

  private drawLiveLineTip(): void {
    const pulse = 0.5 + 0.5 * Math.sin(Date.now() / 140)
    const radius = 2.4 + pulse * 1
    this.canvasContext.save()
    this.canvasContext.shadowColor = AppColors.PRIMARY_GOLD
    this.canvasContext.shadowBlur = 5
    this.canvasContext.fillStyle = '#FFE08A'
    this.canvasContext.beginPath()
    this.canvasContext.arc(this.currentTouchX, this.currentTouchY, radius, 0, 2 * Math.PI)
    this.canvasContext.fill()
    this.canvasContext.strokeStyle = '#FFFFFF33'
    this.canvasContext.lineWidth = 1
    this.canvasContext.beginPath()
    this.canvasContext.arc(this.currentTouchX, this.currentTouchY, radius + 2, 0, 2 * Math.PI)
    this.canvasContext.stroke()
    this.canvasContext.restore()
  }

  findLetterAtPosition(x: number, y: number): LetterItem | null {
    const thresholdSq = this.TOUCH_THRESHOLD * this.TOUCH_THRESHOLD
    for (let i = 0; i < this.letters.length; i++) {
      const letter = this.letters[i]
      const dx = x - (letter.x + this.LETTER_CENTER)
      const dy = y - (letter.y + this.LETTER_CENTER)
      if ((dx * dx + dy * dy) < thresholdSq) {
        return letter
      }
    }
    return null
  }

  onTouchStart(x: number, y: number): void {
    this.lineFeedback = 'normal'
    this.feedbackLetterIds = []
    this.isDragging = true
    this.startLineAnimationLoop()
    this.currentTouchX = x
    this.currentTouchY = y
    const letter = this.findLetterAtPosition(x, y)
    if (letter !== null && !letter.isSelected) {
      gameState.selectLetter(letter)
      this.playLetterSnap(letter.id)
      soundManager.play(SoundNames.LETTER_SELECT)
      hapticManager.play(HapticNames.LETTER_SELECT)
      this.refreshState()
    }
    this.drawLines()
  }

  onTouchMove(x: number, y: number): void {
    if (!this.isDragging) {
      return
    }
    this.currentTouchX = x
    this.currentTouchY = y
    const letter = this.findLetterAtPosition(x, y)
    if (letter !== null) {
      if (!letter.isSelected) {
        gameState.selectLetter(letter)
        this.playLetterSnap(letter.id)
        soundManager.play(SoundNames.LETTER_SELECT)
        hapticManager.play(HapticNames.LETTER_SELECT)
        this.refreshState()
      } else {
        const selected = gameState.selectedLetters
        if (selected.length >= 2 && selected[selected.length - 2].id === letter.id) {
          gameState.undoLastLetter()
          this.playLetterSnap(letter.id)
          soundManager.play(SoundNames.LETTER_SELECT)
          hapticManager.play(HapticNames.LETTER_SELECT)
          this.refreshState()
        }
      }
    }
    this.drawLines()
  }

  onTouchEnd(): void {
    this.isDragging = false
    this.stopLineAnimationLoop()
    this.drawLines()
    if (this.currentWord.length >= GameLayout.MIN_WORD_LENGTH) {
      this.submitWord()
    } else {
      gameState.clearSelection()
      this.refreshState()
      this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    }
  }

  private startLineAnimationLoop(): void {
    if (this.lineAnimTimerId > 0) {
      return
    }
    this.lineAnimTimerId = setInterval(() => {
      if (!this.isDragging) {
        this.stopLineAnimationLoop()
        return
      }
      this.drawLines()
    }, 66) as number
  }

  private stopLineAnimationLoop(): void {
    if (this.lineAnimTimerId > 0) {
      clearInterval(this.lineAnimTimerId)
      this.lineAnimTimerId = 0
    }
  }

  private playLetterSnap(id: number): void {
    const key = id.toString()
    this.snapLetterId = key
    this.snapLetterScale = 1.08
    this.getUIContext().animateTo({ duration: 70, curve: Curve.EaseOut }, () => {
      this.snapLetterScale = 1.14
    })
    setTimeout(() => {
      if (this.snapLetterId !== key) {
        return
      }
      this.getUIContext().animateTo({ duration: 90, curve: Curve.EaseIn }, () => {
        this.snapLetterScale = 1.03
      })
    }, 75)
    setTimeout(() => {
      if (this.snapLetterId !== key) {
        return
      }
      this.getUIContext().animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
        this.snapLetterScale = 1
      })
    }, 170)
    setTimeout(() => {
      if (this.snapLetterId === key) {
        this.snapLetterId = ''
      }
    }, 285)
  }

  build() {
    NavDestination() {
      Stack() { // Layer 1: Crossword grid
        Column() {
          Column() {
            ForEach(this.crosswordRows, (row: CrosswordRow) => {
              Row() {
                ForEach(row.cells, (cell: CrosswordCell, ci: number) => {
                  if (cell.isActive) {
                    Stack({ alignContent: Alignment.Center }) {
                      Text(this.crosswordCellText(cell))
                        .width(this.crosswordCellSize)
                        .height(this.crosswordCellSize)
                        .fontSize(this.crosswordFontSize)
                        .fontColor(this.crosswordCellTextColor(cell))
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Center)
                    }
                      .width(this.crosswordCellSize)
                      .height(this.crosswordCellSize)
                      .backgroundColor(this.crosswordCellBg(cell))
                      .border({
                        width: this.crosswordCellBorderWidth(cell),
                        color: this.crosswordCellBorderColor(cell)
                      })
                      .scale({
                        x: this.crosswordCellScale(cell),
                        y: this.crosswordCellScale(cell)
                      })
                      .shadow({
                        radius: this.crosswordCellShadowRadius(cell),
                        color: this.crosswordCellShadowColor(cell),
                        offsetX: 0,
                        offsetY: 0
                      })
                      .animation({ duration: this.crosswordCellAnimDuration(), curve: Curve.EaseOut })
                      .borderRadius(3)
                      .margin(1)
                  } else {
                    Text('')
                      .width(this.crosswordCellSize)
                      .height(this.crosswordCellSize)
                      .margin(1).opacity(0)
                  }
                }, (cell: CrosswordCell) => `${this.activeLevelId}_${this.crosswordCellKey(cell)}`)
              }
            }, (row: CrosswordRow) => `${this.activeLevelId}_${row.id}`)

          }.backgroundColor('#000000DD')
          .borderRadius(16)
          .padding({
            left: 10,
            right: 10,
            top: 8,
            bottom: 8
          })
        }
        .translate({ x: this.wrongShakeX, y: this.crosswordOffsetY })
        .animation({ duration: 60, curve: Curve.Linear })
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)

        ForEach(this.letters, (item: LetterItem, index: number) => { // Layer 2: Letter circle
          Stack() {
            Circle()
              .width(GameLayout.LETTER_SIZE - 5)
              .height(GameLayout.LETTER_SIZE - 5)
              .fill('transparent')
              .stroke(this.letterStrokeColor(item))
              .strokeWidth(item.isSelected || this.isFeedbackLetter(item.id) ? 3 : 2)
              .opacity(item.isSelected || this.isFeedbackLetter(item.id) ? 1 : 0.88)
              .scale({
                x: this.letterScale(item),
                y: this.letterScale(item)
              })
              .shadow({
                radius: item.isSelected || this.isFeedbackLetter(item.id) ? 12 : 1,
                color: this.letterGlowColor(item),
                offsetX: 0,
                offsetY: 0
              })
              .animation({ duration: 150, curve: Curve.EaseOut })

            Text(item.letter)
              .fontSize(20)
              .fontColor(this.letterTextColor(item))
              .fontWeight(FontWeight.Bold)
          }
          .width(GameLayout.LETTER_SIZE)
          .height(GameLayout.LETTER_SIZE)
          .position({ x: this.letterPos[index * 2] ?? 0, y: this.letterPos[index * 2 + 1] ?? 0 })
          .clipShape(new Circle({ width: GameLayout.LETTER_SIZE, height: GameLayout.LETTER_SIZE }))
          .onTouch((event: TouchEvent) => {

            if (event.type === TouchType.Down) {
              this.pressedLetterId = item.id.toString()
            }

            if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.pressedLetterId = ''
            }
          })
          .hitTestBehavior(HitTestMode.None)
        }, (item: LetterItem) => `${this.activeLevelId}_${item.id.toString()}`)

        Canvas(this.canvasContext)
          .width(this.CANVAS_SIZE)
          .height(this.CANVAS_SIZE)
          .hitTestBehavior(HitTestMode.None)
          .onReady(() => {
            this.drawLines()
          }) // Layer 3: All screen
        Text(this.currentWord)
          .width(130)
          .height(26)
          .position({ x: 51.5, y: 103.5 })
          .fontSize(18)
          .fontColor(this.showError ? '#FF5252' : AppColors.PRIMARY_GOLD)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)
        BackButton({ btnSize: 28, bgColor: '#00000066' }).position({ x: 66, y: 18 }) // Layer 4: Back button
        Stack() { // Layer 5: Hint button
          HintButton({
            isEnabled: this.hintCount > 0, count: this.hintCount, onTap: () => {
              this.handleHintTap()
            }
          })
        }.position({ x: this.hintPosX, y: this.hintPosY })

        if (this.bonusWordsTotal > 0) { // Layer 6: Bonus indicator
          Stack() {
            Canvas(this.bonusCanvasCtx).width(30).height(30).onReady(() => {
              this.drawBonusIndicator()
            })
            Text((this.bonusWordsTotal - this.bonusWordsFound).toString())
              .fontSize(12)
              .fontColor(AppColors.WHITE)
              .fontWeight(FontWeight.Bold)
          }.width(30).height(30).position({ x: this.bonusPosX, y: this.bonusPosY }).hitTestBehavior(HitTestMode.None)
        }
        Stack() { // Layer 7: Shuffle button
          Circle()
            .width(GameLayout.SHUFFLE_SIZE)
            .height(GameLayout.SHUFFLE_SIZE)
            .fill('transparent')
            .stroke(AppColors.PRIMARY_GOLD)
            .strokeWidth(2)
            .opacity(0.8)
          Text('🔀').fontSize(18).fontColor(AppColors.PRIMARY_GOLD).fontWeight(FontWeight.Bold)
        }
        .width(GameLayout.SHUFFLE_SIZE)
        .height(GameLayout.SHUFFLE_SIZE)
        .borderRadius(GameLayout.SHUFFLE_SIZE / 2)
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.PRIMARY_GOLD)
          }, normal: {
            .backgroundColor('#00000000')
          }
        })
        .position({ x: this.shufflePosX, y: this.shufflePosY })
        .onClick(() => {
          this.shuffleLetters()
        })

        if (this.showSuccess) { // Layer 8: Success overlay
          Column() {
            Text('\u2714').fontSize(48).fontColor(AppColors.SUCCESS_GREEN)
          }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor('#00000080')
        }
        if (this.showBonusPopup) { // Layer 9: Bonus popup
          Column() {
            Column() {
              Text('⭐ Bonus ⭐')
                .fontSize(22)
                .fontColor(AppColors.WHITE)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })
              Text(this.bonusWordFound).fontSize(22).fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
            }
            .padding({
              left: 24,
              right: 24,
              top: 14,
              bottom: 14
            })
            .backgroundColor(AppColors.BONUS_POPUP_BG)
            .borderRadius(16)
            .border({ width: 2, color: AppColors.PRIMARY_GOLD })
            .opacity(0.85)
            .scale({ x: this.bonusPopupScale, y: this.bonusPopupScale })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#00000080')
          .opacity(this.bonusPopupOpacity)
        }
        if (this.showTutorial) {
          Stack() {
            Rect().width('100%').height('100%').fill('#00000055')
            Column() {
              Text('How to Play')
                .fontSize(14)
                .fontColor(AppColors.WHITE)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })
              Text('Drag letters to form a word.\nBlanks fill when the word is correct.\n\uD83D\uDCA1 = Hint')
                .fontSize(11)
                .fontColor(AppColors.GRAY_LIGHT)
                .textAlign(TextAlign.Center)
                .margin({ bottom: 12 })
              Row() {
                Stack() {
                  Rect().width(120).height(40).fill(AppColors.GRAY_DARK).radius(15)
                  Text('Skip').fontSize(14).fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
                }.onClick(() => {
                  gameState.closeTutorial(true)
                  this.refreshState()
                })
              }
              .backgroundColor(Color.Transparent)
            }
            .padding(12)
            .backgroundColor('#1A1A1A')
            .borderRadius(12)
            .width(170)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height('100%')
        }
      }.width('100%').height('100%').backgroundColor(this.bgColor)
      .gesture(PanGesture({ fingers: 1, distance: 1 }).onActionStart((event: GestureEvent) => {
        if (event.fingerList.length > 0) {
          const finger = event.fingerList[0]
          if (this.isHintPoint(finger.localX, finger.localY)) {
            this.ignoreCurrentPan = true
            this.handleHintTap()
            return
          }
          this.ignoreCurrentPan = false
          this.updatePressedByPos(finger.localX, finger.localY)
          this.onTouchStart(finger.localX, finger.localY)
        }
      }).onActionUpdate((event: GestureEvent) => {
        if (this.ignoreCurrentPan) {
          return
        }
        if (event.fingerList.length > 0) {
          const finger = event.fingerList[0]
          this.updatePressedByPos(finger.localX, finger.localY)
          this.onTouchMove(finger.localX, finger.localY)
        }
      }).onActionEnd(() => {
        if (this.ignoreCurrentPan) {
          this.ignoreCurrentPan = false
          return
        }
        this.pressedLetterId = ''
        this.onTouchEnd()
      }))
      .parallelGesture(TapGesture({ count: 1, fingers: 1 }).onAction((event: GestureEvent) => {
        if (event.fingerList.length > 0) {
          const finger = event.fingerList[0]
          if (this.isHintPoint(finger.localX, finger.localY)) {
            this.handleHintTap()
          }
        }
      }))
    }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND_DARK).onBackPressed(() => true).onShown(() => {
      this.refreshState()
    })
  }

  submitWord(): void {
    const submittedPoints = this.linePoints.slice()
    const submittedLetterIds = gameState.selectedLetters.map((letter: LetterItem) => letter.id)
    if (this.currentWord.length < GameLayout.MIN_WORD_LENGTH) {
      this.clearFeedback()
      gameState.clearSelection()
      this.refreshState()
      this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
      return
    }
    const prevFound = this.wordSlots.map(s => s.isFound)
    const prevBonusCount = gameState.bonusWordsFound.length
    const success = gameState.submitWord()
    this.refreshState()
    this.feedbackLetterIds = submittedLetterIds
    this.linePoints = submittedPoints
    const isBonusWord = success && gameState.bonusWordsFound.length > prevBonusCount
    if (success) {
      soundManager.play(gameState.isLevelComplete ? SoundNames.LEVEL_COMPLETE : SoundNames.CORRECT_WORD)
      hapticManager.play(gameState.isLevelComplete ? HapticNames.LEVEL_COMPLETE : HapticNames.CORRECT_WORD)
      this.lineFeedback = 'success'
      if (this.showTutorial) {
        gameState.closeTutorial(true)
        this.showTutorial = false
      }
    } else {
      soundManager.play(SoundNames.WRONG_WORD)
      hapticManager.play(HapticNames.WRONG_WORD)
      this.lineFeedback = 'wrong'
    }
    this.drawLines()
    if (success) {
      const newIndex = this.wordSlots.findIndex((s, i) => s.isFound && !prevFound[i])
      if (newIndex !== -1) {
        StatsStore.addWordsFound(1)
        this.successFlashSlotIndex = newIndex
        this.successFlashOn = true
        setTimeout(() => {
          this.successFlashOn = false
          this.successFlashSlotIndex = -1
        }, 360)
      }
      setTimeout(() => {
        this.clearFeedback()
      }, 520)
      if (gameState.isLevelComplete) {
        const durationMs = Date.now() - this.pageEnterMs
        StatsStore.setLastCompletedLevelMs(durationMs)
        StatsStore.trySetFastest(gameState.currentLevelId, durationMs)
      }
    }
    if (success && isBonusWord) {
      this.showBonusPopupAnimation()
    } else if (success) {
      this.showSuccessOverlay()
    } else {
      this.showErrorAnimation()
    }
  }

  private buildCrosswordGrid(): CrosswordRow[] {
    const level = gameState.currentLevel
    if (!level || this.wordSlots.length === 0) {
      return []
    }
    const gridRows = level.grid.length
    const gridCols = gridRows > 0 ? level.grid[0].length : 0
    const maxDim = Math.max(gridRows, gridCols)
    this.crosswordCellSize = maxDim > 0 ? Math.max(12, Math.floor(110 / maxDim)) : 20
    this.crosswordFontSize = Math.max(7, Math.floor(this.crosswordCellSize * 0.65))
    const full: CrosswordCell[][] = [] // Build grid from level.grid (compact, already bounding-box trimmed)
    for (let r = 0; r < gridRows; r++) {
      const row: CrosswordCell[] = []
      for (let c = 0; c < gridCols; c++) {
        const cell = new CrosswordCell()
        cell.row = r
        cell.col = c
        if ((level.grid[r]?.[c] ?? '') !== '') {
          cell.isActive = true
          cell.letter = level.grid[r][c]
        }
        row.push(cell)
      }
      full.push(row)
    }
    for (let s = 0; s < this.wordSlots.length;
      s++) { // Assign slot metadata (found slots take priority at intersections)
      const slot = this.wordSlots[s]
      for (let li = 0; li < slot.word.length; li++) {
        const r = slot.dir === 'H' ? slot.row : slot.row + li
        const c = slot.dir === 'H' ? slot.col + li : slot.col
        if (r >= 0 && r < gridRows && c >= 0 && c < gridCols) {
          const cell = full[r][c]
          const wasFound = cell.isFound
          if (slot.isFound) {
            cell.isFound = true
          }
          if (slot.revealedIndexes.indexOf(li) !== -1) {
            cell.isRevealed = true
          }
          if (cell.slotIndex === -1 || (slot.isFound && !wasFound)) {
            cell.slotIndex = s
            cell.letterIndex = li
            cell.revealedIndexes = slot.revealedIndexes.slice()
          }
        }
      }
    }
    const rows: CrosswordRow[] = []
    for (let r = 0; r < gridRows; r++) {
      const crossRow = new CrosswordRow()
      crossRow.id = `row_${r}`
      for (let c = 0; c < gridCols; c++) {
        crossRow.cells.push(full[r][c])
      }
      rows.push(crossRow)
    }
    return rows
  }

  private showBonusPopupAnimation(): void {
    this.bonusWordFound = gameState.bonusWordsFound[gameState.bonusWordsFound.length - 1]
    this.showBonusPopup = true
    this.bonusPopupScale = 0
    this.bonusPopupOpacity = 0
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.bonusPopupScale = 1.15
      this.bonusPopupOpacity = 1
    })
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 150, curve: Curve.EaseIn }, () => {
        this.bonusPopupScale = 1.0
      })
    }, 250)
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 280, curve: Curve.EaseIn }, () => {
        this.bonusPopupScale = 0.8
        this.bonusPopupOpacity = 0
      })
      setTimeout(() => {
        this.showBonusPopup = false
      }, 280)
    }, 1500)

    setTimeout(() => {
      if (gameState.isLevelComplete) {
        this.navPathStack.pushPathByName(PageNames.WIN, null)
      }
    }, 1800)
  }

  private shuffleLetters(): void {
    gameState.shuffleLetters()
    soundManager.play(SoundNames.SHUFFLE)
    hapticManager.play(HapticNames.SHUFFLE)
    this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE,
      this.CANVAS_SIZE) // Sync this.letters for correct touch detection (p0x/y still hold old positions)
    const newLetters: LetterItem[] = []
    for (let i = 0; i < gameState.letters.length; i++) {
      newLetters.push(gameState.letters[i].clone())
    }
    this.letters = newLetters // Animate from old positions (p0x/y) to new positions
    this.getUIContext().animateTo({ duration: 420, curve: Curve.EaseInOut }, () => {
      const newPos: number[] = []
      for (let i = 0; i < gameState.letters.length; i++) {
        newPos.push(gameState.letters[i].x)
        newPos.push(gameState.letters[i].y)
      }
      this.letterPos = newPos
    })
  }

  @Builder
  private TutorialLetter(letter: string) {
    Text(letter)
      .fontSize(11)
      .fontColor(AppColors.WHITE)
      .fontWeight(FontWeight.Bold)
      .width(24)
      .height(24)
      .textAlign(TextAlign.Center)
      .backgroundColor('#243B74')
      .borderRadius(12)
      .border({ width: 1, color: AppColors.PRIMARY_GOLD })
  }

  private showSuccessOverlay(): void {
    this.showSuccess = true
    setTimeout(() => {
      this.showSuccess = false
      if (gameState.isLevelComplete) {
        this.navPathStack.pushPathByName(PageNames.WIN, null)
      }
    }, GameLayout.SUCCESS_DELAY)
  }

  private showErrorAnimation(): void {
    this.showError = true
    this.wrongFlash = true
    const d = 45
    this.wrongShakeX = 7
    setTimeout(() => this.wrongShakeX = -7, d)
    setTimeout(() => this.wrongShakeX = 5, d * 2)
    setTimeout(() => this.wrongShakeX = -3, d * 3)
    setTimeout(() => this.wrongShakeX = 0, d * 4)
    setTimeout(() => {
      this.wrongFlash = false
      this.showError = false
    }, 260)
    setTimeout(() => {
      gameState.hideError()
      this.clearFeedback()
      this.refreshState()
      this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    }, GameLayout.ERROR_DELAY)
  }

  private updatePressedByPos(x: number, y: number) {
    const r = GameLayout.LETTER_SIZE / 2
    const hit = r * 1.18
    const letters = this.letters
    const pos = this.letterPos

    for (let i = 0; i < letters.length; i++) {
      const cx = (pos[i * 2] ?? 0) + r
      const cy = (pos[i * 2 + 1] ?? 0) + r
      const dx = x - cx
      const dy = y - cy
      if ((dx * dx + dy * dy) <= (hit * hit)) {
        this.pressedLetterId = letters[i].id.toString()
        return
      }
    }
    this.pressedLetterId = ''
  }

  private handleHintTap(): void {
    const now = Date.now()
    if (this.hintCount <= 0 || now - this.lastHintTapMs < 250) {
      return
    }
    this.lastHintTapMs = now
    const revealedBefore = this.snapshotRevealedIndexes()
    this.clearFeedback()
    gameState.clearSelection()
    const didUseHint = gameState.useHint()
    this.refreshState()
    if (didUseHint) {
      hapticManager.play(HapticNames.HINT)
      this.flashHintCells(this.findNewHintCellKeys(revealedBefore))
    }
  }

  private isHintPoint(x: number, y: number): boolean {
    const padding = 8
    return x >= this.hintPosX - padding &&
      x <= this.hintPosX + GameLayout.HINT_SIZE + padding &&
      y >= this.hintPosY - padding &&
      y <= this.hintPosY + GameLayout.HINT_SIZE + padding
  }

  private clearFeedback(): void {
    this.lineFeedback = 'normal'
    this.feedbackLetterIds = []
    this.linePoints = []
    this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
  }

  private snapshotRevealedIndexes(): string[] {
    const snapshot: string[] = []
    for (let slotIndex = 0; slotIndex < this.wordSlots.length; slotIndex++) {
      const slot = this.wordSlots[slotIndex]
      for (let i = 0; i < slot.revealedIndexes.length; i++) {
        snapshot.push(`${slotIndex}:${slot.revealedIndexes[i]}`)
      }
    }
    return snapshot
  }

  private findNewHintCellKeys(revealedBefore: string[]): string[] {
    const keys: string[] = []
    for (let slotIndex = 0; slotIndex < gameState.wordSlots.length; slotIndex++) {
      const slot = gameState.wordSlots[slotIndex]
      for (let i = 0; i < slot.revealedIndexes.length; i++) {
        const letterIndex = slot.revealedIndexes[i]
        if (revealedBefore.indexOf(`${slotIndex}:${letterIndex}`) !== -1) {
          continue
        }
        const row = slot.dir === 'H' ? slot.row : slot.row + letterIndex
        const col = slot.dir === 'H' ? slot.col + letterIndex : slot.col
        keys.push(`${row}:${col}`)
      }
    }
    return keys
  }

  private syncRevealedCellKeys(): void {
    if (this.revealedLevelId !== gameState.currentLevelId) {
      this.revealedLevelId = gameState.currentLevelId
      this.revealedCellKeys = []
    }

    const keys = this.revealedCellKeys.slice()
    for (let slotIndex = 0; slotIndex < this.wordSlots.length; slotIndex++) {
      const slot = this.wordSlots[slotIndex]
      for (let i = 0; i < slot.revealedIndexes.length; i++) {
        const letterIndex = slot.revealedIndexes[i]
        const row = slot.dir === 'H' ? slot.row : slot.row + letterIndex
        const col = slot.dir === 'H' ? slot.col + letterIndex : slot.col
        this.addUniqueKey(keys, `${row}:${col}`)
      }
    }
    this.revealedCellKeys = keys
  }

  private addUniqueKey(keys: string[], key: string): void {
    if (keys.indexOf(key) === -1) {
      keys.push(key)
    }
  }

  private flashHintCells(keys: string[]): void {
    if (keys.length === 0) {
      return
    }
    const revealedKeys = this.revealedCellKeys.slice()
    for (let i = 0; i < keys.length; i++) {
      this.addUniqueKey(revealedKeys, keys[i])
    }
    this.revealedCellKeys = revealedKeys

    this.hintFlashSeq += 1
    const seq = this.hintFlashSeq
    this.hintFlashKeys = keys
    this.hintFlashOn = true
    this.hintFlashPhase = 1
    setTimeout(() => {
      if (seq !== this.hintFlashSeq) {
        return
      }
      this.hintFlashPhase = 2
    }, 140)
    setTimeout(() => {
      if (seq !== this.hintFlashSeq) {
        return
      }
      this.hintFlashPhase = 3
    }, 560)
    setTimeout(() => {
      if (seq !== this.hintFlashSeq) {
        return
      }
      this.hintFlashOn = false
      this.hintFlashPhase = 0
      this.refreshState()
    }, 820)
    setTimeout(() => {
      if (seq !== this.hintFlashSeq) {
        return
      }
      this.hintFlashKeys = []
    }, 900)
  }

  private isHintFlashCell(cell: CrosswordCell): boolean {
    return this.hintFlashOn && this.hintFlashKeys.indexOf(`${cell.row}:${cell.col}`) !== -1
  }

  private isRevealedCell(cell: CrosswordCell): boolean {
    return cell.isLetterRevealed() || this.revealedCellKeys.indexOf(`${cell.row}:${cell.col}`) !== -1
  }

  private crosswordCellKey(cell: CrosswordCell): string {
    // Only persistent state drives remounts. Flash animation uses .animation() in-place
    // so the cell is never unmounted during the hint sequence, keeping revealed letters visible.
    return `cell_${cell.row}_${cell.col}_${cell.slotIndex}_${cell.letter}_${cell.isFound ? 1 : 0}_${cell.isRevealed ? 1 : 0}_${cell.revealedIndexes.join(',')}`
  }

  private crosswordCellText(cell: CrosswordCell): string {
    if (cell.isFound || this.isCellInFoundSlot(cell) || this.isRevealedCell(cell) || this.isHintFlashCell(cell)) {
      return cell.letter
    }
    return ''
  }

  private crosswordCellTextColor(cell: CrosswordCell): ResourceColor {
    return this.isHintFlashCell(cell) ? AppColors.BACKGROUND_DARK : AppColors.WHITE
  }

  private isCellInFoundSlot(cell: CrosswordCell): boolean {
    for (let s = 0; s < this.wordSlots.length; s++) {
      const slot = this.wordSlots[s]
      if (!slot.isFound) {
        continue
      }
      for (let li = 0; li < slot.word.length; li++) {
        const r = slot.dir === 'H' ? slot.row : slot.row + li
        const c = slot.dir === 'H' ? slot.col + li : slot.col
        if (cell.row === r && cell.col === c) {
          return true
        }
      }
    }
    return false
  }

  private crosswordCellBg(cell: CrosswordCell): string {
    if (this.isHintFlashCell(cell)) {
      return this.hintFlashPhase === 3 ? AppColors.WORD_SLOT_FILLED : AppColors.PRIMARY_GOLD
    }
    if (this.wrongFlash) {
      return '#600020'
    }
    if (this.successFlashOn && this.successFlashSlotIndex === cell.slotIndex) {
      return '#1DB954'
    }
    if (cell.isFound || this.isCellInFoundSlot(cell)) {
      return AppColors.SUCCESS_GREEN
    }
    if (this.isRevealedCell(cell)) {
      return AppColors.WORD_SLOT_FILLED
    }
    return AppColors.WORD_SLOT_EMPTY
  }

  private crosswordCellBorderWidth(cell: CrosswordCell): number {
    if (this.isHintFlashCell(cell)) {
      return this.hintFlashPhase === 1 ? 3 : 2
    }
    return this.isRevealedCell(cell) && !cell.isFound ? 1 : 0
  }

  private crosswordCellBorderColor(cell: CrosswordCell): ResourceColor {
    if (this.isHintFlashCell(cell)) {
      return AppColors.STAR_GOLD
    }
    if (this.isRevealedCell(cell) && !cell.isFound) {
      return '#FFFFFF33'
    }
    return Color.Transparent
  }

  private crosswordCellScale(cell: CrosswordCell): number {
    if (this.isHintFlashCell(cell)) {
      if (this.hintFlashPhase === 1) {
        return 1.04
      }
      if (this.hintFlashPhase === 2) {
        return 1.12
      }
      return 1.03
    }
    if (this.successFlashOn && this.successFlashSlotIndex === cell.slotIndex) {
      return 1.08
    }
    return 1
  }

  private crosswordCellShadowRadius(cell: CrosswordCell): number {
    if (this.isHintFlashCell(cell)) {
      return this.hintFlashPhase === 1 ? 18 : 11
    }
    if (this.successFlashOn && this.successFlashSlotIndex === cell.slotIndex) {
      return 8
    }
    return 0
  }

  private crosswordCellShadowColor(cell: CrosswordCell): ResourceColor {
    if (this.isHintFlashCell(cell)) {
      return AppColors.STAR_GOLD
    }
    if (this.successFlashOn && this.successFlashSlotIndex === cell.slotIndex) {
      return AppColors.SUCCESS_GREEN
    }
    return Color.Transparent
  }

  private crosswordCellAnimDuration(): number {
    return (this.successFlashOn || this.wrongFlash || this.hintFlashOn) ? 220 : 0
  }

  private isFeedbackLetter(id: number): boolean {
    return this.feedbackLetterIds.indexOf(id) !== -1
  }

  private letterStrokeColor(item: LetterItem): string {
    if (this.isFeedbackLetter(item.id)) {
      return this.lineFeedback === 'wrong' ? '#FF5252' : AppColors.LINE_GREEN
    }
    return item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE
  }

  private letterTextColor(item: LetterItem): string {
    if (this.isFeedbackLetter(item.id)) {
      return this.lineFeedback === 'wrong' ? '#FFB3B3' : '#D8FFB8'
    }
    return item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE
  }

  private letterGlowColor(item: LetterItem): string {
    if (this.isFeedbackLetter(item.id)) {
      return this.lineFeedback === 'wrong' ? '#FF5252' : AppColors.LINE_GREEN
    }
    return item.isSelected || this.pressedLetterId === item.id.toString() ? '#FFD36A' : '#000000'
  }

  private letterScale(item: LetterItem): number {
    if (this.isFeedbackLetter(item.id)) {
      return this.lineFeedback === 'wrong' ? 1.12 : 1.16
    }
    if (this.snapLetterId === item.id.toString()) {
      return this.snapLetterScale
    }
    return this.pressedLetterId === item.id.toString() || item.isSelected ? 1.08 : 1.0
  }
}
