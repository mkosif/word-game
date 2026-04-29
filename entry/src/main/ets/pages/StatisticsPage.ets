import { AppColors } from '../common/Constants'
import { BackButton } from '../components/BackButton'
import { StatsStore } from '../components/StatsStore'

@Component
export struct StatisticsPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @State fastestMs: number = 0
  @State totalWords: number = 0
  @State totalPlayMs: number = 0
  @State fastestLevelId: number = 0

  aboutToAppear(): void {
    this.totalPlayMs = StatsStore.getTotalPlayTimeMs()
    this.totalWords = StatsStore.getTotalWordsFound()
    const fastest = StatsStore.getFastest()
    if (fastest) {
      this.fastestLevelId = fastest.levelId
      this.fastestMs = fastest.durationMs
    } else {
      this.fastestLevelId = 0
      this.fastestMs = 0
    }
  }

  private formatTime(ms: number): string {
    const totalSec = Math.floor(ms / 1000)
    const min = Math.floor(totalSec / 60)
    const sec = totalSec % 60
    if (min <= 0) {
      return `${sec}s`
    }
    return `${min}m ${sec}s`
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            BackButton({ btnSize: 26 })
              .margin({ right: 6 })

            Text('Statistics')
              .fontSize(18)
              .fontColor(AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)

            Text('').width(26)
          }
          .width('84%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 30, bottom: 10 })

          this.StatCard('Play Time', this.formatTime(this.totalPlayMs))
          this.StatCard('Words Found', `${this.totalWords}`)
          this.StatCard('Fastest Level', this.fastestLevelId > 0 ? `Level ${this.fastestLevelId}` : '-')
          this.StatCard('Fastest Time', this.fastestLevelId > 0 ? this.formatTime(this.fastestMs) : '-')

          Text('').height(28)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(AppColors.BACKGROUND_DARK)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .backgroundColor(AppColors.BACKGROUND_DARK)
    }
    .hideTitleBar(true)
    .backgroundColor(AppColors.BACKGROUND_DARK)
  }

  @Builder
  private StatCard(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(11)
        .fontColor(AppColors.GRAY_LIGHT)
        .layoutWeight(1)

      Text(value)
        .fontSize(15)
        .fontColor(AppColors.WHITE)
        .fontWeight(FontWeight.Bold)
    }
    .width('84%')
    .height(34)
    .padding({ left: 10, right: 10 })
    .backgroundColor(AppColors.LETTER_BG)
    .borderRadius(12)
    .margin({ bottom: 6 })
  }
}
