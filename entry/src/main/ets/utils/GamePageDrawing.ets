import { AppColors } from '../common/Constants'
import { GamePageHost } from './GamePageHost'
import { LinePoint } from '../model/GamePageModels'

export function drawGamePageBonusIndicator(host: GamePageHost): void {
  if (host.bonusWordsTotal <= 0) {
    return
  }
  const size = 30
  const center = size / 2
  const radius = 12
  host.bonusCanvasCtx.clearRect(0, 0, size, size)
  host.bonusCanvasCtx.beginPath()
  host.bonusCanvasCtx.arc(center, center, radius, 0, 2 * Math.PI)
  host.bonusCanvasCtx.strokeStyle = AppColors.GRAY_DARK
  host.bonusCanvasCtx.lineWidth = 3
  host.bonusCanvasCtx.stroke()
  if (host.bonusWordsFound > 0) {
    const progress = host.bonusWordsFound / host.bonusWordsTotal
    const startAngle = -Math.PI / 2
    const endAngle = startAngle + (2 * Math.PI * progress)
    host.bonusCanvasCtx.beginPath()
    host.bonusCanvasCtx.arc(center, center, radius, startAngle, endAngle)
    host.bonusCanvasCtx.strokeStyle = AppColors.SUCCESS_GREEN
    host.bonusCanvasCtx.lineWidth = 3
    host.bonusCanvasCtx.lineCap = 'round'
    host.bonusCanvasCtx.stroke()
  }
}

export function drawGamePageLines(host: GamePageHost): void {
  host.canvasContext.clearRect(0, 0, host.CANVAS_SIZE, host.CANVAS_SIZE)
  if (host.linePoints.length === 0) {
    return
  }
  host.canvasContext.lineCap = 'round'
  host.canvasContext.lineJoin = 'round'
  applyLineStyle(host)
  drawLineGlow(host)
  drawLineSegments(host)
  drawLiveSegment(host)
  drawLineDots(host)
  host.canvasContext.shadowBlur = 0
  host.canvasContext.shadowColor = 'transparent'
}

function applyLineStyle(host: GamePageHost): void {
  if (host.lineFeedback === 'wrong') {
    host.canvasContext.strokeStyle = '#FF5252'
  } else if (host.lineFeedback === 'success') {
    host.canvasContext.strokeStyle = AppColors.LINE_GREEN
  } else if (host.linePoints.length > 1) {
    const first = host.linePoints[0]
    const last = host.linePoints[host.linePoints.length - 1]
    const gradient = host.canvasContext.createLinearGradient(first.x, first.y, last.x, last.y)
    gradient.addColorStop(0, '#FFE08A')
    gradient.addColorStop(1, AppColors.PRIMARY_GOLD)
    host.canvasContext.strokeStyle = gradient
  } else {
    host.canvasContext.strokeStyle = '#FFE08A'
  }
  host.canvasContext.shadowColor = getLineShadowColor(host)
  host.canvasContext.shadowBlur = host.lineFeedback === 'normal' ? 5 : 9
}

function getLineShadowColor(host: GamePageHost): string {
  if (host.lineFeedback === 'wrong') {
    return '#FF5252'
  }
  if (host.lineFeedback === 'success') {
    return AppColors.LINE_GREEN
  }
  return AppColors.PRIMARY_GOLD
}

function drawLineGlow(host: GamePageHost): void {
  if (host.linePoints.length < 2) {
    return
  }
  const glowColor = getLineGlowColor(host)
  host.canvasContext.save()
  host.canvasContext.lineCap = 'round'
  host.canvasContext.lineJoin = 'round'
  host.canvasContext.strokeStyle = glowColor
  host.canvasContext.lineWidth = host.lineFeedback === 'normal' ? 3.5 : 5
  host.canvasContext.shadowColor = glowColor
  host.canvasContext.shadowBlur = 6
  host.canvasContext.beginPath()
  host.canvasContext.moveTo(host.linePoints[0].x, host.linePoints[0].y)
  for (let i = 1; i < host.linePoints.length; i++) {
    host.canvasContext.lineTo(host.linePoints[i].x, host.linePoints[i].y)
  }
  host.canvasContext.stroke()
  host.canvasContext.restore()
}

function getLineGlowColor(host: GamePageHost): string {
  if (host.lineFeedback === 'wrong') {
    return '#FF525226'
  }
  if (host.lineFeedback === 'success') {
    return '#76FF0326'
  }
  return '#F5A62328'
}

function drawLineSegments(host: GamePageHost): void {
  const minWidth = 1.4
  const maxWidth = 3
  const totalSegments = Math.max(1, host.linePoints.length - 1)
  for (let i = 1; i < host.linePoints.length; i++) {
    const p0 = host.linePoints[i - 1]
    const p1 = host.linePoints[i]
    const t = (i - 1) / totalSegments
    const width = getLineWidth(host, minWidth, maxWidth, t)
    host.canvasContext.lineWidth = width
    host.canvasContext.beginPath()
    host.canvasContext.moveTo(p0.x, p0.y)
    host.canvasContext.lineTo(p1.x, p1.y)
    host.canvasContext.stroke()
  }
}

function getLineWidth(host: GamePageHost, minWidth: number, maxWidth: number, t: number): number {
  const baseWidth = host.lineFeedback === 'normal' ? minWidth : 3
  return baseWidth + (maxWidth - minWidth) * Math.sin(Math.PI * t)
}

function drawLiveSegment(host: GamePageHost): void {
  if (!host.isDragging || host.lineFeedback !== 'normal' || host.linePoints.length === 0) {
    return
  }
  const last = host.linePoints[host.linePoints.length - 1]
  host.canvasContext.lineWidth = 1.6
  host.canvasContext.beginPath()
  host.canvasContext.moveTo(last.x, last.y)
  host.canvasContext.lineTo(host.currentTouchX, host.currentTouchY)
  host.canvasContext.stroke()
  drawLiveLineTip(host)
}

function drawLiveLineTip(host: GamePageHost): void {
  const pulse = 0.5 + 0.5 * Math.sin(Date.now() / 140)
  const radius = 2.4 + pulse
  host.canvasContext.save()
  host.canvasContext.shadowColor = AppColors.PRIMARY_GOLD
  host.canvasContext.shadowBlur = 5
  host.canvasContext.fillStyle = '#FFE08A'
  host.canvasContext.beginPath()
  host.canvasContext.arc(host.currentTouchX, host.currentTouchY, radius, 0, 2 * Math.PI)
  host.canvasContext.fill()
  host.canvasContext.strokeStyle = '#FFFFFF33'
  host.canvasContext.lineWidth = 1
  host.canvasContext.beginPath()
  host.canvasContext.arc(host.currentTouchX, host.currentTouchY, radius + 2, 0, 2 * Math.PI)
  host.canvasContext.stroke()
  host.canvasContext.restore()
}

function drawLineDots(host: GamePageHost): void {
  for (let i = 0; i < host.linePoints.length; i++) {
    const point: LinePoint = host.linePoints[i]
    host.canvasContext.beginPath()
    host.canvasContext.arc(point.x, point.y, getDotRadius(host), 0, 2 * Math.PI)
    host.canvasContext.fillStyle = getDotColor(host)
    host.canvasContext.fill()
  }
}

function getDotRadius(host: GamePageHost): number {
  return host.lineFeedback === 'normal' ? 2.2 : 3.2
}

function getDotColor(host: GamePageHost): string {
  if (host.lineFeedback === 'wrong') {
    return '#FF5252'
  }
  if (host.lineFeedback === 'success') {
    return AppColors.LINE_GREEN
  }
  return '#FFE08A'
}
