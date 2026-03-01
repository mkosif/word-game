import { AppColors, PageNames, Settings } from '../common/Constants'
import { MAX_UNLOCKED_KEY, CURRENT_LEVEL_KEY } from '../model/LevelData'
import { HomePage } from './HomePage'
import { GamePage } from './GamePage'
import { WinPage } from './WinPage'
import { SettingsPage } from './SettingsPage'
import { StatisticsPage } from './StatisticsPage'
import { StatsStore } from '../components/StatsStore'

@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    PersistentStorage.persistProp(MAX_UNLOCKED_KEY, 1)
    PersistentStorage.persistProp(CURRENT_LEVEL_KEY, 1)
    PersistentStorage.persistProp(Settings.SOUND_ENABLED_KEY, true)
    PersistentStorage.persistProp(Settings.IS_DARK_THEME_KEY, true)
    StatsStore.init()
  }

  @Builder
  PageMap(name: string) {
    if (name === PageNames.GAME) {
      GamePage()
    } else if (name === PageNames.WIN) {
      WinPage()
    } else if (name === PageNames.SETTINGS) {
      SettingsPage()
    } else if (name === PageNames.STATISTICS){
      StatisticsPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage()
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND_DARK)
  }
}