@Builder
export function PillButton(
  text: string,
  fillColor: string,
  textColor: string,
  width: number,
  height: number
) {
  Stack() {
    Rect()
      .width(width)
      .height(height)
      .fill(fillColor)
      .radius(height / 2)
    Text(text)
      .fontSize(14)
      .fontColor(textColor)
      .fontWeight(FontWeight.Bold)
  }
}