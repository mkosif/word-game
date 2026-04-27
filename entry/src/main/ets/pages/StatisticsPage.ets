
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
      Scroll(){
       Column() {
          Row(){
            BackButton({btnSize: 24})
              .margin({right: 5, top: 2})

           Text('Statistics')
             .fontSize(20)
             .fontWeight(FontWeight.Bold)
             .margin({left: 10})
             .margin({top: 5})
         }
         .width('100%')
          .padding(12)

         Column(){
           this.statCard('Total Play Time', this.formatTime(this.totalPlayMs))
           Divider()
             .color('#1C1C1E')
             .strokeWidth(1)
             .margin({top:8, bottom: 8})

           this.statCard('Total Words Found', `${this.totalWords}`)
           Divider()
             .color('#1C1C1E')
             .strokeWidth(1)
             .margin({top:8, bottom: 8})

           this.statCard('Fastest Completed Level', this.fastestLevelId > 0 ? `Level ${this.fastestLevelId}` : '-')
           Divider()
             .color('#1C1C1E')
             .strokeWidth(1)
             .margin({top:8, bottom: 8})

           if(this.fastestLevelId > 0){
              this.statCard('Fastest Time', this.formatTime(this.fastestMs))
           } else {
             this.statCard('Fastest Time', '-')
            }
          }
          .width('100%')
          .padding(12)
       }
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
  private statCard(title: string, value:string){
    Column(){
      Text(title)
        .fontSize(14)
        .opacity(0.7)

      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({top: 6})
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#1C1C1E')
  }
}

