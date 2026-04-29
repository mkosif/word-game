import { CURRENT_LEVEL_KEY, getLevelById, Level, MAX_UNLOCKED_KEY } from '../model/LevelData'
import { AppSizes, GameLayout } from '../common/Constants'
import { secureRandomNumber } from '../utils/SecureRandom'

interface WordPos {
  row: number
  col: number
  dir: string
}

class HintCandidate {
  slotIndex: number = 0
  letterIndex: number = 0

  constructor(slotIndex: number, letterIndex: number) {
    this.slotIndex = slotIndex
    this.letterIndex = letterIndex
  }
}

@Observed
export class LetterItem {
  id: number = 0
  letter: string = ''
  isSelected: boolean = false
  x: number = 0
  y: number = 0

  constructor(id: number, letter: string, x: number, y: number) {
    this.id = id
    this.letter = letter
    this.isSelected = false
    this.x = x
    this.y = y
  }

  clone(): LetterItem {
    const item = new LetterItem(this.id, this.letter, this.x, this.y)
    item.isSelected = this.isSelected
    return item
  }
}

@Observed
export class WordSlot {
  word: string = ''
  isFound: boolean = false
  letters: string[] = []
  revealedIndexes: number[] = []
  row: number = 0
  col: number = 0
  dir: string = 'H'

  constructor(word: string, row: number, col: number, dir: string) {
    this.word = word
    this.isFound = false
    this.letters = word.split('')
    this.revealedIndexes = []
    this.row = row
    this.col = col
    this.dir = dir
  }

  clone(): WordSlot {
    const slot = new WordSlot(this.word, this.row, this.col, this.dir)
    slot.isFound = this.isFound
    slot.revealedIndexes = this.revealedIndexes.slice()
    return slot
  }
}

@Observed
export class GameState {
  static readonly TUTORIAL_DONE: string = 'tutorialDone'
  static readonly INITIAL_HINT_COUNT: number = 3
  hintCount: number = GameState.INITIAL_HINT_COUNT
  hintIndex: number = 0
  currentLevelId: number = 1
  maxUnlockedLevel: number = 1
  letters: LetterItem[] = []
  selectedLetters: LetterItem[] = []
  currentWord: string = ''
  wordSlots: WordSlot[] = []
  foundWords: string[] = []
  bonusWordsFound: string[] = []
  currentLevel: Level | undefined
  levelScore: number = 0
  isLevelComplete: boolean = false
  showError: boolean = false
  hintPos: number[] = [0, 0]
  bonusPos: number[] = [0, 0]
  shufflePos: number[] = [0, 0]
  isTutorialDone: boolean = false
  showTutorial: boolean = false

  constructor() {
    this.maxUnlockedLevel = AppStorage.get<number>(MAX_UNLOCKED_KEY) ?? 1
    this.currentLevelId = AppStorage.get<number>(CURRENT_LEVEL_KEY) ?? 1
    this.isTutorialDone = AppStorage.get<boolean>(GameState.TUTORIAL_DONE) ?? false
  }

  ensureTutorialOnFirstLaunch(): void {
    this.isTutorialDone = AppStorage.get<boolean>(GameState.TUTORIAL_DONE) ?? false
    if (!this.isTutorialDone) {
      this.showTutorial = true
    }
  }

  closeTutorial(markDone: boolean): void {
    this.showTutorial = false
    if (markDone) {
      this.isTutorialDone = true
      AppStorage.set<boolean>(GameState.TUTORIAL_DONE, true)
    }
  }

  loadLevel(levelId: number): void {
    const level = getLevelById(levelId)
    if (!level) {
      return
    }

    this.currentLevel = level
    this.currentLevelId = levelId
    this.resetLevelState(level)
    AppStorage.set(CURRENT_LEVEL_KEY, levelId)
  }

  unlockNextLevel(): void {
    this.maxUnlockedLevel = this.currentLevelId + 1
    AppStorage.set(MAX_UNLOCKED_KEY, this.maxUnlockedLevel)
  }

  useHint(): boolean {
    if (this.hintCount <= 0) {
      return false
    }
    const candidates: HintCandidate[] = []
    for (let slotIndex = 0; slotIndex < this.wordSlots.length; slotIndex++) {
      const slot = this.wordSlots[slotIndex]
      if (slot.isFound) {
        continue
      }
      for (let letterIndex = 0; letterIndex < slot.word.length; letterIndex++) {
        if (slot.revealedIndexes.indexOf(letterIndex) === -1) {
          candidates.push(new HintCandidate(slotIndex, letterIndex))
        }
      }
    }

    if (candidates.length === 0) {
      return false
    }

    const selectedIndex = Math.floor(secureRandomNumber() * candidates.length)
    const selected = candidates[selectedIndex]
    this.wordSlots[selected.slotIndex].revealedIndexes.push(selected.letterIndex)
    this.hintCount -= 1
    this.updateScore()
    return true
  }

  shuffleLetters(): void {
    if (this.letters.length < 2) {
      return
    }
    const positions: number[][] = []
    for (let i = 0; i < this.letters.length; i++) {
      positions.push([this.letters[i].x, this.letters[i].y])
    }
    const origX0 = positions[0][0]
    for (let i = positions.length - 1; i > 0; i--) {
      const j = Math.floor(secureRandomNumber() * (i + 1))
      const tmp = positions[i]
      positions[i] = positions[j]
      positions[j] = tmp
    } // Identity permutation — force a swap so something always changes
    if (Math.abs(positions[0][0] - origX0) < 1) {
      const tmp = positions[0]
      positions[0] = positions[1]
      positions[1] = tmp
    }
    for (let i = 0; i < this.letters.length; i++) {
      this.letters[i].x = positions[i][0]
      this.letters[i].y = positions[i][1]
    }
    this.selectedLetters = []
    this.currentWord = ''
  }

  selectLetter(letterItem: LetterItem): void {
    if (letterItem.isSelected) {
      this.deselectLetter(letterItem)
      return
    }

    const index = this.letters.findIndex((l: LetterItem) => l.id === letterItem.id)
    if (index !== -1) {
      this.letters[index].isSelected = true
      this.selectedLetters.push(this.letters[index])
      this.updateCurrentWord()
    }
  }

  submitWord(): boolean {
    if (this.currentWord.length < GameLayout.MIN_WORD_LENGTH) {
      this.clearSelection()
      return false
    }

    let slotIndex = -1
    for (let i = 0; i < this.wordSlots.length; i++) {
      if (this.wordSlots[i].word === this.currentWord && !this.wordSlots[i].isFound) {
        slotIndex = i
        break
      }
    }

    if (slotIndex !== -1) {
      this.wordSlots[slotIndex].isFound = true
      this.foundWords.push(this.currentWord)

      let allFound = true
      for (let i = 0; i < this.wordSlots.length; i++) {
        if (!this.wordSlots[i].isFound) {
          allFound = false
          break
        }
      }
      this.isLevelComplete = allFound
      if (this.isLevelComplete) {
        this.unlockNextLevel()
      }

      this.updateScore()
      this.clearSelection()
      return true
    }

    if (this.isBonusWord(this.currentWord)) {
      if (!this.bonusWordsFound.includes(this.currentWord)) {
        this.bonusWordsFound.push(this.currentWord)
        this.updateScore()
      }
      this.clearSelection()
      return true
    }

    this.showError = true
    this.clearSelection()
    return false
  }

  undoLastLetter(): void {
    if (this.selectedLetters.length === 0) {
      return
    }
    const last = this.selectedLetters[this.selectedLetters.length - 1]
    const index = this.letters.findIndex((l: LetterItem) => l.id === last.id)
    if (index !== -1) {
      this.letters[index].isSelected = false
    }
    this.selectedLetters.pop()
    this.updateCurrentWord()
  }

  clearSelection(): void {
    for (let i = 0; i < this.letters.length; i++) {
      this.letters[i].isSelected = false
    }
    this.selectedLetters = []
    this.currentWord = ''
  }

  hideError(): void {
    this.showError = false
  }

  private resetLevelState(level: Level): void {
    this.selectedLetters = []
    this.currentWord = ''
    this.foundWords = []
    this.bonusWordsFound = []
    this.levelScore = 0
    this.isLevelComplete = false
    this.showError = false
    this.hintCount = GameState.INITIAL_HINT_COUNT
    this.hintIndex = 0

    this.letters = this.arrangeLettersInCircle(level.letters)
    this.computeIndicatorPositions(level.letters.length)
    this.wordSlots = level.words.map((word: string) => {
      const pos = this.findWordInGrid(word, level.grid)
      return new WordSlot(word, pos?.row ?? 0, pos?.col ?? 0, pos?.dir ?? 'H')
    })
    this.updateScore()
  }

  private findWordInGrid(word: string, grid: string[][]): WordPos | undefined {
    const rows = grid.length
    // H scan
    for (let r = 0; r < rows; r++) {
      const cols = grid[r].length
      for (let c = 0; c <= cols - word.length; c++) {
        let ok = true
        for (let i = 0; i < word.length; i++) {
          if ((grid[r][c + i] ?? '') !== word[i]) { ok = false; break }
        }
        const leftOk  = c === 0 || (grid[r][c - 1] ?? '') === ''
        const rightOk = c + word.length >= cols || (grid[r][c + word.length] ?? '') === ''
        if (ok && leftOk && rightOk) {
          const pos: WordPos = { row: r, col: c, dir: 'H' }
          return pos
        }
      }
    }
    // V scan
    const cols0 = grid[0]?.length ?? 0
    for (let c = 0; c < cols0; c++) {
      for (let r = 0; r <= rows - word.length; r++) {
        let ok = true
        for (let i = 0; i < word.length; i++) {
          if ((grid[r + i][c] ?? '') !== word[i]) { ok = false; break }
        }
        const topOk    = r === 0 || (grid[r - 1][c] ?? '') === ''
        const bottomOk = r + word.length >= rows || (grid[r + word.length][c] ?? '') === ''
        if (ok && topOk && bottomOk) {
          const pos: WordPos = { row: r, col: c, dir: 'V' }
          return pos
        }
      }
    }
    return undefined
  }

  private arrangeLettersInCircle(letterArray: string[]): LetterItem[] {
    const result: LetterItem[] = []
    const center = Math.floor(AppSizes.SCREEN_SIZE / 2)
    const radius = AppSizes.LETTER_EDGE_RADIUS
    const half = GameLayout.LETTER_SIZE / 2
    const count = letterArray.length

    for (let i = 0; i < count; i++) {
      const angle = (2 * Math.PI * i / count) - Math.PI / 2
      const x = center + radius * Math.cos(angle) - half
      const y = center + radius * Math.sin(angle) - half
      result.push(new LetterItem(i, letterArray[i], x, y))
    }
    return result
  }

  // Place hint, bonus & shuffle in the gaps between letters on the same circle.
  private computeIndicatorPositions(count: number): void {
    const center = Math.floor(AppSizes.SCREEN_SIZE / 2)
    const radius = AppSizes.LETTER_EDGE_RADIUS
    const step = 2 * Math.PI / count

    // Gaps are evenly spaced, so nearest index = round(offset / step)
    const nearestGap =
      (target: number): number => ((Math.round((target + Math.PI / 2 - step / 2) / step) % count) + count) % count

    const hintIdx = nearestGap(-Math.PI / 4) // upper-right
    let bonusIdx = nearestGap(Math.PI / 2) // bottom
    if (bonusIdx === hintIdx) {
      bonusIdx = (bonusIdx + 1) % count
    }

    let shuffleIdx = nearestGap(Math.PI)
    if (shuffleIdx === hintIdx) {
      shuffleIdx = (shuffleIdx + 1) % count
    }
    if (shuffleIdx === bonusIdx) {
      shuffleIdx = (shuffleIdx + 1) % count
    }
    if (shuffleIdx === hintIdx) {
      shuffleIdx = bonusIdx
    } // 2-letter fallback: overlaps hidden bonus

    // Gap index -> top-left pixel position
    const toPos = (i: number, half: number): number[] => {
      const a = step * i - Math.PI / 2 + step / 2
      return [center + radius * Math.cos(a) - half, center + radius * Math.sin(a) - half]
    }

    this.hintPos = toPos(hintIdx, GameLayout.HINT_SIZE / 2)
    this.bonusPos = toPos(bonusIdx, GameLayout.BONUS_SIZE / 2)
    this.shufflePos = toPos(shuffleIdx, GameLayout.SHUFFLE_SIZE / 2)
  }

  private deselectLetter(letterItem: LetterItem): void {
    const index = this.letters.findIndex((l: LetterItem) => l.id === letterItem.id)
    if (index !== -1) {
      this.letters[index].isSelected = false
      const selectedIndex = this.selectedLetters.findIndex((l: LetterItem) => l.id === letterItem.id)
      if (selectedIndex !== -1) {
        this.selectedLetters.splice(selectedIndex, 1)
      }
      this.updateCurrentWord()
    }
  }

  private updateCurrentWord(): void {
    this.currentWord = this.selectedLetters.map((item: LetterItem) => item.letter).join('')
  }

  private isBonusWord(word: string): boolean {
    if (!this.currentLevel || !this.currentLevel.bonusWords) {
      return false
    }
    return this.currentLevel.bonusWords.includes(word)
  }

  private updateScore(): void {
    const totalWords = this.wordSlots.length
    const bonusTotal = this.currentLevel && this.currentLevel.bonusWords ? this.currentLevel.bonusWords.length : 0

    const mainScore = totalWords > 0 ? Math.round(60 * this.foundWords.length / totalWords) : 0
    const bonusScore = bonusTotal > 0 ? Math.round(40 * this.bonusWordsFound.length / bonusTotal) : 40
    const hintsUsed = GameState.INITIAL_HINT_COUNT - this.hintCount
    const hintPenalty = hintsUsed * (60 / GameState.INITIAL_HINT_COUNT)

    this.levelScore = Math.max(0, mainScore + bonusScore - hintPenalty)
  }
}

export const gameState = new GameState()
