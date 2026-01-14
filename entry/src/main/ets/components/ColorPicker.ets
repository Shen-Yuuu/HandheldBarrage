import { hsvToRgb, hexToHsv } from '../model/ColorUtils';

@Component
export struct CustomColorPicker {
  @Prop selectedColor: string;
  onChange: (color: string) => void = () => {
  };
  @State hue: number = 0; // 0-1
  @State saturation: number = 1; // 0-1
  @State value: number = 1; // 0-1
  private svRectWidth: number = 0;
  private svRectHeight: number = 0;

  aboutToAppear() {
    const hsv = hexToHsv(this.selectedColor);
    this.hue = hsv.h;
    this.saturation = hsv.s;
    this.value = hsv.v;
  }

  updateColor() {
    const newColor = hsvToRgb(this.hue, this.saturation, this.value);
    this.onChange(newColor);
  }

  handleHexInput(value: string) {
    if (/^#[0-9A-Fa-f]{6}$/.test(value) || /^#[0-9A-Fa-f]{8}$/.test(value)) {
      this.onChange(value);
      const hsv = hexToHsv(value);
      this.hue = hsv.h;
      this.saturation = hsv.s;
      this.value = hsv.v;
    }
  }

  build() {
    Column({ space: 10 }) {
      // Preview & Hex Input
      Row({ space: 15 }) {
        Rect()
          .width(40)
          .height(40)
          .fill(this.selectedColor)
          .stroke(Color.Gray)
          .strokeWidth(1)
          .radius(4)

        TextInput({ text: this.selectedColor })
          .fontSize(16)
          .fontColor(Color.Gray)
          .layoutWeight(1)
          .onChange((value) => {
            this.handleHexInput(value);
          })
      }
      .width('100%')
      .padding({ left: 10, right: 10 })

      // Saturation / Value Box
      Stack() {
        // Base Hue
        Rect()
          .width('100%')
          .height(200)
          .fill(hsvToRgb(this.hue, 1, 1))
          .radius(8)

        // White Gradient (Left to Right) - Saturation
        Rect()
          .width('100%')
          .height(200)
          .fill(Color.Transparent)
          .linearGradient({
            angle: 90,
            colors: [['#FFFFFFFF', 0.0], ['#00FFFFFF', 1.0]]
          })
          .radius(8)

        // Black Gradient (Top to Bottom) - Value
        Rect()
          .width('100%')
          .height(200)
          .fill(Color.Transparent)
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#FF000000', 1.0]]
          })
          .radius(8)

        // Cursor
        Circle()
          .width(20)
          .height(20)
          .fill(this.selectedColor)
          .stroke(Color.White)
          .strokeWidth(2)
          .position({
            x: `${this.saturation * 100}%`,
            y: `${(1 - this.value) * 100}%`
          })
          .markAnchor({ x: 10, y: 10 }) // Center the circle
          .hitTestBehavior(HitTestMode.None) // Pass touches to stack
      }
      .width('100%')
      .height(200)
      .onAreaChange((oldArea, newArea) => {
        this.svRectWidth = newArea.width as number;
        this.svRectHeight = newArea.height as number;
      })
      .gesture(
        PanGesture()
          .onActionStart((event: GestureEvent) => {
            this.handleSVPan(event);
          })
          .onActionUpdate((event: GestureEvent) => {
            this.handleSVPan(event);
          })
      )

      // Hue Slider
      Stack() {
        Rect()
          .width('100%')
          .height(20)
          .radius(10)
          .linearGradient({
            angle: 90,
            colors: [
              [0xFFFF0000, 0.0],
              [0xFFFFFF00, 0.17],
              [0xFF00FF00, 0.33],
              [0xFF00FFFF, 0.50],
              [0xFF0000FF, 0.67],
              [0xFFFF00FF, 0.83],
              [0xFFFF0000, 1.0]
            ]
          })

        Slider({
          value: this.hue * 100,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
          .trackColor(Color.Transparent)
          .selectedColor(Color.Transparent)
          .blockColor(Color.White)
          .onChange((value: number) => {
            this.hue = value / 100;
            this.updateColor();
          })
      }
      .width('100%')
      .height(30)
    }
    .width('100%')
  }

  handleSVPan(event: GestureEvent) {
    if (this.svRectWidth === 0 || this.svRectHeight === 0) {
      return;
    }

    // event.fingerList[0].localX is relative to the component
    let x = event.fingerList[0].localX;
    let y = event.fingerList[0].localY;

    // Clamp
    x = Math.max(0, Math.min(x, this.svRectWidth));
    y = Math.max(0, Math.min(y, this.svRectHeight));

    this.saturation = x / this.svRectWidth;
    this.value = 1 - (y / this.svRectHeight);

    this.updateColor();
  }
}
