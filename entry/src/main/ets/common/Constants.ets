export class AppColors {
  static readonly PRIMARY_GOLD: string = '#F5A623'
  static readonly BG_EASY: string = '#0D3B1A'
  static readonly BG_MEDIUM: string = '#1A237E'
  static readonly BG_HARD: string = '#3D1A6E'
  static readonly BG_EXPERT: string = '#5C1010'
  static readonly BACKGROUND_DARK: string = '#1A237E'
  static readonly SUCCESS_GREEN: string = '#4CAF50'
  static readonly WHITE: string = '#FFFFFF'
  static readonly BLACK: string = '#000000'
  static readonly GRAY_LIGHT: string = '#E0E0E0'
  static readonly GRAY_DARK: string = '#424242'
  static readonly LETTER_BG: string = '#2C3E7B'
  static readonly SELECTED_LETTER: string = '#FF8C00'
  static readonly WORD_SLOT_EMPTY: string = '#3D5AFE'
  static readonly WORD_SLOT_FILLED: string = '#7C4DFF'
  static readonly STAR_GOLD: string = '#FFD700'
  static readonly LINE_GREEN: string = '#76FF03'
  static readonly BONUS_POPUP_BG: string = '#2D1B69'
}

export class AppSizes {
  static readonly LETTER_CIRCLE_SIZE: number = 36
  static readonly LETTER_FONT_SIZE: number = 18
  static readonly TITLE_FONT_SIZE: number = 20
  static readonly BUTTON_FONT_SIZE: number = 14
  static readonly WORD_SLOT_SIZE: number = 24
  static readonly SPACING_SMALL: number = 4
  static readonly SPACING_MEDIUM: number = 8
  static readonly SPACING_LARGE: number = 12
  static readonly BORDER_RADIUS: number = 18
  static readonly SCREEN_SIZE: number = 233
  static readonly LETTER_EDGE_RADIUS: number = 92
}

export class GameLayout {
  static readonly MIN_WORD_LENGTH: number = 2
  static readonly TOUCH_THRESHOLD: number = 28
  static readonly SUCCESS_DELAY: number = 500
  static readonly ERROR_DELAY: number = 600
  static readonly LETTER_SIZE: number = 44
  static readonly HINT_SIZE: number = 34
  static readonly BONUS_SIZE: number = 30
  static readonly SHUFFLE_SIZE: number = 34
}

export class PageNames {
  static readonly HOME: string = 'HomePage'
  static readonly GAME: string = 'GamePage'
  static readonly WIN: string = 'WinPage'
  static readonly SETTINGS: string = 'SettingsPage'
  static readonly STATISTICS: string = 'StatisticsPage'
}

export class Settings {
  static readonly SOUND_ENABLED_KEY: string = 'soundEnabled'
  static readonly HAPTIC_ENABLED_KEY: string = 'hapticEnabled'
  static readonly IS_DARK_THEME_KEY: string = 'isDarkTheme'
}

export function difficultyBgColor(difficulty: string): string {
  if (difficulty === 'easy') {
    return AppColors.BG_EASY
  }
  if (difficulty === 'medium') {
    return AppColors.BG_MEDIUM
  }
  if (difficulty === 'hard') {
    return AppColors.BG_HARD
  }
  if (difficulty === 'expert') {
    return AppColors.BG_EXPERT
  }
  return AppColors.BACKGROUND_DARK
}
