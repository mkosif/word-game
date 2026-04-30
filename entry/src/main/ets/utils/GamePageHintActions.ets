import { GameLayout } from '../common/Constants'
import { hapticManager, HapticNames } from '../common/HapticManager'
import { WordSlot, gameState } from '../viewmodel/GameViewModel'
import { GamePageHost } from './GamePageHost'
import { addUniqueKey, clearGamePageFeedback, refreshGamePageState } from './GamePageStateActions'

export function handleGamePageHintTap(host: GamePageHost): void {
  const now = Date.now()
  if (host.hintCount <= 0 || now - host.lastHintTapMs < 250) {
    return
  }
  host.lastHintTapMs = now
  const revealedBefore = snapshotRevealedIndexes(host)
  clearGamePageFeedback(host)
  gameState.clearSelection()
  const didUseHint = gameState.useHint()
  refreshGamePageState(host)
  if (didUseHint) {
    hapticManager.play(HapticNames.HINT)
    flashHintCells(host, findNewHintCellKeys(revealedBefore))
  }
}

export function isGamePageHintPoint(host: GamePageHost, x: number, y: number): boolean {
  const padding = 8
  return x >= host.hintPosX - padding &&
    x <= host.hintPosX + GameLayout.HINT_SIZE + padding &&
    y >= host.hintPosY - padding &&
    y <= host.hintPosY + GameLayout.HINT_SIZE + padding
}

function snapshotRevealedIndexes(host: GamePageHost): string[] {
  const snapshot: string[] = []
  for (let slotIndex = 0; slotIndex < host.wordSlots.length; slotIndex++) {
    const slot = host.wordSlots[slotIndex]
    for (let i = 0; i < slot.revealedIndexes.length; i++) {
      snapshot.push(`${slotIndex}:${slot.revealedIndexes[i]}`)
    }
  }
  return snapshot
}

function findNewHintCellKeys(revealedBefore: string[]): string[] {
  const keys: string[] = []
  for (let slotIndex = 0; slotIndex < gameState.wordSlots.length; slotIndex++) {
    const slot: WordSlot = gameState.wordSlots[slotIndex]
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

function flashHintCells(host: GamePageHost, keys: string[]): void {
  if (keys.length === 0) {
    return
  }
  const revealedKeys = host.revealedCellKeys.slice()
  for (let i = 0; i < keys.length; i++) {
    addUniqueKey(revealedKeys, keys[i])
  }
  host.revealedCellKeys = revealedKeys
  host.hintFlashSeq += 1
  const seq = host.hintFlashSeq
  host.hintFlashKeys = keys
  host.hintFlashOn = true
  host.hintFlashPhase = 1
  host.requestRender()
  queueHintPhase(host, seq, 2, 140)
  queueHintPhase(host, seq, 3, 560)
  queueHintEnd(host, seq)
}

function queueHintPhase(host: GamePageHost, seq: number, phase: number, delay: number): void {
  setTimeout(() => {
    if (seq !== host.hintFlashSeq) {
      return
    }
    host.hintFlashPhase = phase
    host.requestRender()
  }, delay)
}

function queueHintEnd(host: GamePageHost, seq: number): void {
  setTimeout(() => {
    if (seq !== host.hintFlashSeq) {
      return
    }
    host.hintFlashOn = false
    host.hintFlashPhase = 0
    host.requestRender()
    refreshGamePageState(host)
  }, 820)
  setTimeout(() => {
    if (seq !== host.hintFlashSeq) {
      return
    }
    host.hintFlashKeys = []
    host.requestRender()
  }, 900)
}
