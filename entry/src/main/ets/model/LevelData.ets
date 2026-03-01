export type Difficulty = 'easy' | 'medium' | 'hard' | 'expert'

export interface Hint {
  word: string
  revealIndexes: number[]
}

export interface Level {
  id: number
  difficulty: Difficulty
  letters: string[]
  grid: string[][]
  words: string[]
  bonusWords?: string[]
  hints: Hint[]
}

export const MAX_UNLOCKED_KEY: string = 'maxUnlockedLevel'
export const CURRENT_LEVEL_KEY: string = 'currentLevelId'

export const LEVELS: Level[] = [
  {
    id: 1,
    difficulty: 'easy',
    letters: ['A', 'E', 'T'],
    grid: [
      ['T', '',  '' ],
      ['E', 'A', 'T'],
      ['A', '',  '' ]
    ],
    words: ['EAT', 'TEA'],
    bonusWords: ['ATE', 'ETA'],
    hints: [
      { word: 'EAT', revealIndexes: [0] },
      { word: 'EAT', revealIndexes: [2] },
      { word: 'TEA', revealIndexes: [1] }
    ]
  },
  {
    id: 2,
    difficulty: 'medium',
    letters: ['O', 'P', 'T', 'S'],
    grid: [
      ['S', 'T', 'O', 'P'],
      ['',  'O', '',  'O'],
      ['',  'P', '',  'T']
    ],
    words: ['STOP', 'TOP', 'POT'],
    bonusWords: ['OPT', 'TOPS', 'SPOT', 'POTS', 'OPTS'],
    hints: [
      { word: 'STOP', revealIndexes: [0] },
      { word: 'TOP', revealIndexes: [1] },
      { word: 'POT', revealIndexes: [2] }
    ]
  },
  {
    id: 3,
    difficulty: 'medium',
    letters: ['E', 'A', 'R', 'D'],
    grid: [
      ['D', 'E', 'A', 'R'],
      ['',  'A', '',  'E'],
      ['',  'R', '',  'A'],
      ['',  '',  '',  'D']
    ],
    words: ['DEAR', 'EAR', 'READ'],
    bonusWords: ['RED', 'DARE', 'ARE', 'ERA'],
    hints: [
      { word: 'DEAR', revealIndexes: [0] },
      { word: 'READ', revealIndexes: [3] },
      { word: 'EAR', revealIndexes: [1] }
    ]
  },
  {
    id: 4,
    difficulty: 'medium',
    letters: ['L', 'I', 'M', 'E', 'S'],
    grid: [
      ['',  'S', '',  '',  '' ],
      ['',  'L', '',  'M', '' ],
      ['',  'I', '',  'I', '' ],
      ['S', 'M', 'I', 'L', 'E'],
      ['',  '',  '',  'E', '' ]
    ],
    words: ['SMILE', 'SLIM', 'MILE'],
    bonusWords: ['LIE', 'ISLE', 'LIME', 'LIES', 'SEMI', 'ELMS'],
    hints: [
      { word: 'SMILE', revealIndexes: [0] },
      { word: 'SLIM', revealIndexes: [2] },
      { word: 'MILE', revealIndexes: [1] }
    ]
  },
  {
    id: 5,
    difficulty: 'medium',
    letters: ['P', 'L', 'A', 'N', 'E'],
    grid: [
      ['P', 'L', 'A', 'N', 'E'],
      ['L', 'A', '',  '',  '' ],
      ['A', 'N', '',  '',  '' ],
      ['N', 'E', '',  '',  '' ]
    ],
    words: ['PLANE', 'PLAN', 'LANE'],
    bonusWords: ['PALE', 'PAN', 'PANE', 'LEAN', 'PLEA', 'LEAP', 'PANEL'],
    hints: [
      { word: 'PLANE', revealIndexes: [0] },
      { word: 'PLAN', revealIndexes: [2] },
      { word: 'LANE', revealIndexes: [1] }
    ]
  },
  {
    id: 6,
    difficulty: 'medium',
    letters: ['B', 'R', 'E', 'A', 'D'],
    grid: [
      ['',  '',  'B', '',  '' ],
      ['B', 'R', 'E', 'A', 'D'],
      ['A', 'E', 'D', '',  '' ],
      ['D', 'A', '',  '',  '' ],
      ['',  'D', '',  '',  '' ]
    ],
    words: ['BREAD', 'BAD', 'BED', 'READ'],
    bonusWords: ['BEAR', 'BARE', 'BEAD', 'DRAB', 'BAR', 'DARE'],
    hints: [
      { word: 'BREAD', revealIndexes: [0] },
      { word: 'READ', revealIndexes: [1] },
      { word: 'BAD', revealIndexes: [2] }
    ]
  },
  {
    id: 7,
    difficulty: 'hard',
    letters: ['O', 'R', 'A', 'N', 'G', 'E'],
    grid: [
      ['O', 'R', 'A', 'N', 'G', 'E'],
      ['',  'A', 'G', '',  'O', '' ],
      ['',  'N', 'E', '',  'N', '' ],
      ['',  'G', '',  '',  'E', '' ],
      ['',  'E', '',  '',  '',  '' ]
    ],
    words: ['ORANGE', 'RANGE', 'AGE', 'GONE'],
    bonusWords: ['NEAR', 'EARN', 'GORE', 'RAGE', 'RANG', 'ORGAN'],
    hints: [
      { word: 'ORANGE', revealIndexes: [0] },
      { word: 'RANGE', revealIndexes: [2] },
      { word: 'GONE', revealIndexes: [1] }
    ]
  },
  {
    id: 8,
    difficulty: 'hard',
    letters: ['G', 'A', 'R', 'D', 'E', 'N'],
    grid: [
      ['G', 'A', 'R', 'D', 'E', 'N'],
      ['',  '',  'E', '',  '',  'E'],
      ['',  '',  'A', '',  '',  'A'],
      ['',  '',  'D', '',  '',  'R']
    ],
    words: ['GARDEN', 'READ', 'NEAR'],
    bonusWords: ['RED', 'DARE', 'RANGE', 'ANGER', 'GRAND', 'GRADE', 'DEAN'],
    hints: [
      { word: 'GARDEN', revealIndexes: [0] },
      { word: 'NEAR', revealIndexes: [3] },
      { word: 'READ', revealIndexes: [1] }
    ]
  },
  {
    id: 9,
    difficulty: 'hard',
    letters: ['S', 'I', 'L', 'E', 'N', 'T'],
    grid: [
      ['S', 'I', 'L', 'E', 'N', 'T'],
      ['',  '',  'I', '',  'E', 'E'],
      ['',  '',  'S', '',  'T', 'N'],
      ['',  '',  'T', '',  '',  '' ]
    ],
    words: ['SILENT', 'LIST', 'NET', 'TEN'],
    bonusWords: ['SITE', 'LENS', 'SENT', 'LENT', 'TILE', 'LINE', 'NEST', 'ISLE', 'LISTEN', 'TINSEL'],
    hints: [
      { word: 'SILENT', revealIndexes: [0] },
      { word: 'LIST', revealIndexes: [2] },
      { word: 'NET', revealIndexes: [1] }
    ]
  },
  {
    id: 10,
    difficulty: 'expert',
    letters: ['C', 'A', 'P', 'T', 'A', 'I', 'N'],
    grid: [
      ['C', 'A', 'P', 'T', 'A', 'I', 'N'],
      ['A', 'C', 'A', '',  '',  '',  '' ],
      ['T', 'T', 'I', '',  '',  '',  '' ],
      ['',  '',  'N', '',  '',  '',  '' ],
      ['',  '',  'T', '',  '',  '',  '' ]
    ],
    words: ['CAPTAIN', 'CAT', 'ACT', 'PAINT'],
    bonusWords: ['PANIC', 'PACT', 'ANTI', 'PANT', 'CATNIP', 'TAN', 'PIN'],
    hints: [
      { word: 'CAPTAIN', revealIndexes: [0] },
      { word: 'PAINT', revealIndexes: [2] },
      { word: 'CAT', revealIndexes: [1] }
    ]
  }
]

export function getLevelById(id: number): Level | undefined {
  return LEVELS.find(level => level.id === id)
}

export function getTotalLevels(): number {
  return LEVELS.length
}