import { window } from '@kit.ArkUI'
import { difficultyBgColor, GameLayout } from '../common/Constants'
import { hapticManager, HapticNames } from '../common/HapticManager'
import { soundManager, SoundNames } from '../common/SoundManager'
import { StatsStore } from '../components/StatsStore'
import { DEFAULT_LEVEL_LAYOUT, LevelLayout } from '../model/LevelData'
import { LetterItem, gameState } from '../viewmodel/GameViewModel'
import {
  buildCrosswordGrid,
  buildLetterPositions,
  buildLinePoints,
  cloneLetters,
  cloneWordSlots,
  CrosswordGridResult
} from '../model/GamePageModels'
import { drawGamePageBonusIndicator, drawGamePageLines } from './GamePageDrawing'
import { GamePageHost } from './GamePageHost'

export function prepareGamePage(host: GamePageHost): void {
  setGestureBackEnabled(host, false)
  gameState.ensureTutorialOnFirstLaunch()
  host.pageEnterMs = Date.now()
  refreshGamePageState(host)
}

export function leaveGamePage(host: GamePageHost): void {
  stopLineAnimationLoop(host)
  setGestureBackEnabled(host, true)
  const delta = Date.now() - host.pageEnterMs
  StatsStore.addPlayTimeMs(delta)
}

export function setGestureBackEnabled(host: GamePageHost, enabled: boolean): void {
  const context = host.getUIContext().getHostContext()
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

export function refreshGamePageState(host: GamePageHost): void {
  host.currentWord = gameState.currentWord
  host.showError = gameState.showError
  host.showTutorial = gameState.showTutorial
  host.letters = cloneLetters(gameState.letters)
  host.wordSlots = cloneWordSlots(gameState.wordSlots)
  syncRevealedCellKeys(host)
  updateLinePoints(host)
  host.hintCount = gameState.hintCount
  host.bonusWordsFound = gameState.bonusWordsFound.length
  host.bonusWordsTotal =
    gameState.currentLevel && gameState.currentLevel.bonusWords ? gameState.currentLevel.bonusWords.length : 0
  syncGamePageLevelLayout(host)
  host.hintPosX = gameState.hintPos[0]
  host.hintPosY = gameState.hintPos[1]
  host.bonusPosX = gameState.bonusPos[0]
  host.bonusPosY = gameState.bonusPos[1]
  host.shufflePosX = gameState.shufflePos[0]
  host.shufflePosY = gameState.shufflePos[1]
  drawGamePageBonusIndicator(host)
  syncGamePageLetterPos(host)
  syncCrosswordGrid(host)
  host.bgColor = difficultyBgColor(gameState.currentLevel?.difficulty ?? 'medium')
}

export function syncGamePageLetterPos(host: GamePageHost): void {
  host.letterPos = buildLetterPositions(host.letters)
}

export function resetGamePageTransientUiState(host: GamePageHost): void {
  clearGamePageFeedback(host)
  host.showSuccess = false
  host.showError = false
  host.wrongFlash = false
  host.wrongShakeX = 0
  host.successFlashSlotIndex = -1
  host.successFlashOn = false
  host.showBonusPopup = false
  host.bonusPopupScale = 0
  host.bonusPopupOpacity = 0
  host.hintFlashSeq += 1
  host.hintFlashKeys = []
  host.hintFlashOn = false
  host.hintFlashPhase = 0
  host.pressedLetterId = ''
  host.snapLetterId = ''
  host.snapLetterScale = 1
}

export function onGameTouchStart(host: GamePageHost, x: number, y: number): void {
  host.lineFeedback = 'normal'
  host.feedbackLetterIds = []
  host.isDragging = true
  startLineAnimationLoop(host)
  host.currentTouchX = x
  host.currentTouchY = y
  const letter = findLetterAtPosition(host, x, y)
  if (letter !== null && !letter.isSelected) {
    selectGameLetter(host, letter)
  }
  drawGamePageLines(host)
}

export function onGameTouchMove(host: GamePageHost, x: number, y: number): void {
  if (!host.isDragging) {
    return
  }
  host.currentTouchX = x
  host.currentTouchY = y
  const letter = findLetterAtPosition(host, x, y)
  if (letter !== null) {
    handleMovedLetter(host, letter)
  }
  drawGamePageLines(host)
}

export function onGameTouchEnd(host: GamePageHost): boolean {
  host.isDragging = false
  stopLineAnimationLoop(host)
  drawGamePageLines(host)
  if (host.currentWord.length >= GameLayout.MIN_WORD_LENGTH) {
    return true
  }
  gameState.clearSelection()
  refreshGamePageState(host)
  host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
  return false
}

export function stopLineAnimationLoop(host: GamePageHost): void {
  if (host.lineAnimTimerId > 0) {
    clearInterval(host.lineAnimTimerId)
    host.lineAnimTimerId = 0
  }
}

export function playLetterSnap(host: GamePageHost, id: number): void {
  const key = id.toString()
  host.snapLetterId = key
  host.snapLetterScale = 1.08
  host.getUIContext().animateTo({ duration: 70, curve: Curve.EaseOut }, () => {
    host.snapLetterScale = 1.14
  })
  setTimeout(() => {
    if (host.snapLetterId !== key) {
      return
    }
    host.getUIContext().animateTo({ duration: 90, curve: Curve.EaseIn }, () => {
      host.snapLetterScale = 1.03
    })
  }, 75)
  setTimeout(() => {
    if (host.snapLetterId !== key) {
      return
    }
    host.getUIContext().animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
      host.snapLetterScale = 1
    })
  }, 170)
  setTimeout(() => {
    if (host.snapLetterId === key) {
      host.snapLetterId = ''
    }
  }, 285)
}

export function updateGamePagePressedByPos(host: GamePageHost, x: number, y: number): void {
  const radius = GameLayout.LETTER_SIZE / 2
  const hit = radius * 1.18
  for (let i = 0; i < host.letters.length; i++) {
    const cx = (host.letterPos[i * 2] ?? 0) + radius
    const cy = (host.letterPos[i * 2 + 1] ?? 0) + radius
    const dx = x - cx
    const dy = y - cy
    if ((dx * dx + dy * dy) <= (hit * hit)) {
      host.pressedLetterId = host.letters[i].id.toString()
      return
    }
  }
  host.pressedLetterId = ''
}

export function clearGamePageFeedback(host: GamePageHost): void {
  host.lineFeedback = 'normal'
  host.feedbackLetterIds = []
  host.linePoints = []
  host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
}

export function addUniqueKey(keys: string[], key: string): void {
  if (keys.indexOf(key) === -1) {
    keys.push(key)
  }
}

function syncGamePageLevelLayout(host: GamePageHost): void {
  const layout: LevelLayout = gameState.currentLevel?.layout ?? DEFAULT_LEVEL_LAYOUT
  host.crosswordOffsetY = layout.crosswordOffsetY
}

function syncCrosswordGrid(host: GamePageHost): void {
  const levelGrid = gameState.currentLevel ? gameState.currentLevel.grid : []
  const result: CrosswordGridResult = buildCrosswordGrid(levelGrid, host.wordSlots)
  host.crosswordRows = result.rows
  host.crosswordCellSize = result.cellSize
  host.crosswordFontSize = result.fontSize
}

function syncRevealedCellKeys(host: GamePageHost): void {
  if (host.revealedLevelId !== gameState.currentLevelId) {
    host.revealedLevelId = gameState.currentLevelId
    host.revealedCellKeys = []
  }
  const keys = host.revealedCellKeys.slice()
  for (let slotIndex = 0; slotIndex < host.wordSlots.length; slotIndex++) {
    const slot = host.wordSlots[slotIndex]
    for (let i = 0; i < slot.revealedIndexes.length; i++) {
      const letterIndex = slot.revealedIndexes[i]
      const row = slot.dir === 'H' ? slot.row : slot.row + letterIndex
      const col = slot.dir === 'H' ? slot.col + letterIndex : slot.col
      addUniqueKey(keys, `${row}:${col}`)
    }
  }
  host.revealedCellKeys = keys
}

function updateLinePoints(host: GamePageHost): void {
  host.linePoints = buildLinePoints(gameState.selectedLetters, host.LETTER_CENTER)
}

function findLetterAtPosition(host: GamePageHost, x: number, y: number): LetterItem | null {
  const thresholdSq = host.TOUCH_THRESHOLD * host.TOUCH_THRESHOLD
  for (let i = 0; i < host.letters.length; i++) {
    const letter = host.letters[i]
    const dx = x - (letter.x + host.LETTER_CENTER)
    const dy = y - (letter.y + host.LETTER_CENTER)
    if ((dx * dx + dy * dy) < thresholdSq) {
      return letter
    }
  }
  return null
}

function startLineAnimationLoop(host: GamePageHost): void {
  if (host.lineAnimTimerId > 0) {
    return
  }
  host.lineAnimTimerId = setInterval(() => {
    if (!host.isDragging) {
      stopLineAnimationLoop(host)
      return
    }
    drawGamePageLines(host)
  }, 66) as number
}

function selectGameLetter(host: GamePageHost, letter: LetterItem): void {
  gameState.selectLetter(letter)
  playLetterSnap(host, letter.id)
  soundManager.play(SoundNames.LETTER_SELECT)
  hapticManager.play(HapticNames.LETTER_SELECT)
  refreshGamePageState(host)
}

function handleMovedLetter(host: GamePageHost, letter: LetterItem): void {
  if (!letter.isSelected) {
    selectGameLetter(host, letter)
    return
  }
  const selected = gameState.selectedLetters
  if (selected.length >= 2 && selected[selected.length - 2].id === letter.id) {
    gameState.undoLastLetter()
    playLetterSnap(host, letter.id)
    soundManager.play(SoundNames.LETTER_SELECT)
    hapticManager.play(HapticNames.LETTER_SELECT)
    refreshGamePageState(host)
  }
}
