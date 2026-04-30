import { AppColors, AppSizes, GameLayout } from '../common/Constants'
import { HintButton } from '../components/HintButton'
import { BackButton } from '../components/BackButton'
import { CURRENT_LEVEL_KEY, DEFAULT_LEVEL_LAYOUT } from '../model/LevelData'
import { LetterItem, WordSlot, gameState } from '../viewmodel/GameViewModel'
import { CrosswordCell, CrosswordRow, LinePoint } from '../model/GamePageModels'
import { drawGamePageBonusIndicator, drawGamePageLines } from '../utils/GamePageDrawing'
import {
  crosswordCellAnimDuration,
  crosswordCellBg,
  crosswordCellBorderColor,
  crosswordCellBorderWidth,
  crosswordCellKey,
  crosswordCellScale,
  crosswordCellShadowColor,
  crosswordCellShadowRadius,
  crosswordCellText,
  crosswordCellTextColor,
  letterGlowColor,
  letterScale,
  letterStrokeColor,
  letterTextColor
} from '../utils/GamePageCrosswordStyles'
import { handleGamePageHintTap, isGamePageHintPoint } from '../utils/GamePageHintActions'
import * as gamePageStateActions from '../utils/GamePageStateActions'
import { shuffleGamePageLetters, submitGamePageWord } from '../utils/GamePageWordActions'

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
  linePoints: LinePoint[] = []
  currentTouchX: number = 0
  currentTouchY: number = 0
  isDragging: boolean = false
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
  @State crosswordOffsetY: number = DEFAULT_LEVEL_LAYOUT.crosswordOffsetY
  pageEnterMs: number = 0
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private bonusCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  bonusCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.bonusCanvasSettings)
  ignoreCurrentPan: boolean = false
  lastHintTapMs: number = 0
  hintFlashSeq: number = 0
  revealedLevelId: number = 0
  lineAnimTimerId: number = 0
  readonly LETTER_CENTER: number = GameLayout.LETTER_SIZE / 2
  readonly CANVAS_SIZE: number = AppSizes.SCREEN_SIZE
  readonly TOUCH_THRESHOLD: number = GameLayout.TOUCH_THRESHOLD + 4

  private letterPosById(id: number): number[] {
    for (let i = 0; i < this.letters.length; i++) {
      if (this.letters[i].id === id) {
        return [this.letterPos[i * 2] ?? 0, this.letterPos[i * 2 + 1] ?? 0]
      }
    }
    return [0, 0]
  }

  aboutToAppear(): void {
    gamePageStateActions.prepareGamePage(this)
  }

  aboutToDisappear(): void {
    gamePageStateActions.leaveGamePage(this)
  }

  onActiveLevelChanged(): void {
    gamePageStateActions.resetGamePageTransientUiState(this)
    gamePageStateActions.refreshGamePageState(this)
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Column() {
            ForEach(this.crosswordRows, (row: CrosswordRow) => {
              Row() {
                ForEach(row.cells, (cell: CrosswordCell) => {
                  if (cell.isActive) {
                    Stack({ alignContent: Alignment.Center }) {
                      Text(crosswordCellText(this, cell))
                        .width(this.crosswordCellSize)
                        .height(this.crosswordCellSize)
                        .fontSize(this.crosswordFontSize)
                        .fontColor(crosswordCellTextColor(this, cell))
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Center)
                    }
                    .width(this.crosswordCellSize)
                    .height(this.crosswordCellSize)
                    .backgroundColor(crosswordCellBg(this, cell))
                    .border({
                      width: crosswordCellBorderWidth(this, cell),
                      color: crosswordCellBorderColor(this, cell)
                    })
                    .scale({
                      x: crosswordCellScale(this, cell),
                      y: crosswordCellScale(this, cell)
                    })
                    .shadow({
                      radius: crosswordCellShadowRadius(this, cell),
                      color: crosswordCellShadowColor(this, cell),
                      offsetX: 0,
                      offsetY: 0
                    })
                    .animation({ duration: crosswordCellAnimDuration(this), curve: Curve.EaseOut })
                    .borderRadius(3)
                    .margin(1)
                  } else {
                    Text('')
                      .width(this.crosswordCellSize)
                      .height(this.crosswordCellSize)
                      .margin(1)
                      .opacity(0)
                  }
                }, (cell: CrosswordCell) => `${this.activeLevelId}_${crosswordCellKey(cell)}`)
              }
            }, (row: CrosswordRow) => `${this.activeLevelId}_${row.id}`)
          }
          .backgroundColor('#000000DD')
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

        ForEach(this.letters, (item: LetterItem) => {
          Stack() {
            Circle()
              .width(GameLayout.LETTER_SIZE - 5)
              .height(GameLayout.LETTER_SIZE - 5)
              .fill('transparent')
              .stroke(letterStrokeColor(this, item))
              .strokeWidth(item.isSelected || this.feedbackLetterIds.indexOf(item.id) !== -1 ? 3 : 2)
              .opacity(item.isSelected || this.feedbackLetterIds.indexOf(item.id) !== -1 ? 1 : 0.88)
              .scale({
                x: letterScale(this, item),
                y: letterScale(this, item)
              })
              .shadow({
                radius: item.isSelected || this.feedbackLetterIds.indexOf(item.id) !== -1 ? 12 : 1,
                color: letterGlowColor(this, item),
                offsetX: 0,
                offsetY: 0
              })
              .animation({ duration: 150, curve: Curve.EaseOut })

            Text(item.letter)
              .fontSize(20)
              .fontColor(letterTextColor(this, item))
              .fontWeight(FontWeight.Bold)
          }
          .width(GameLayout.LETTER_SIZE)
          .height(GameLayout.LETTER_SIZE)
          .position({ x: this.letterPosById(item.id)[0], y: this.letterPosById(item.id)[1] })
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
            drawGamePageLines(this)
          })

        Text(this.currentWord)
          .width(130)
          .height(26)
          .position({ x: 51.5, y: 103.5 })
          .fontSize(18)
          .fontColor(this.showError ? '#FF5252' : AppColors.PRIMARY_GOLD)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)

        BackButton({ btnSize: 28, bgColor: '#00000066' }).position({ x: 66, y: 18 })

        Stack() {
          HintButton({
            isEnabled: this.hintCount > 0,
            count: this.hintCount,
            onTap: () => {
              handleGamePageHintTap(this)
            }
          })
        }.position({ x: this.hintPosX, y: this.hintPosY })

        if (this.bonusWordsTotal > 0) {
          Stack() {
            Canvas(this.bonusCanvasCtx)
              .width(30)
              .height(30)
              .onReady(() => {
                drawGamePageBonusIndicator(this)
              })
            Text((this.bonusWordsTotal - this.bonusWordsFound).toString())
              .fontSize(12)
              .fontColor(AppColors.WHITE)
              .fontWeight(FontWeight.Bold)
          }
          .width(30)
          .height(30)
          .position({ x: this.bonusPosX, y: this.bonusPosY })
          .hitTestBehavior(HitTestMode.None)
        }

        Stack() {
          Circle()
            .width(GameLayout.SHUFFLE_SIZE)
            .height(GameLayout.SHUFFLE_SIZE)
            .fill('transparent')
            .stroke(AppColors.PRIMARY_GOLD)
            .strokeWidth(2)
            .opacity(0.8)
          Text('🔀')
            .fontSize(18)
            .fontColor(AppColors.PRIMARY_GOLD)
            .fontWeight(FontWeight.Bold)
        }
        .width(GameLayout.SHUFFLE_SIZE)
        .height(GameLayout.SHUFFLE_SIZE)
        .borderRadius(GameLayout.SHUFFLE_SIZE / 2)
        .stateStyles({
          pressed: {
            .backgroundColor(AppColors.PRIMARY_GOLD)
          },
          normal: {
            .backgroundColor('#00000000')
          }
        })
        .position({ x: this.shufflePosX, y: this.shufflePosY })
        .onClick(() => {
          shuffleGamePageLetters(this)
        })

        if (this.showSuccess) {
          Column() {
            Text('\u2714')
              .fontSize(48)
              .fontColor(AppColors.SUCCESS_GREEN)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#00000080')
        }

        if (this.showBonusPopup) {
          Column() {
            Column() {
              Text('⭐ Bonus ⭐')
                .fontSize(22)
                .fontColor(AppColors.WHITE)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })
              Text(this.bonusWordFound)
                .fontSize(22)
                .fontColor(AppColors.WHITE)
                .fontWeight(FontWeight.Bold)
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
            Rect()
              .width('100%')
              .height('100%')
              .fill('#00000055')
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
                  Rect()
                    .width(120)
                    .height(40)
                    .fill(AppColors.GRAY_DARK)
                    .radius(15)
                  Text('Skip')
                    .fontSize(14)
                    .fontColor(AppColors.WHITE)
                    .fontWeight(FontWeight.Bold)
                }.onClick(() => {
                  gameState.closeTutorial(true)
                  gamePageStateActions.refreshGamePageState(this)
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
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgColor)
      .gesture(
        PanGesture({ fingers: 1, distance: 1 })
          .onActionStart((event: GestureEvent) => {
            if (event.fingerList.length > 0) {
              const finger = event.fingerList[0]
              if (isGamePageHintPoint(this, finger.localX, finger.localY)) {
                this.ignoreCurrentPan = true
                handleGamePageHintTap(this)
                return
              }
              this.ignoreCurrentPan = false
              gamePageStateActions.updateGamePagePressedByPos(this, finger.localX, finger.localY)
              gamePageStateActions.onGameTouchStart(this, finger.localX, finger.localY)
            }
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.ignoreCurrentPan) {
              return
            }
            if (event.fingerList.length > 0) {
              const finger = event.fingerList[0]
              gamePageStateActions.updateGamePagePressedByPos(this, finger.localX, finger.localY)
              gamePageStateActions.onGameTouchMove(this, finger.localX, finger.localY)
            }
          })
          .onActionEnd(() => {
            if (this.ignoreCurrentPan) {
              this.ignoreCurrentPan = false
              return
            }
            this.pressedLetterId = ''
            if (gamePageStateActions.onGameTouchEnd(this)) {
              submitGamePageWord(this)
            }
          })
      )
      .parallelGesture(
        TapGesture({ count: 1, fingers: 1 })
          .onAction((event: GestureEvent) => {
            if (event.fingerList.length > 0) {
              const finger = event.fingerList[0]
              if (isGamePageHintPoint(this, finger.localX, finger.localY)) {
                handleGamePageHintTap(this)
              }
            }
          })
      )
    }
    .hideTitleBar(true)
    .backgroundColor(AppColors.BACKGROUND_DARK)
    .onBackPressed(() => true)
    .onShown(() => {
      gamePageStateActions.refreshGamePageState(this)
    })
  }
}
