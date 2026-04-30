import { AppColors } from '../common/Constants'
import { CrosswordCell } from '../model/GamePageModels'
import { LetterItem, WordSlot } from '../viewmodel/GameViewModel'
import { GamePageHost } from './GamePageHost'

export function isHintFlashCell(host: GamePageHost, cell: CrosswordCell): boolean {
  const hintFlashKeys = host.hintFlashKeys ?? []
  return host.hintFlashOn && hintFlashKeys.indexOf(`${cell.row}:${cell.col}`) !== -1
}

export function isRevealedCell(host: GamePageHost, cell: CrosswordCell): boolean {
  const revealedCellKeys = host.revealedCellKeys ?? []
  return cell.isLetterRevealed() || revealedCellKeys.indexOf(`${cell.row}:${cell.col}`) !== -1
}

export function crosswordCellKey(cell: CrosswordCell): string {
  const found = cell.isFound ? 1 : 0
  const revealed = cell.isRevealed ? 1 : 0
  const parts: string[] = [
    'cell',
    cell.row.toString(),
    cell.col.toString(),
    cell.slotIndex.toString(),
    cell.letter,
    found.toString(),
    revealed.toString(),
    cell.revealedIndexes.join(',')
  ]
  return parts.join('_')
}

export function crosswordCellText(host: GamePageHost, cell: CrosswordCell): string {
  if (cell.isFound || isCellInFoundSlot(host, cell) || isRevealedCell(host, cell) || isHintFlashCell(host, cell)) {
    return cell.letter
  }
  return ''
}

export function crosswordCellTextColor(host: GamePageHost, cell: CrosswordCell): ResourceColor {
  return isHintFlashCell(host, cell) ? AppColors.BACKGROUND_DARK : AppColors.WHITE
}

export function crosswordCellBg(host: GamePageHost, cell: CrosswordCell): string {
  if (isHintFlashCell(host, cell)) {
    return host.hintFlashPhase === 3 ? AppColors.WORD_SLOT_FILLED : AppColors.PRIMARY_GOLD
  }
  if (host.wrongFlash) {
    return '#600020'
  }
  if (host.successFlashOn && host.successFlashSlotIndex === cell.slotIndex) {
    return '#1DB954'
  }
  if (cell.isFound || isCellInFoundSlot(host, cell)) {
    return AppColors.SUCCESS_GREEN
  }
  if (isRevealedCell(host, cell)) {
    return AppColors.WORD_SLOT_FILLED
  }
  return AppColors.WORD_SLOT_EMPTY
}

export function crosswordCellBorderWidth(host: GamePageHost, cell: CrosswordCell): number {
  if (isHintFlashCell(host, cell)) {
    return host.hintFlashPhase === 1 ? 3 : 2
  }
  return isRevealedCell(host, cell) && !cell.isFound ? 1 : 0
}

export function crosswordCellBorderColor(host: GamePageHost, cell: CrosswordCell): ResourceColor {
  if (isHintFlashCell(host, cell)) {
    return AppColors.STAR_GOLD
  }
  if (isRevealedCell(host, cell) && !cell.isFound) {
    return '#FFFFFF33'
  }
  return Color.Transparent
}

export function crosswordCellScale(host: GamePageHost, cell: CrosswordCell): number {
  if (isHintFlashCell(host, cell)) {
    if (host.hintFlashPhase === 1) {
      return 1.04
    }
    if (host.hintFlashPhase === 2) {
      return 1.12
    }
    return 1.03
  }
  if (host.successFlashOn && host.successFlashSlotIndex === cell.slotIndex) {
    return 1.08
  }
  return 1
}

export function crosswordCellShadowRadius(host: GamePageHost, cell: CrosswordCell): number {
  if (isHintFlashCell(host, cell)) {
    return host.hintFlashPhase === 1 ? 18 : 11
  }
  if (host.successFlashOn && host.successFlashSlotIndex === cell.slotIndex) {
    return 8
  }
  return 0
}

export function crosswordCellShadowColor(host: GamePageHost, cell: CrosswordCell): ResourceColor {
  if (isHintFlashCell(host, cell)) {
    return AppColors.STAR_GOLD
  }
  if (host.successFlashOn && host.successFlashSlotIndex === cell.slotIndex) {
    return AppColors.SUCCESS_GREEN
  }
  return Color.Transparent
}

export function crosswordCellAnimDuration(host: GamePageHost): number {
  return host.successFlashOn || host.wrongFlash || host.hintFlashOn ? 220 : 0
}

export function letterStrokeColor(host: GamePageHost, item: LetterItem): string {
  if (isFeedbackLetter(host, item.id)) {
    return host.lineFeedback === 'wrong' ? '#FF5252' : AppColors.LINE_GREEN
  }
  return item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE
}

export function letterTextColor(host: GamePageHost, item: LetterItem): string {
  if (isFeedbackLetter(host, item.id)) {
    return host.lineFeedback === 'wrong' ? '#FFB3B3' : '#D8FFB8'
  }
  return item.isSelected ? AppColors.PRIMARY_GOLD : AppColors.WHITE
}

export function letterGlowColor(host: GamePageHost, item: LetterItem): string {
  if (isFeedbackLetter(host, item.id)) {
    return host.lineFeedback === 'wrong' ? '#FF5252' : AppColors.LINE_GREEN
  }
  return item.isSelected || host.pressedLetterId === item.id.toString() ? '#FFD36A' : '#000000'
}

export function letterScale(host: GamePageHost, item: LetterItem): number {
  if (isFeedbackLetter(host, item.id)) {
    return host.lineFeedback === 'wrong' ? 1.12 : 1.16
  }
  if (host.snapLetterId === item.id.toString()) {
    return host.snapLetterScale
  }
  return host.pressedLetterId === item.id.toString() || item.isSelected ? 1.08 : 1.0
}

function isFeedbackLetter(host: GamePageHost, id: number): boolean {
  const feedbackLetterIds = host.feedbackLetterIds ?? []
  return feedbackLetterIds.indexOf(id) !== -1
}

function isCellInFoundSlot(host: GamePageHost, cell: CrosswordCell): boolean {
  for (let i = 0; i < host.wordSlots.length; i++) {
    const slot: WordSlot = host.wordSlots[i]
    if (!slot.isFound) {
      continue
    }
    if (isCellInsideSlot(cell, slot)) {
      return true
    }
  }
  return false
}

function isCellInsideSlot(cell: CrosswordCell, slot: WordSlot): boolean {
  for (let i = 0; i < slot.word.length; i++) {
    const row = slot.dir === 'H' ? slot.row : slot.row + i
    const col = slot.dir === 'H' ? slot.col + i : slot.col
    if (cell.row === row && cell.col === col) {
      return true
    }
  }
  return false
}
