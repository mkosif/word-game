import { media } from '@kit.MediaKit'
import { audio } from '@kit.AudioKit'
import { common } from '@kit.AbilityKit'
import { Settings } from './Constants'
import { JSON } from '@kit.ArkTS'

export class SoundNames {
  static readonly LETTER_SELECT: string = 'letter_select'
  static readonly SHUFFLE: string = 'shuffle'
  static readonly CORRECT_WORD: string = 'correct_word'
  static readonly WRONG_WORD: string = 'wrong_word'
  static readonly LEVEL_COMPLETE: string = 'level_complete'
}

const SOUND_FILES: string[] = [
  SoundNames.LETTER_SELECT,
  SoundNames.SHUFFLE,
  SoundNames.CORRECT_WORD,
  SoundNames.WRONG_WORD,
  SoundNames.LEVEL_COMPLETE
]

class SoundManager {
  private pool: media.SoundPool | null = null
  private ids: Map<string, number> = new Map()

  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      const audioInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_GAME,
        rendererFlags: 0
      }
      this.pool = await media.createSoundPool(5, audioInfo)
      console.info('[SoundManager] SoundPool created')
      for (let i = 0; i < SOUND_FILES.length; i++) {
        const name = SOUND_FILES[i]
        try {
          const rawFd = await context.resourceManager.getRawFd(`${name}.mp3`)
          const id = await this.pool!.load(rawFd.fd, rawFd.offset, rawFd.length)
          this.ids.set(name, id)
          console.info(`[SoundManager] Loaded ${name} -> id=${id}`)
        } catch (e) {
          console.warn(`[SoundManager] Failed to load: ${name} ` + JSON.stringify(e))
        }
      }
    } catch (e) {
      // SoundPool not available on this device — game continues without sound
      console.error(`[SoundManager] SoundPool init failed: ` + JSON.stringify(e))
    }
  }

  play(name: string): void {
    if (!this.pool) {
      console.warn(`[SoundManager] play (${name}) skipped - pool not ready`)
      return
    }
    const enabled: boolean = AppStorage.get(Settings.SOUND_ENABLED_KEY) as boolean
    if (!enabled) {
      console.info(`[SoundManager] play (${name}) skipped - sound disabled`)
      return
    }
    const id = this.ids.get(name)
    if (id === undefined) {
      console.warn(`[SoundManager] play (${name}) skipped - sound not loaded`)
      return
    }
    try {
      const params: media.PlayParameters = {
        loop: 0,
        rate: 1.0,
        leftVolume: 1.0,
        rightVolume: 1.0,
        priority: 1
      }
      this.pool.play(id, params).catch(() => {})
    } catch (e) {}
  }

  release(): void {
    if (this.pool) {
      try {
        this.pool.release()
      } catch (e) {
        console.warn('[SoundManager] release failed: ' + JSON.stringify(e))
      }
      this.pool = null
    }
    this.ids.clear()
  }
}

export const soundManager = new SoundManager()
