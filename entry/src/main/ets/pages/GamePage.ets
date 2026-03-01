import { AppColors, AppSizes, difficultyBgColor, GameLayout, PageNames } from '../common/Constants'
import { GameState, gameState, LetterItem, WordSlot } from '../viewmodel/GameViewModel'
import { HintButton } from '../components/HintButton'
import { BackButton } from '../components/BackButton'
import { soundManager, SoundNames } from '../common/SoundManager'
import { StatsStore } from '../components/StatsStore'

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
  slotIndex: number = -1
  letterIndex: number = -1
  letter: string = ''
  isFound: boolean = false
  revealedIndexes: number[] = []

  isLetterRevealed(): boolean {
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
}

@Component
export struct GamePage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @State levelId: number = 1
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
  pressedLetterId: string = ''
  @State wrongFlash: boolean = false
  @State wrongShakeX: number = 0
  @State successFlashSlotIndex: number = -1
  @State successFlashOn: boolean = false
  @State showBonusPopup: boolean = false
  @State bonusWordFound: string = ''
  @State bonusPopupScale: number = 0
  @State bonusPopupOpacity: number = 0
  @State bgColor: string = AppColors.BACKGROUND_DARK
  @State crosswordRows: CrosswordRow[] = []
  @State crosswordCellSize: number = 20
  @State crosswordFontSize: number = 13
  @State foundWordCount: number = 0
  private pageEnterMs: number = 0
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private bonusCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private bonusCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.bonusCanvasSettings)
  private readonly LETTER_CENTER: number = GameLayout.LETTER_SIZE / 2
  private readonly CANVAS_SIZE: number = AppSizes.SCREEN_SIZE
  private readonly TOUCH_THRESHOLD: number = GameLayout.TOUCH_THRESHOLD

  get isTutorialDone(): boolean {
    return AppStorage.get<boolean>(GameState.TUTORIAL_DONE) ?? false
  }

  set isTutorialDone(v: boolean) {
    AppStorage.set<boolean>(GameState.TUTORIAL_DONE, v)
  }

  aboutToAppear(): void {
    gameState.ensureTutorialOnFirstLaunch()
    this.pageEnterMs = Date.now()
    this.refreshState()
  }

  aboutToDisappear(): void {
    const delta = Date.now() - this.pageEnterMs
    StatsStore.addPlayTimeMs(delta)
  }

  refreshState(): void {
    this.levelId = gameState.currentLevelId
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
    this.updateLinePoints()
    this.hintCount = gameState.hintCount
    this.bonusWordsFound = gameState.bonusWordsFound.length
    this.bonusWordsTotal =
      gameState.currentLevel && gameState.currentLevel.bonusWords ? gameState.currentLevel.bonusWords.length : 0
    this.hintPosX = gameState.hintPos[0]
    this.hintPosY = gameState.hintPos[1]
    this.bonusPosX = gameState.bonusPos[0]
    this.bonusPosY = gameState.bonusPos[1]
    this.shufflePosX = gameState.shufflePos[0]
    this.shufflePosY = gameState.shufflePos[1]
    this.drawBonusIndicator()
    this.syncLetterPos()
    let fc = 0
    for (let i = 0; i < this.wordSlots.length; i++) {
      if (this.wordSlots[i].isFound) {
        fc++
      }
    }
    this.foundWordCount = fc
    this.crosswordRows = this.buildCrosswordGrid()
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
    if (this.linePoints.length > 1) {
      const first = this.linePoints[0]
      const last = this.linePoints[this.linePoints.length - 1]
      const gradient = this.canvasContext.createLinearGradient(first.x, first.y, last.x, last.y)
      gradient.addColorStop(0, '#FFD36A')
      gradient.addColorStop(1, '#FF7A00')
      this.canvasContext.strokeStyle = gradient
    } else {
      this.canvasContext.strokeStyle = '#FFD36A'
    }
    const minW = 2
    const maxW = 5
    const totalSegments = Math.max(1, this.linePoints.length - 1)
    this.canvasContext.shadowColor = '#FFD36A'
    this.canvasContext.shadowBlur = 10

    for (let i = 1; i < this.linePoints.length; i++) {
      const p0 = this.linePoints[i - 1]
      const p1 = this.linePoints[i]
      const t = (i - 1) / totalSegments
      const w = minW + (maxW - minW) * Math.sin(Math.PI * t)
      this.canvasContext.lineWidth = w
      this.canvasContext.beginPath()
      this.canvasContext.moveTo(p0.x, p0.y)
      this.canvasContext.lineTo(p1.x, p1.y)
      this.canvasContext.stroke()
    }
    if (this.isDragging && this.linePoints.length > 0) {
      const last = this.linePoints[this.linePoints.length - 1]
      this.canvasContext.lineWidth = minW
      this.canvasContext.beginPath()
      this.canvasContext.moveTo(last.x, last.y)
      this.canvasContext.lineTo(this.currentTouchX, this.currentTouchY)
      this.canvasContext.stroke()
    }
    this.canvasContext.shadowBlur = 0
    this.canvasContext.shadowColor = 'transparent'
  }

  findLetterAtPosition(x: number, y: number): LetterItem | null {
    for (let i = 0; i < this.letters.length; i++) {
      const letter = this.letters[i]
      const centerX = letter.x + this.LETTER_CENTER
      const centerY = letter.y + this.LETTER_CENTER
      const dx = x - centerX
      const dy = y - centerY
      const distance = Math.sqrt(dx * dx + dy * dy)
      if (distance < this.TOUCH_THRESHOLD) {
        return letter
      }
    }
    return null
  }

  onTouchStart(x: number, y: number): void {
    this.isDragging = true
    this.currentTouchX = x
    this.currentTouchY = y
    const letter = this.findLetterAtPosition(x, y)
    if (letter !== null && !letter.isSelected) {
      gameState.selectLetter(letter)
      soundManager.play(SoundNames.LETTER_SELECT)
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
        soundManager.play(SoundNames.LETTER_SELECT)
        this.refreshState()
      } else {
        const selected = gameState.selectedLetters
        if (selected.length >= 2 && selected[selected.length - 2].id === letter.id) {
          gameState.undoLastLetter()
          this.refreshState()
        }
      }
    }
    this.drawLines()
  }

  onTouchEnd(): void {
    this.isDragging = false
    this.drawLines()
    if (this.currentWord.length >= GameLayout.MIN_WORD_LENGTH) {
      this.submitWord()
    } else {
      gameState.clearSelection()
      this.refreshState()
      this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    }
  }

  build() {
    NavDestination() {
      Stack() { // Layer 1: Crossword grid
        Column() {
          Column() {
            ForEach(this.crosswordRows, (row: CrosswordRow, ri: number) => {
              Row() {
                ForEach(row.cells, (cell: CrosswordCell, ci: number) => {
                  if (cell.isActive) {
                    Text(cell.isFound ? cell.letter : (cell.isLetterRevealed() ? cell.letter : ''))
                      .width(this.crosswordCellSize)
                      .height(this.crosswordCellSize)
                      .fontSize(this.crosswordFontSize)
                      .fontColor(AppColors.WHITE)
                      .fontWeight(FontWeight.Bold)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(this.wrongFlash ? '#600020' :
                        (this.successFlashOn && this.successFlashSlotIndex === cell.slotIndex ? '#1DB954' :
                          (cell.isFound ? AppColors.SUCCESS_GREEN : AppColors.WORD_SLOT_EMPTY)))
                      .animation({ duration: (this.successFlashOn || this.wrongFlash) ? 160 : 0, curve: Curve.EaseOut })
                      .borderRadius(3)
                      .margin(1)
                  } else {
                    Text('')
                      .width(this.crosswordCellSize)
                      .height(this.crosswordCellSize)
                      .margin(1).opacity(0)
                  }
                }, (cell: CrosswordCell) => `cell_${cell.slotIndex}_${cell.isFound ? 1 :
                  0}_${cell.revealedIndexes.join(',')}`)
              }
            }, (row: CrosswordRow, ri: number) => {
              const str = `r${ri.toString()}`
              return `${str}_${this.foundWordCount.toString()}_${this.hintCount.toString()}`
            })

            Text(this.currentWord)
              .fontSize(18)
              .fontColor(this.showError ? '#FF5252' : AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)
              .height(26)
              .margin({ top: 6 })
          }.backgroundColor('#000000DD')
          .borderRadius(16)
          .padding({
            left: 10,
            right: 10,
            top: 8,
            bottom: 8
          })
        }
        .translate({ x: this.wrongShakeX, y: 0 })
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
              .stroke(item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE)
              .strokeWidth(2)
              .scale({
                x: this.pressedLetterId === item.id.toString() ? 1.15 : 1.0,
                y: this.pressedLetterId === item.id.toString() ? 1.15 : 1.0
              })
              .shadow({
                radius: this.pressedLetterId === item.id.toString() ? 1.15 : 1.0,
                color: this.pressedLetterId === item.id.toString() ? '#FFD36A' : '#000000',
                offsetX: 0,
                offsetY: 0
              })
              .animation({ duration: 120, curve: Curve.EaseOut })

            Text(item.letter)
              .fontSize(20)
              .fontColor(item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE)
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
        }, (item: string, index: number) => item)

        Canvas(this.canvasContext)
          .width(this.CANVAS_SIZE)
          .height(this.CANVAS_SIZE)
          .hitTestBehavior(HitTestMode.None)
          .onReady(() => {
            this.drawLines()
          }) // Layer 3: All screen
        BackButton({ btnSize: 28, bgColor: '#00000066' }).position({ x: 66, y: 18 }) // Layer 4: Back button
        Stack() { // Layer 5: Hint button
          HintButton({
            isEnabled: gameState.hintCount > 0, count: this.hintCount, onTap: () => {
              gameState.useHint()
              this.refreshState()
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
          gameState.shuffleLetters()
          soundManager.play(SoundNames.SHUFFLE)
          this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE,
            this.CANVAS_SIZE) // Sync this.letters for correct touch detection (p0x/y still hold old positions)
          const newLetters: LetterItem[] = []
          for (let i = 0; i < gameState.letters.length; i++) {
            newLetters.push(gameState.letters[i].clone())
          }
          this.letters = newLetters // Animate from old positions (p0x/y) to new positions
          this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseInOut }, () => {
            const newPos: number[] = []
            for (let i = 0; i < gameState.letters.length; i++) {
              newPos.push(gameState.letters[i].x)
              newPos.push(gameState.letters[i].y)
            }
            this.letterPos = newPos
          })
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
            Rect().width('100%').height('100%').fill('#00000000')
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
                  console.info('[TUTORIAL] skip clicked')
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
          }.width('100%').height('100%')
        }
      }.width('100%').height('100%').backgroundColor(this.bgColor)
      .gesture(PanGesture({ fingers: 1, distance: 1 }).onActionStart((event: GestureEvent) => {
        if (event.fingerList.length > 0) {
          const finger = event.fingerList[0]
          this.updatePressedByPos(finger.localX, finger.localY)
          this.onTouchStart(finger.localX, finger.localY)
        }
      }).onActionUpdate((event: GestureEvent) => {
        if (event.fingerList.length > 0) {
          const finger = event.fingerList[0]
          this.updatePressedByPos(finger.localX, finger.localY)
          this.onTouchMove(finger.localX, finger.localY)
        }
      }).onActionEnd(() => {
        this.pressedLetterId = ''
        this.onTouchEnd()
      }))
    }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND_DARK).onShown(() => {
      this.refreshState()
    })
  }

  submitWord(): void { // Clear canvas
    this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    this.linePoints = []
    if (this.currentWord.length < GameLayout.MIN_WORD_LENGTH) {
      gameState.clearSelection()
      this.refreshState()
      return
    }
    const prevFound = this.wordSlots.map(s => s.isFound)
    const prevBonusCount = gameState.bonusWordsFound.length
    const success = gameState.submitWord()
    this.refreshState()
    const isBonusWord = success && gameState.bonusWordsFound.length > prevBonusCount
    if (success) {
      soundManager.play(gameState.isLevelComplete ? SoundNames.LEVEL_COMPLETE : SoundNames.CORRECT_WORD)
    } else {
      soundManager.play(SoundNames.WRONG_WORD)
    }
    if (success) {
      const newIndex = this.wordSlots.findIndex((s, i) => s.isFound && !prevFound[i])
      if (newIndex !== -1) {
        StatsStore.addWordsFound(1)
        this.successFlashSlotIndex = newIndex
        this.successFlashOn = true
        setTimeout(() => {
          this.successFlashOn = false
          this.successFlashSlotIndex = -1
        }, 250)
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
          if (cell.slotIndex === -1 || (slot.isFound && !cell.isFound)) {
            cell.slotIndex = s
            cell.letterIndex = li
            cell.isFound = slot.isFound
            cell.revealedIndexes = slot.revealedIndexes.slice()
          }
        }
      }
    }
    const rows: CrosswordRow[] = []
    for (let r = 0; r < gridRows; r++) {
      const crossRow = new CrosswordRow()
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
    }, GameLayout.SUCCESS_DELAY)
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
    const d = 60
    this.wrongShakeX = 8
    setTimeout(() => this.wrongShakeX = -6, d)
    setTimeout(() => this.wrongShakeX = 6, d * 2)
    setTimeout(() => this.wrongShakeX = -4, d * 3)
    setTimeout(() => this.wrongShakeX = 4, d * 4)
    setTimeout(() => this.wrongShakeX = 0, d * 5)
    setTimeout(() => {
      this.wrongFlash = false
      this.showError = false
    }, 350)
    setTimeout(() => {
      gameState.hideError()
      this.refreshState()
      this.canvasContext.clearRect(0, 0, this.CANVAS_SIZE, this.CANVAS_SIZE)
    }, GameLayout.ERROR_DELAY)
  }

  private updatePressedByPos(x: number, y: number) {
    const r = GameLayout.LETTER_SIZE / 2
    const hit = r * 0.9
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
}