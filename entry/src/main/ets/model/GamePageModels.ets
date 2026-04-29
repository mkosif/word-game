import { LetterItem, WordSlot } from '../viewmodel/GameViewModel'

export class LinePoint {
  x: number = 0
  y: number = 0

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}

export class CrosswordCell {
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

export class CrosswordRow {
  cells: CrosswordCell[] = []
  id: string = ''
}

export class CrosswordGridResult {
  rows: CrosswordRow[] = []
  cellSize: number = 20
  fontSize: number = 13
}

export function cloneLetters(source: LetterItem[]): LetterItem[] {
  const letters: LetterItem[] = []
  for (let i = 0; i < source.length; i++) {
    letters.push(source[i].clone())
  }
  return letters
}

export function cloneWordSlots(source: WordSlot[]): WordSlot[] {
  const slots: WordSlot[] = []
  for (let i = 0; i < source.length; i++) {
    slots.push(source[i].clone())
  }
  return slots
}

export function buildLetterPositions(letters: LetterItem[]): number[] {
  const positions: number[] = []
  for (let i = 0; i < letters.length; i++) {
    positions.push(letters[i].x)
    positions.push(letters[i].y)
  }
  return positions
}

export function buildLinePoints(letters: LetterItem[], letterCenter: number): LinePoint[] {
  const points: LinePoint[] = []
  for (let i = 0; i < letters.length; i++) {
    const letter = letters[i]
    points.push(new LinePoint(letter.x + letterCenter, letter.y + letterCenter))
  }
  return points
}

export function buildCrosswordGrid(levelGrid: string[][], wordSlots: WordSlot[]): CrosswordGridResult {
  const result = new CrosswordGridResult()
  if (levelGrid.length === 0 || wordSlots.length === 0) {
    return result
  }
  const gridRows = levelGrid.length
  const gridCols = gridRows > 0 ? levelGrid[0].length : 0
  const maxDim = Math.max(gridRows, gridCols)
  result.cellSize = maxDim > 0 ? Math.max(12, Math.floor(110 / maxDim)) : 20
  result.fontSize = Math.max(7, Math.floor(result.cellSize * 0.65))
  const full = buildRawCrosswordCells(levelGrid, gridRows, gridCols)
  applyWordSlotMetadata(full, wordSlots, gridRows, gridCols)
  for (let r = 0; r < gridRows; r++) {
    const row = new CrosswordRow()
    row.id = `row_${r}`
    for (let c = 0; c < gridCols; c++) {
      row.cells.push(full[r][c])
    }
    result.rows.push(row)
  }
  return result
}

function buildRawCrosswordCells(levelGrid: string[][], gridRows: number, gridCols: number): CrosswordCell[][] {
  const full: CrosswordCell[][] = []
  for (let r = 0; r < gridRows; r++) {
    const row: CrosswordCell[] = []
    for (let c = 0; c < gridCols; c++) {
      const cell = new CrosswordCell()
      cell.row = r
      cell.col = c
      if ((levelGrid[r]?.[c] ?? '') !== '') {
        cell.isActive = true
        cell.letter = levelGrid[r][c]
      }
      row.push(cell)
    }
    full.push(row)
  }
  return full
}

function applyWordSlotMetadata(
  full: CrosswordCell[][],
  wordSlots: WordSlot[],
  gridRows: number,
  gridCols: number
): void {
  for (let slotIndex = 0; slotIndex < wordSlots.length; slotIndex++) {
    const slot = wordSlots[slotIndex]
    for (let letterIndex = 0; letterIndex < slot.word.length; letterIndex++) {
      const row = slot.dir === 'H' ? slot.row : slot.row + letterIndex
      const col = slot.dir === 'H' ? slot.col + letterIndex : slot.col
      if (row >= 0 && row < gridRows && col >= 0 && col < gridCols) {
        updateCrosswordCell(full[row][col], slot, slotIndex, letterIndex)
      }
    }
  }
}

function updateCrosswordCell(
  cell: CrosswordCell,
  slot: WordSlot,
  slotIndex: number,
  letterIndex: number
): void {
  const wasFound = cell.isFound
  if (slot.isFound) {
    cell.isFound = true
  }
  if (slot.revealedIndexes.indexOf(letterIndex) !== -1) {
    cell.isRevealed = true
  }
  if (cell.slotIndex === -1 || (slot.isFound && !wasFound)) {
    cell.slotIndex = slotIndex
    cell.letterIndex = letterIndex
    cell.revealedIndexes = slot.revealedIndexes.slice()
  }
}
