import { vibrator } from '@kit.SensorServiceKit'
import { Settings } from './Constants'
import { JSON } from '@kit.ArkTS'

export class HapticNames {
  static readonly LETTER_SELECT: string = 'letter_select'
  static readonly SHUFFLE: string = 'shuffle'
  static readonly HINT: string = 'hint'
  static readonly CORRECT_WORD: string = 'correct_word'
  static readonly WRONG_WORD: string = 'wrong_word'
  static readonly LEVEL_COMPLETE: string = 'level_complete'
}

class HapticManager {
  private lastPlayMs: number = 0

  play(name: string): void {
    const enabled: boolean = AppStorage.get(Settings.HAPTIC_ENABLED_KEY) as boolean
    if (!enabled) {
      return
    }

    const now = Date.now()
    if (name === HapticNames.LETTER_SELECT && now - this.lastPlayMs < 45) {
      return
    }
    this.lastPlayMs = now

    const duration = this.durationFor(name)
    if (duration <= 0) {
      return
    }

    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        usage: 'touch'
      }).catch((error: Error) => {
        console.warn(`[HapticManager] vibration failed: ${JSON.stringify(error)}`)
      })
    } catch (error) {
      console.warn(`[HapticManager] vibration unavailable: ${JSON.stringify(error)}`)
    }
  }

  private durationFor(name: string): number {
    if (name === HapticNames.LETTER_SELECT) {
      return 8
    }
    if (name === HapticNames.SHUFFLE) {
      return 12
    }
    if (name === HapticNames.HINT) {
      return 20
    }
    if (name === HapticNames.CORRECT_WORD) {
      return 28
    }
    if (name === HapticNames.WRONG_WORD) {
      return 42
    }
    if (name === HapticNames.LEVEL_COMPLETE) {
      return 60
    }
    return 0
  }
}

export const hapticManager = new HapticManager()
