export interface FastestInfo {
  levelId: number
  durationMs: number
}

export class StatsStore{
  private static readonly K_TOTAL_PLAY_MS: string = 'totalPlayTimeMs'
  private static readonly K_TOTAL_WORDS: string = 'totalWordsFound'
  private static readonly K_FASTEST_LEVEL_ID: string = 'fastestLevelId'
  private static readonly K_FASTEST_LEVEL_MS: string ='fastestLevelMs'

  static init():void{
    PersistentStorage.persistProp(StatsStore.K_TOTAL_PLAY_MS, 0)
    PersistentStorage.persistProp(StatsStore.K_TOTAL_WORDS, 0)
    PersistentStorage.persistProp(StatsStore.K_FASTEST_LEVEL_ID, -1)
    PersistentStorage.persistProp(StatsStore.K_FASTEST_LEVEL_MS, -1)
  }

  static getTotalPlayTimeMs(): number {
    return AppStorage.get<number>(StatsStore.K_TOTAL_PLAY_MS) ?? 0
  }

  static addPlayTimeMs(deltaMs: number): void {
    if(deltaMs <= 0) {
      return
    }
    const curr = StatsStore.getTotalPlayTimeMs()
    AppStorage.set<number>(StatsStore.K_TOTAL_PLAY_MS, curr + deltaMs)
  }

  static getTotalWordsFound(): number {
    return AppStorage.get<number>(StatsStore.K_TOTAL_WORDS) ?? 0
  }

  static incWordsFound(by: number = 1): void {
    const curr = StatsStore.getTotalWordsFound()
    AppStorage.set<number>(StatsStore.K_TOTAL_WORDS, curr + by)
  }

  static getFastest(): FastestInfo | null {
    const id = AppStorage.get<number>(StatsStore.K_FASTEST_LEVEL_ID) ?? -1
    const ms = AppStorage.get<number>(StatsStore.K_FASTEST_LEVEL_MS) ?? -1
    if(id < 0 || ms < 0) {
      return null
    }
    return {levelId: id, durationMs: ms}
  }

  static trySetFastest(levelId: number, durationMs: number): boolean {
    const best = AppStorage.get<number>(StatsStore.K_FASTEST_LEVEL_MS) ?? -1
    if(best < 0 || durationMs < best){
      AppStorage.set<number>(StatsStore.K_FASTEST_LEVEL_ID, levelId)
      AppStorage.set<number>(StatsStore.K_FASTEST_LEVEL_MS, durationMs)
      return true
    }
    return false
  }

  static addWordsFound(count: number): void{
    if(count <= 0) {
      return
    }
    const current = AppStorage.get<number>(StatsStore.K_TOTAL_WORDS) ?? 0
    AppStorage.set<number>(StatsStore.K_TOTAL_WORDS, current + count)
  }
}