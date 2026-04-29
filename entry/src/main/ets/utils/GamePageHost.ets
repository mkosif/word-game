import { LinePoint, CrosswordRow } from '../model/GamePageModels'
import { LetterItem, WordSlot } from '../viewmodel/GameViewModel'

export interface GamePageHost {
  navPathStack: NavPathStack
  activeLevelId: number
  letters: LetterItem[]
  currentWord: string
  wordSlots: WordSlot[]
  showError: boolean
  showSuccess: boolean
  linePoints: LinePoint[]
  currentTouchX: number
  currentTouchY: number
  isDragging: boolean
  hintCount: number
  bonusWordsFound: number
  bonusWordsTotal: number
  showTutorial: boolean
  hintPosX: number
  hintPosY: number
  bonusPosX: number
  bonusPosY: number
  shufflePosX: number
  shufflePosY: number
  letterPos: number[]
  pressedLetterId: string
  snapLetterId: string
  snapLetterScale: number
  wrongFlash: boolean
  wrongShakeX: number
  successFlashSlotIndex: number
  successFlashOn: boolean
  showBonusPopup: boolean
  bonusWordFound: string
  bonusPopupScale: number
  bonusPopupOpacity: number
  lineFeedback: string
  feedbackLetterIds: number[]
  hintFlashKeys: string[]
  hintFlashOn: boolean
  hintFlashPhase: number
  revealedCellKeys: string[]
  bgColor: string
  crosswordRows: CrosswordRow[]
  crosswordCellSize: number
  crosswordFontSize: number
  crosswordOffsetY: number
  pageEnterMs: number
  canvasContext: CanvasRenderingContext2D
  bonusCanvasCtx: CanvasRenderingContext2D
  ignoreCurrentPan: boolean
  lastHintTapMs: number
  hintFlashSeq: number
  revealedLevelId: number
  lineAnimTimerId: number
  readonly LETTER_CENTER: number
  readonly CANVAS_SIZE: number
  readonly TOUCH_THRESHOLD: number
  getUIContext(): UIContext
}
