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
  private activeStreamIds: number[] = []
  private audioManager: audio.AudioManager | null = null

  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.audioManager = audio.getAudioManager()
      const audioInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_GAME,
        rendererFlags: 0
      }
      this.pool = await media.createSoundPool(5, audioInfo)
      this.pool.on('playFinishedWithStreamId', (streamId: number) => {
        this.removeActiveStreamId(streamId)
      })
      console.info('[SoundManager] SoundPool created')
      for (let i = 0; i < SOUND_FILES.length; i++) {
        const name = SOUND_FILES[i]
        try {
          const rawFd = await context.resourceManager.getRawFd(`${name}.mp3`)
          const id = await this.pool!.load(rawFd.fd, rawFd.offset, rawFd.length)
          this.ids.set(name, id)
          console.info(`[SoundManager] Loaded ${name} -> id=${id}`)
        } catch (e) {
          console.warn(`[SoundManager] Failed to load: ${name} ${JSON.stringify(e)}`)
        }
      }
    } catch (e) {
      console.error(`[SoundManager] SoundPool init failed: ${JSON.stringify(e)}`)
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
    if (this.isMutedOrSilent()) {
      console.info(`[SoundManager] play (${name}) skipped - audio output muted`)
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
      this.pool.play(id, params).then((streamId: number) => {
        this.activeStreamIds.push(streamId)
      }).catch((error: Error) => {
        console.warn(`[SoundManager] play (${name}) failed: ${JSON.stringify(error)}`)
      })
    } catch (e) {
      console.warn(`[SoundManager] play (${name}) failed: ${JSON.stringify(e)}`)
    }
  }

  release(): void {
    this.stopActiveStreams()
    if (this.pool) {
      try {
        this.pool.release()
      } catch (e) {
        console.warn(`[SoundManager] release failed: ${JSON.stringify(e)}`)
      }
      this.pool = null
    }
    this.ids.clear()
  }

  private stopActiveStreams(): void {
    if (!this.pool) {
      this.activeStreamIds = []
      return
    }
    const streamIds = this.activeStreamIds.slice()
    this.activeStreamIds = []
    for (let i = 0; i < streamIds.length; i++) {
      this.pool.stop(streamIds[i]).catch(() => {})
    }
  }

  private removeActiveStreamId(streamId: number): void {
    const index = this.activeStreamIds.indexOf(streamId)
    if (index !== -1) {
      this.activeStreamIds.splice(index, 1)
    }
  }

  private isMutedOrSilent(): boolean {
    if (!this.audioManager) {
      try {
        this.audioManager = audio.getAudioManager()
      } catch (e) {
        console.warn(`[SoundManager] audio manager unavailable: ${JSON.stringify(e)}`)
        return false
      }
    }
    try {
      const volumeManager = this.audioManager.getVolumeManager()
      if (volumeManager.isSystemMutedForStream(audio.StreamUsage.STREAM_USAGE_GAME)) {
        return true
      }
      return false
    } catch (e) {
      console.warn(`[SoundManager] mute check failed: ${JSON.stringify(e)}`)
      return false
    }
  }
}

export const soundManager = new SoundManager()
