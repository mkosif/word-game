
import { AppColors } from '../common/Constants'
import { GameIconButton } from '../components/GameIconButton'
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
    if(fastest){
      this.fastestLevelId = fastest.levelId
      this.fastestMs = fastest.durationMs
    }else{
      this.fastestLevelId = 0
      this.fastestMs = 0
    }
  }

  private formatTime(ms: number): string {
    const totalSec = Math.floor(ms / 1000)
    const min = Math.floor(totalSec / 60)
    const sec = totalSec % 60
    if(min <= 0) {
      return `${sec}s`
    }
    return `${min}m ${sec}s`
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            GameIconButton({
              icon: '\u2190',
              buttonSize: 32,
              strokeColor: AppColors.WHITE,
              onTap: () => {
                this.navPathStack.pop()
              }
            })

            Text('Statistics')
              .fontSize(17)
              .fontColor(AppColors.PRIMARY_GOLD)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)

            Text('').width(36)
          }
          .width('82%')
          .margin({ top: 38, bottom: 14 })

          Row() {
            this.SummaryTile('Words', `${this.totalWords}`)
            this.SummaryTile('Play', this.formatTime(this.totalPlayMs))
          }
          .width('82%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 10 })

          Text('Records')
            .fontSize(10)
            .fontColor(AppColors.GRAY_LIGHT)
            .width('82%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 5 })

          Column() {
            this.StatRow('Fastest Level', this.fastestLevelId > 0 ? `Level ${this.fastestLevelId}` : '-')
            this.StatRow('Fastest Time', this.fastestLevelId > 0 ? this.formatTime(this.fastestMs) : '-')
          }
          .width('82%')
          .padding({ top: 6, bottom: 6 })
          .backgroundColor('#0000002E')
          .borderRadius(12)

          Text('').height(40)
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .backgroundColor(AppColors.BACKGROUND_DARK)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.None)
      .backgroundColor(AppColors.BACKGROUND_DARK)
    }
    .hideTitleBar(true)
  }

  @Builder
  private SummaryTile(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontColor(AppColors.WHITE)
        .fontWeight(FontWeight.Bold)

      Text(label)
        .fontSize(9)
        .fontColor(AppColors.GRAY_LIGHT)
        .margin({ top: 2 })
    }
    .width(84)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#0000002E')
    .borderRadius(12)
  }

  @Builder
  private StatRow(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(12)
        .fontColor(AppColors.GRAY_LIGHT)
        .layoutWeight(1)

      Text(value)
        .fontSize(13)
        .fontColor(AppColors.WHITE)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(36)
    .padding({ left: 10, right: 10 })
  }
}

