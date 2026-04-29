import { GameLayout, PageNames } from '../common/Constants'
import { hapticManager, HapticNames } from '../common/HapticManager'
import { soundManager, SoundNames } from '../common/SoundManager'
import { StatsStore } from '../components/StatsStore'
import { buildLetterPositions, cloneLetters } from '../model/GamePageModels'
import { WordSlot, gameState } from '../viewmodel/GameViewModel'
import { drawGamePageLines } from './GamePageDrawing'
import { GamePageHost } from './GamePageHost'
import { clearGamePageFeedback, refreshGamePageState } from './GamePageStateActions'

export function submitGamePageWord(host: GamePageHost): void {
  const submittedPoints = host.linePoints.slice()
  const submittedLetterIds = selectedLetterIds()
  if (host.currentWord.length < GameLayout.MIN_WORD_LENGTH) {
    clearGamePageFeedback(host)
    gameState.clearSelection()
    refreshGamePageState(host)
    host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
    return
  }
  const prevFound = foundSlotSnapshot(host.wordSlots)
  const prevBonusCount = gameState.bonusWordsFound.length
  const success = gameState.submitWord()
  refreshGamePageState(host)
  host.feedbackLetterIds = submittedLetterIds
  host.linePoints = submittedPoints
  const isBonusWord = success && gameState.bonusWordsFound.length > prevBonusCount
  updateSubmitFeedback(host, success)
  drawGamePageLines(host)
  if (success) {
    handleSuccessfulWord(host, prevFound)
  }
  if (success && isBonusWord) {
    showGamePageBonusPopupAnimation(host)
  } else if (success) {
    showGamePageSuccessOverlay(host)
  } else {
    showGamePageErrorAnimation(host)
  }
}

export function shuffleGamePageLetters(host: GamePageHost): void {
  gameState.shuffleLetters()
  soundManager.play(SoundNames.SHUFFLE)
  hapticManager.play(HapticNames.SHUFFLE)
  host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
  host.letters = cloneLetters(gameState.letters)
  host.getUIContext().animateTo({ duration: 420, curve: Curve.EaseInOut }, () => {
    host.letterPos = buildLetterPositions(gameState.letters)
  })
}

function updateSubmitFeedback(host: GamePageHost, success: boolean): void {
  if (success) {
    soundManager.play(gameState.isLevelComplete ? SoundNames.LEVEL_COMPLETE : SoundNames.CORRECT_WORD)
    hapticManager.play(gameState.isLevelComplete ? HapticNames.LEVEL_COMPLETE : HapticNames.CORRECT_WORD)
    host.lineFeedback = 'success'
    if (host.showTutorial) {
      gameState.closeTutorial(true)
      host.showTutorial = false
    }
    return
  }
  soundManager.play(SoundNames.WRONG_WORD)
  hapticManager.play(HapticNames.WRONG_WORD)
  host.lineFeedback = 'wrong'
}

function handleSuccessfulWord(host: GamePageHost, prevFound: boolean[]): void {
  const newIndex = findNewlyFoundSlot(host.wordSlots, prevFound)
  if (newIndex !== -1) {
    StatsStore.addWordsFound(1)
    host.successFlashSlotIndex = newIndex
    host.successFlashOn = true
    setTimeout(() => {
      host.successFlashOn = false
      host.successFlashSlotIndex = -1
    }, 360)
  }
  setTimeout(() => {
    clearGamePageFeedback(host)
  }, 520)
  if (gameState.isLevelComplete) {
    const durationMs = Date.now() - host.pageEnterMs
    StatsStore.setLastCompletedLevelMs(durationMs)
    StatsStore.trySetFastest(gameState.currentLevelId, durationMs)
  }
}

function selectedLetterIds(): number[] {
  const ids: number[] = []
  for (let i = 0; i < gameState.selectedLetters.length; i++) {
    ids.push(gameState.selectedLetters[i].id)
  }
  return ids
}

function foundSlotSnapshot(wordSlots: WordSlot[]): boolean[] {
  const found: boolean[] = []
  for (let i = 0; i < wordSlots.length; i++) {
    found.push(wordSlots[i].isFound)
  }
  return found
}

function findNewlyFoundSlot(wordSlots: WordSlot[], prevFound: boolean[]): number {
  for (let i = 0; i < wordSlots.length; i++) {
    if (wordSlots[i].isFound && !prevFound[i]) {
      return i
    }
  }
  return -1
}

function showGamePageBonusPopupAnimation(host: GamePageHost): void {
  host.bonusWordFound = gameState.bonusWordsFound[gameState.bonusWordsFound.length - 1]
  host.showBonusPopup = true
  host.bonusPopupScale = 0
  host.bonusPopupOpacity = 0
  host.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
    host.bonusPopupScale = 1.15
    host.bonusPopupOpacity = 1
  })
  setTimeout(() => {
    host.getUIContext().animateTo({ duration: 150, curve: Curve.EaseIn }, () => {
      host.bonusPopupScale = 1.0
    })
  }, 250)
  setTimeout(() => {
    host.getUIContext().animateTo({ duration: 280, curve: Curve.EaseIn }, () => {
      host.bonusPopupScale = 0.8
      host.bonusPopupOpacity = 0
    })
    setTimeout(() => {
      host.showBonusPopup = false
    }, 280)
  }, 1500)
  setTimeout(() => {
    if (gameState.isLevelComplete) {
      host.navPathStack.pushPathByName(PageNames.WIN, null)
    }
  }, 1800)
}

function showGamePageSuccessOverlay(host: GamePageHost): void {
  host.showSuccess = true
  setTimeout(() => {
    host.showSuccess = false
    if (gameState.isLevelComplete) {
      host.navPathStack.pushPathByName(PageNames.WIN, null)
    }
  }, GameLayout.SUCCESS_DELAY)
}

function showGamePageErrorAnimation(host: GamePageHost): void {
  host.showError = true
  host.wrongFlash = true
  const delay = 45
  host.wrongShakeX = 7
  setTimeout(() => {
    host.wrongShakeX = -7
  }, delay)
  setTimeout(() => {
    host.wrongShakeX = 5
  }, delay * 2)
  setTimeout(() => {
    host.wrongShakeX = -3
  }, delay * 3)
  setTimeout(() => {
    host.wrongShakeX = 0
  }, delay * 4)
  setTimeout(() => {
    host.wrongFlash = false
    host.showError = false
  }, 260)
  setTimeout(() => {
    gameState.hideError()
    clearGamePageFeedback(host)
    refreshGamePageState(host)
    host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
  }, GameLayout.ERROR_DELAY)
}
