import { BarrageConfig, BarrageSegment } from '../model/BarrageConfig';

/**
 * Canvas 字体权重转换
 */
function toCanvasFontWeight(fontWeight: FontWeight): number {
  switch (fontWeight) {
    case FontWeight.Lighter:
      return 100;
    case FontWeight.Normal:
      return 400;
    case FontWeight.Regular:
      return 400;
    case FontWeight.Medium:
      return 500;
    case FontWeight.Bold:
      return 700;
    case FontWeight.Bolder:
      return 900;
    default:
      return 400;
  }
}

/**
 * 渐变文字组件
 */
@Component
struct GradientText {
  @Prop @Watch('onPropsChange') text: string = '';
  @Prop @Watch('onPropsChange') fontSize: number = 48;
  @Prop @Watch('onPropsChange') fontWeight: FontWeight = FontWeight.Normal;
  @Prop @Watch('onPropsChange') fontStyle: FontStyle = FontStyle.Normal;
  @Prop @Watch('onPropsChange') fontFamily: string = 'HarmonyOS Sans';
  @Prop @Watch('onPropsChange') letterSpacing: number = 0;
  @Prop @Watch('onPropsChange') lineHeight: number = 0;
  @Prop decorationType: TextDecorationType = TextDecorationType.None;
  @Prop decorationColor: ResourceColor = Color.White;
  @Prop @Watch('onPropsChange') gradientColors: Array<[string, number]> =
    [['#FF0000', 0], ['#0000FF', 1]];
  @Prop @Watch('onPropsChange') gradientDirection: number = 90;
  @Prop textOpacity: number = 1;
  @Prop @Watch('onPropsChange') hasShadow: boolean = false;
  @Prop @Watch('onPropsChange') isVertical: boolean = false;
  @Prop @Watch('onPropsChange') strokeEnabled: boolean = false;
  @Prop @Watch('onPropsChange') strokeColor: string = '#000000';
  @Prop @Watch('onPropsChange') strokeWidth: number = 2;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private isCanvasReady: boolean = false;
  @State measuredWidth: number = 0;
  @State measuredHeight: number = 0;

  onPropsChange(): void {
    this.requestDraw();
  }

  private requestDraw(): void {
    if (this.isCanvasReady && this.measuredWidth > 0 && this.measuredHeight > 0) {
      setTimeout(() => this.draw(), 0);
    }
  }

  private getLineHeight(): number {
    return this.lineHeight > 0 ? this.lineHeight : this.fontSize * 1.25;
  }

  private getFontSizeInPx(): number {
    return vp2px(this.fontSize);
  }

  /**
   * 构建 Canvas 字体字符串
   * familyName 直接使用 config 传入的值，与注册时的名称一致
   */
  private buildCanvasFont(): string {
    const style = this.fontStyle === FontStyle.Italic ? 'italic' : 'normal';
    const numericWeight = toCanvasFontWeight(this.fontWeight);
    let weight: string;
    if (numericWeight >= 700) {
      weight = 'bold';
    } else if (numericWeight >= 500) {
      weight = '500';
    } else {
      weight = 'normal';
    }
    const fontSizePx = this.getFontSizeInPx();
    return `${style} ${weight} ${fontSizePx}px "${this.fontFamily}"`;
  }

  build() {
    Stack() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(Color.Transparent)
        .fontWeight(this.fontWeight)
        .fontStyle(this.fontStyle)
        .fontFamily(this.fontFamily)
        .letterSpacing(this.letterSpacing)
        .lineHeight(this.getLineHeight())
        .maxLines(this.isVertical ? undefined : 1)
        .constraintSize({ maxWidth: 99999 })
        .textOverflow({ overflow: TextOverflow.Clip })
        .opacity(0)
        .onAreaChange((_oldArea: Area, newArea: Area) => {
          const w = newArea.width as number;
          const h = newArea.height as number;
          if (w > 0 && h > 0) {
            const changed = Math.abs(w - this.measuredWidth) > 0.5 ||
              Math.abs(h - this.measuredHeight) > 0.5;
            if (changed) {
              this.measuredWidth = w;
              this.measuredHeight = h;
              this.requestDraw();
            }
          }
        })

      Canvas(this.context)
        .width(this.measuredWidth > 0 ? this.measuredWidth : 1)
        .height(this.measuredHeight > 0 ? this.measuredHeight : 1)
        .onReady(() => {
          this.isCanvasReady = true;
          if (this.measuredWidth > 0 && this.measuredHeight > 0) {
            this.draw();
          }
        })
    }
    .opacity(this.textOpacity)
    .alignContent(Alignment.TopStart)
  }

  private draw(): void {
    if (!this.isCanvasReady || this.measuredWidth <= 0 || this.measuredHeight <= 0) {
      return;
    }

    const ctx = this.context;
    const w = this.measuredWidth;
    const h = this.measuredHeight;

    ctx.clearRect(0, 0, w * 2, h * 2);
    ctx.font = this.buildCanvasFont();
    ctx.textBaseline = 'middle';

    if (this.isVertical) {
      this.drawVerticalText(ctx, w, h);
    } else {
      this.drawHorizontalText(ctx, w, h);
    }
  }

  private drawHorizontalText(ctx: CanvasRenderingContext2D, w: number, h: number): void {
    const text = this.text || '';
    if (text.length === 0) return;

    const centerX = w / 2;
    const centerY = h / 2;

    const angle = this.gradientDirection * (Math.PI / 180);
    const diagonal = Math.sqrt(w * w + h * h) / 2;
    const dx = Math.cos(angle) * diagonal;
    const dy = Math.sin(angle) * diagonal;
    const gradient = ctx.createLinearGradient(
      centerX - dx, centerY - dy,
      centerX + dx, centerY + dy
    );

    for (let i = 0; i < this.gradientColors.length; i++) {
      const cs = this.gradientColors[i];
      gradient.addColorStop(Math.max(0, Math.min(1, cs[1])), cs[0]);
    }

    if (this.strokeEnabled && this.strokeWidth > 0) {
      ctx.save();
      ctx.strokeStyle = this.strokeColor;
      ctx.lineWidth = this.strokeWidth * 2;
      ctx.lineJoin = 'round';
      ctx.miterLimit = 2;
      if (this.letterSpacing > 0) {
        this.drawCharsWithSpacing(ctx, text, centerX, centerY, true);
      } else {
        ctx.textAlign = 'center';
        ctx.strokeText(text, centerX, centerY);
      }
      ctx.restore();
      ctx.font = this.buildCanvasFont();
      ctx.textBaseline = 'middle';
    }

    this.applyShadow(ctx);
    ctx.fillStyle = gradient;
    if (this.letterSpacing > 0) {
      this.drawCharsWithSpacing(ctx, text, centerX, centerY, false);
    } else {
      ctx.textAlign = 'center';
      ctx.fillText(text, centerX, centerY);
    }
    this.resetShadow(ctx);
  }

  private drawVerticalText(ctx: CanvasRenderingContext2D, w: number, h: number): void {
    const text = this.text || '';
    if (text.length === 0) return;

    const chars = text.split('');
    const lineH = this.getLineHeight();
    const totalH = chars.length * lineH;
    const centerX = w / 2;
    const startY = (h - totalH) / 2 + lineH / 2;

    const gradient = ctx.createLinearGradient(0, startY - lineH / 2, 0, startY + totalH);
    for (let i = 0; i < this.gradientColors.length; i++) {
      const cs = this.gradientColors[i];
      gradient.addColorStop(Math.max(0, Math.min(1, cs[1])), cs[0]);
    }

    this.applyShadow(ctx);
    ctx.fillStyle = gradient;
    ctx.textAlign = 'center';
    let y = startY;
    for (let i = 0; i < chars.length; i++) {
      ctx.fillText(chars[i], centerX, y);
      y += lineH;
    }
    this.resetShadow(ctx);
  }

  private drawCharsWithSpacing(ctx: CanvasRenderingContext2D, text: string,
    centerX: number, centerY: number, isStroke: boolean): void {
    const chars = text.split('');
    const charWidths: number[] = [];
    let totalWidth = 0;
    for (let i = 0; i < chars.length; i++) {
      const cw = ctx.measureText(chars[i]).width;
      charWidths.push(cw);
      totalWidth += cw;
      if (i < chars.length - 1) totalWidth += this.letterSpacing;
    }
    let x = centerX - totalWidth / 2;
    ctx.textAlign = 'left';
    for (let i = 0; i < chars.length; i++) {
      if (isStroke) {
        ctx.strokeText(chars[i], x, centerY);
      } else {
        ctx.fillText(chars[i], x, centerY);
      }
      x += charWidths[i] + (i < chars.length - 1 ? this.letterSpacing : 0);
    }
  }

  private applyShadow(ctx: CanvasRenderingContext2D): void {
    if (this.hasShadow) {
      const s = Math.max(2, this.fontSize * 0.06);
      ctx.shadowColor = 'rgba(0, 0, 0, 0.6)';
      ctx.shadowBlur = s * 1.5;
      ctx.shadowOffsetX = s;
      ctx.shadowOffsetY = s;
    }
  }

  private resetShadow(ctx: CanvasRenderingContext2D): void {
    ctx.shadowColor = 'transparent';
    ctx.shadowBlur = 0;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 0;
  }
}
/**
 * 普通文字组件
 */
@Component
struct NormalText {
  @Prop text: string = '';
  @Prop fontSize: number = 48;
  @Prop fontColor: ResourceColor = Color.White;
  @Prop fontWeight: FontWeight = FontWeight.Normal;
  @Prop fontStyle: FontStyle = FontStyle.Normal;
  @Prop fontFamily: string = 'HarmonyOS Sans';
  @Prop letterSpacing: number = 0;
  @Prop lineHeight: number = 0;
  @Prop decorationType: TextDecorationType = TextDecorationType.None;
  @Prop decorationColor: ResourceColor = Color.White;
  @Prop textOpacity: number = 1;
  @Prop hasShadow: boolean = false;
  @Prop isVertical: boolean = false;
  @Prop strokeEnabled: boolean = false;
  @Prop strokeColor: string = '#000000';
  @Prop strokeWidth: number = 2;

  private getLineHeight(): number {
    return this.lineHeight > 0 ? this.lineHeight : this.fontSize * 1.25;
  }

  private buildShadow(): ShadowOptions | undefined {
    if (!this.hasShadow) {
      return undefined;
    }
    return {
      radius: Math.max(4, this.fontSize * 0.08),
      color: 'rgba(0, 0, 0, 0.6)',
      offsetX: Math.max(2, this.fontSize * 0.04),
      offsetY: Math.max(2, this.fontSize * 0.04)
    };
  }

  build() {
    Stack() {
      if (this.strokeEnabled && this.strokeWidth > 0) {
        Text(this.text)
          .fontSize(this.fontSize)
          .fontColor(this.strokeColor)
          .fontWeight(this.fontWeight)
          .fontStyle(this.fontStyle)
          .fontFamily(this.fontFamily)
          .letterSpacing(this.letterSpacing)
          .lineHeight(this.getLineHeight())
          .maxLines(this.isVertical ? undefined : 1)
          .constraintSize({ maxWidth: 99999 })
          .textOverflow({ overflow: TextOverflow.Clip })
          .textShadow([
            { radius: 0, color: this.strokeColor, offsetX: this.strokeWidth, offsetY: 0 },
            { radius: 0, color: this.strokeColor, offsetX: -this.strokeWidth, offsetY: 0 },
            { radius: 0, color: this.strokeColor, offsetX: 0, offsetY: this.strokeWidth },
            { radius: 0, color: this.strokeColor, offsetX: 0, offsetY: -this.strokeWidth },
            {
              radius: 0,
              color: this.strokeColor,
              offsetX: this.strokeWidth * 0.7,
              offsetY: this.strokeWidth * 0.7
            },
            {
              radius: 0,
              color: this.strokeColor,
              offsetX: -this.strokeWidth * 0.7,
              offsetY: this.strokeWidth * 0.7
            },
            {
              radius: 0,
              color: this.strokeColor,
              offsetX: this.strokeWidth * 0.7,
              offsetY: -this.strokeWidth * 0.7
            },
            {
              radius: 0,
              color: this.strokeColor,
              offsetX: -this.strokeWidth * 0.7,
              offsetY: -this.strokeWidth * 0.7
            }
          ])

        Text(this.text)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .fontWeight(this.fontWeight)
          .fontStyle(this.fontStyle)
          .fontFamily(this.fontFamily)
          .letterSpacing(this.letterSpacing)
          .lineHeight(this.getLineHeight())
          .decoration({ type: this.decorationType, color: this.decorationColor })
          .maxLines(this.isVertical ? undefined : 1)
          .constraintSize({ maxWidth: 99999 })
          .textOverflow({ overflow: TextOverflow.Clip })
          .textShadow(this.buildShadow())
      } else {
        Text(this.text)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .fontWeight(this.fontWeight)
          .fontStyle(this.fontStyle)
          .fontFamily(this.fontFamily)
          .letterSpacing(this.letterSpacing)
          .lineHeight(this.getLineHeight())
          .decoration({ type: this.decorationType, color: this.decorationColor })
          .maxLines(this.isVertical ? undefined : 1)
          .constraintSize({ maxWidth: 99999 })
          .textOverflow({ overflow: TextOverflow.Clip })
          .textShadow(this.buildShadow())
      }
    }
    .opacity(this.textOpacity)
  }
}

/**
 * 弹幕片段项组件
 */
@Component
struct BarrageSegmentItem {
  @ObjectLink segment: BarrageSegment;
  @Prop layoutDirection: string = 'horizontal';
  @Prop letterSpacing: number = 0;
  @Prop lineSpacing: number = 0;
  @Prop blinkOpacity: number = 1;
  @Prop gradientEnabled: boolean = false;
  @Prop gradientColors: Array<[string, number]> = [];
  @Prop gradientDirection: number = 90;
  @Prop strokeEnabled: boolean = false;
  @Prop strokeColor: string = '#000000';
  @Prop strokeWidth: number = 2;

  build() {
    if (this.layoutDirection === 'horizontal') {
      this.buildHorizontalContent()
    } else {
      this.buildVerticalContent()
    }
  }

  @Builder
  buildHorizontalContent() {
    if (this.gradientEnabled && this.gradientColors.length >= 2) {
      GradientText({
        text: this.segment.text,
        fontSize: this.segment.fontSize,
        fontWeight: this.segment.fontWeight,
        fontStyle: this.segment.fontStyle,
        fontFamily: this.segment.fontFamily,
        letterSpacing: this.letterSpacing,
        decorationType: this.segment.decorationType,
        decorationColor: this.segment.fontColor,
        gradientColors: this.gradientColors,
        gradientDirection: this.gradientDirection,
        textOpacity: this.blinkOpacity,
        hasShadow: this.segment.hasShadow,
        isVertical: false,
        strokeEnabled: this.strokeEnabled,
        strokeColor: this.strokeColor,
        strokeWidth: this.strokeWidth
      })
    } else {
      NormalText({
        text: this.segment.text,
        fontSize: this.segment.fontSize,
        fontColor: this.segment.fontColor,
        fontWeight: this.segment.fontWeight,
        fontStyle: this.segment.fontStyle,
        fontFamily: this.segment.fontFamily,
        letterSpacing: this.letterSpacing,
        decorationType: this.segment.decorationType,
        decorationColor: this.segment.fontColor,
        textOpacity: this.blinkOpacity,
        hasShadow: this.segment.hasShadow,
        isVertical: false,
        strokeEnabled: this.strokeEnabled,
        strokeColor: this.strokeColor,
        strokeWidth: this.strokeWidth
      })
    }
  }

  @Builder
  buildVerticalContent() {
    Column() {
      ForEach(this.getSegmentText().split(''), (char: string, index: number) => {
        if (this.gradientEnabled && this.gradientColors.length >= 2) {
          GradientText({
            text: char,
            fontSize: this.segment.fontSize,
            fontWeight: this.segment.fontWeight,
            fontStyle: this.segment.fontStyle,
            fontFamily: this.segment.fontFamily,
            letterSpacing: this.letterSpacing,
            lineHeight: this.segment.fontSize + this.lineSpacing,
            decorationType: this.segment.decorationType,
            decorationColor: this.segment.fontColor,
            gradientColors: this.gradientColors,
            gradientDirection: this.gradientDirection,
            textOpacity: this.blinkOpacity,
            hasShadow: this.segment.hasShadow,
            isVertical: true,
            strokeEnabled: this.strokeEnabled,
            strokeColor: this.strokeColor,
            strokeWidth: this.strokeWidth
          })
        } else {
          NormalText({
            text: char,
            fontSize: this.segment.fontSize,
            fontColor: this.segment.fontColor,
            fontWeight: this.segment.fontWeight,
            fontStyle: this.segment.fontStyle,
            fontFamily: this.segment.fontFamily,
            letterSpacing: this.letterSpacing,
            lineHeight: this.segment.fontSize + this.lineSpacing,
            decorationType: this.segment.decorationType,
            decorationColor: this.segment.fontColor,
            textOpacity: this.blinkOpacity,
            hasShadow: this.segment.hasShadow,
            isVertical: true,
            strokeEnabled: this.strokeEnabled,
            strokeColor: this.strokeColor,
            strokeWidth: this.strokeWidth
          })
        }
      }, (char: string, index: number) => index.toString() + '_' + char)
    }
  }

  getSegmentText(): string {
    if (this.segment && this.segment.text) {
      return this.segment.text;
    }
    return '';
  }
}

/**
 * LED 覆盖层组件
 */
@Component
struct LEDOverlay {
  @Prop @Watch('onPropsChange') density: number = 4;
  @Prop @Watch('onPropsChange') shape: string = 'grid';
  @Prop @Watch('onPropsChange') spacing: number = 2;
  @Prop @Watch('onPropsChange') containerWidth: number = 0;
  @Prop @Watch('onPropsChange') containerHeight: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State isReady: boolean = false;

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.isReady = true;
        this.drawLEDGrid();
      })
      .hitTestBehavior(HitTestMode.Transparent)
  }

  onPropsChange() {
    if (this.isReady) {
      this.drawLEDGrid();
    }
  }

  drawLEDGrid() {
    const ctx = this.context;
    const width = this.containerWidth;
    const height = this.containerHeight;

    if (width <= 0 || height <= 0) {
      return;
    }

    const size = Math.max(2, Math.min(16, this.density * 1.5));
    const gap = Math.max(1, Math.min(8, this.spacing * 0.8));
    const step = size + gap;

    ctx.clearRect(0, 0, width, height);
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = 'rgba(0, 0, 0, 0.85)';
    ctx.fillRect(0, 0, width, height);

    if (this.shape === 'circle') {
      this.drawCircleLED(ctx, width, height, size, gap, step);
    } else if (this.shape === 'square') {
      this.drawSquareLED(ctx, width, height, size, gap, step);
    } else {
      this.drawGridLED(ctx, width, height, size, gap, step);
    }

    ctx.globalCompositeOperation = 'source-over';
  }

  drawCircleLED(ctx: CanvasRenderingContext2D, width: number, height: number,
    size: number, gap: number, step: number) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = 'rgba(255, 255, 255, 1)';
    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        ctx.beginPath();
        ctx.arc(x + size / 2, y + size / 2, size / 2 * 0.9, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
    ctx.strokeStyle = 'rgba(40, 40, 40, 0.6)';
    ctx.lineWidth = 0.5;
    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        ctx.beginPath();
        ctx.arc(x + size / 2, y + size / 2, size / 2 * 0.9, 0, Math.PI * 2);
        ctx.stroke();
      }
    }
  }

  drawSquareLED(ctx: CanvasRenderingContext2D, width: number, height: number,
    size: number, gap: number, step: number) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = 'rgba(255, 255, 255, 1)';
    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        ctx.fillRect(x, y, size, size);
      }
    }
    ctx.globalCompositeOperation = 'source-over';
    ctx.strokeStyle = 'rgba(40, 40, 40, 0.5)';
    ctx.lineWidth = 0.5;
    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        ctx.strokeRect(x, y, size, size);
      }
    }
  }

  drawGridLED(ctx: CanvasRenderingContext2D, width: number, height: number,
    size: number, gap: number, step: number) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.95)';
    for (let y = size; y < height; y += step) {
      ctx.fillRect(0, y, width, gap);
    }
    for (let x = size; x < width; x += step) {
      ctx.fillRect(x, 0, gap, height);
    }
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = 'rgba(255, 255, 255, 0.95)';
    for (let y = 0; y < height; y += step) {
      for (let x = 0; x < width; x += step) {
        ctx.beginPath();
        ctx.arc(x + size / 2, y + size / 2, size * 0.35, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}

/**
 * 粒子类
 */
class Particle {
  x: number = 0;
  y: number = 0;
  vx: number = 0;
  vy: number = 0;
  size: number = 2;
  alpha: number = 1;
  color: string = '#FFFFFF';
  life: number = 0;
  maxLife: number = 100;
  particleType: string = 'sparkle';
  rotation: number = 0;
  rotationSpeed: number = 0;
  scale: number = 1;

  constructor() {
  }

  init(w: number, h: number, type: string, isInitial: boolean): void {
    this.particleType = type;
    this.reset(w, h, isInitial);
  }

  reset(w: number, h: number, isInitial: boolean): void {
    this.life = 0;
    this.maxLife = Math.random() * 120 + 60;
    this.rotation = Math.random() * Math.PI * 2;
    this.rotationSpeed = (Math.random() - 0.5) * 0.1;
    this.scale = 1;

    if (this.particleType === 'sparkle') {
      this.x = Math.random() * w;
      this.y = isInitial ? Math.random() * h : -10;
      this.vx = (Math.random() - 0.5) * 2;
      this.vy = Math.random() * 2 + 1;
      this.size = Math.random() * 4 + 2;
      this.alpha = Math.random() * 0.8 + 0.2;
      const colors: string[] = ['#FFD700', '#FFF8DC', '#FFFACD', '#FFFFFF', '#87CEEB', '#FF69B4'];
      this.color = colors[Math.floor(Math.random() * colors.length)];
    } else if (this.particleType === 'bubble') {
      this.x = Math.random() * w;
      this.y = isInitial ? Math.random() * h : h + 10;
      this.vx = (Math.random() - 0.5) * 0.8;
      this.vy = -(Math.random() * 1.5 + 0.8);
      this.size = Math.random() * 10 + 5;
      this.alpha = Math.random() * 0.4 + 0.2;
      const colors: string[] = ['#87CEEB', '#98FB98', '#DDA0DD', '#F0E68C', '#E0FFFF', '#B0E0E6'];
      this.color = colors[Math.floor(Math.random() * colors.length)];
    } else if (this.particleType === 'fire') {
      this.x = w / 2 + (Math.random() - 0.5) * w * 0.6;
      this.y = isInitial ? h - Math.random() * h * 0.3 : h + 5;
      this.vx = (Math.random() - 0.5) * 1.5;
      this.vy = -(Math.random() * 3 + 2);
      this.size = Math.random() * 8 + 4;
      this.alpha = Math.random() * 0.6 + 0.4;
      const colors: string[] = ['#FF4500', '#FF6347', '#FFA500', '#FFD700', '#FF8C00', '#FF0000'];
      this.color = colors[Math.floor(Math.random() * colors.length)];
      this.maxLife = Math.random() * 60 + 30;
    } else if (this.particleType === 'snow') {
      this.x = Math.random() * w;
      this.y = isInitial ? Math.random() * h : -10;
      this.vx = (Math.random() - 0.5) * 1;
      this.vy = Math.random() * 1 + 0.5;
      this.size = Math.random() * 4 + 2;
      this.alpha = Math.random() * 0.6 + 0.4;
      this.color = '#FFFFFF';
      this.rotationSpeed = (Math.random() - 0.5) * 0.05;
    } else if (this.particleType === 'star') {
      this.x = Math.random() * w;
      this.y = Math.random() * h;
      this.vx = 0;
      this.vy = 0;
      this.size = Math.random() * 3 + 1;
      this.alpha = Math.random() * 0.8 + 0.2;
      const colors: string[] = ['#FFFFFF', '#FFD700', '#87CEEB', '#FF69B4', '#00FF7F'];
      this.color = colors[Math.floor(Math.random() * colors.length)];
      this.maxLife = Math.random() * 200 + 100;
    }
  }

  update(w: number, h: number): boolean {
    this.x += this.vx;
    this.y += this.vy;
    this.life++;
    this.rotation += this.rotationSpeed;

    if (this.particleType === 'sparkle') {
      this.alpha = Math.sin(this.life * 0.15) * 0.4 + 0.6;
      this.scale = 1 + Math.sin(this.life * 0.1) * 0.2;
    } else if (this.particleType === 'bubble') {
      this.vx += (Math.random() - 0.5) * 0.1;
      this.vx = Math.max(-1, Math.min(1, this.vx));
      this.alpha = Math.max(0.1, this.alpha - 0.002);
    } else if (this.particleType === 'fire') {
      const fireProgress = this.life / this.maxLife;
      this.alpha = 1 - fireProgress;
      this.scale = 1 - fireProgress * 0.6;
      this.vx += (Math.random() - 0.5) * 0.3;
    } else if (this.particleType === 'snow') {
      this.vx = Math.sin(this.life * 0.05) * 0.5;
    } else if (this.particleType === 'star') {
      this.alpha = Math.sin(this.life * 0.08 + Math.random()) * 0.5 + 0.5;
      this.scale = 1 + Math.sin(this.life * 0.1) * 0.3;
    }

    const outOfBounds = this.x < -20 || this.x > w + 20 || this.y < -20 || this.y > h + 20;
    const expired = this.life > this.maxLife;

    if ((outOfBounds || expired) && this.particleType !== 'star') {
      this.reset(w, h, false);
    } else if (this.particleType === 'star' && expired) {
      this.life = 0;
      this.alpha = Math.random() * 0.8 + 0.2;
    }

    return true;
  }
}

/**
 * 粒子覆盖层组件
 */
@Component
struct ParticleOverlay {
  @Prop containerWidth: number = 0;
  @Prop containerHeight: number = 0;
  @Prop particleType: string = 'sparkle';
  @Prop particleCount: number = 50;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private particles: Particle[] = [];
  private animationTimer: number = -1;
  private isInitialized: boolean = false;

  aboutToDisappear(): void {
    this.stopAnimation();
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onReady(() => {
        this.initParticles();
        this.startAnimation();
      })
  }

  initParticles(): void {
    if (this.containerWidth <= 0 || this.containerHeight <= 0) {
      return;
    }
    this.particles = [];
    let count = Math.min(this.particleCount, 120);
    if (this.particleType === 'fire') {
      count = Math.floor(Math.min(count * 1.5, 150));
    } else if (this.particleType === 'star') {
      count = Math.floor(Math.min(count * 0.6, 60));
    }
    for (let i = 0; i < count; i++) {
      const p = new Particle();
      p.init(this.containerWidth, this.containerHeight, this.particleType, true);
      this.particles.push(p);
    }
    this.isInitialized = true;
  }

  startAnimation(): void {
    this.stopAnimation();
    const fps = this.particleType === 'fire' ? 40 : 30;
    this.animationTimer = setInterval(() => {
      this.draw();
    }, 1000 / fps);
  }

  stopAnimation(): void {
    if (this.animationTimer !== -1) {
      clearInterval(this.animationTimer);
      this.animationTimer = -1;
    }
  }

  draw(): void {
    if (!this.isInitialized) {
      return;
    }
    const ctx = this.context;
    const w = this.containerWidth;
    const h = this.containerHeight;
    if (w <= 0 || h <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);
    for (let i = 0; i < this.particles.length; i++) {
      const p = this.particles[i];
      p.update(w, h);
      ctx.save();
      ctx.globalAlpha = p.alpha;
      if (this.particleType === 'sparkle') {
        this.drawSparkle(ctx, p);
      } else if (this.particleType === 'bubble') {
        this.drawBubble(ctx, p);
      } else if (this.particleType === 'fire') {
        this.drawFire(ctx, p);
      } else if (this.particleType === 'snow') {
        this.drawSnow(ctx, p);
      } else if (this.particleType === 'star') {
        this.drawStar(ctx, p);
      }
      ctx.restore();
    }
  }

  drawSparkle(ctx: CanvasRenderingContext2D, p: Particle): void {
    ctx.fillStyle = p.color;
    const size = p.size * p.scale;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rotation);
    ctx.beginPath();
    for (let i = 0; i < 4; i++) {
      const angle = (i * Math.PI) / 2;
      const outerX = Math.cos(angle) * size;
      const outerY = Math.sin(angle) * size;
      const innerAngle = angle + Math.PI / 4;
      const innerX = Math.cos(innerAngle) * size * 0.3;
      const innerY = Math.sin(innerAngle) * size * 0.3;
      if (i === 0) {
        ctx.moveTo(outerX, outerY);
      } else {
        ctx.lineTo(outerX, outerY);
      }
      ctx.lineTo(innerX, innerY);
    }
    ctx.closePath();
    ctx.fill();
    ctx.shadowColor = p.color;
    ctx.shadowBlur = size * 2;
    ctx.fill();
    ctx.restore();
  }

  drawBubble(ctx: CanvasRenderingContext2D, p: Particle): void {
    const size = p.size * p.scale;
    const gradient = ctx.createRadialGradient(p.x - size * 0.3, p.y - size * 0.3, 0, p.x, p.y, size);
    gradient.addColorStop(0, 'rgba(255, 255, 255, 0.8)');
    gradient.addColorStop(0.3, p.color);
    gradient.addColorStop(1, 'rgba(255, 255, 255, 0.1)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(p.x, p.y, size, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
    ctx.beginPath();
    ctx.arc(p.x - size * 0.35, p.y - size * 0.35, size * 0.15, 0, Math.PI * 2);
    ctx.fill();
  }

  drawFire(ctx: CanvasRenderingContext2D, p: Particle): void {
    const size = p.size * p.scale;
    const gradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, size);
    gradient.addColorStop(0, '#FFFF00');
    gradient.addColorStop(0.3, p.color);
    gradient.addColorStop(1, 'rgba(255, 0, 0, 0)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(p.x, p.y, size, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowColor = '#FF4500';
    ctx.shadowBlur = size;
  }

  drawSnow(ctx: CanvasRenderingContext2D, p: Particle): void {
    const size = p.size * p.scale;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rotation);
    ctx.strokeStyle = p.color;
    ctx.lineWidth = 1;
    ctx.lineCap = 'round';
    for (let i = 0; i < 6; i++) {
      const angle = (i * Math.PI) / 3;
      ctx.save();
      ctx.rotate(angle);
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(0, -size);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, -size * 0.5);
      ctx.lineTo(size * 0.3, -size * 0.7);
      ctx.moveTo(0, -size * 0.5);
      ctx.lineTo(-size * 0.3, -size * 0.7);
      ctx.stroke();
      ctx.restore();
    }
    ctx.restore();
  }

  drawStar(ctx: CanvasRenderingContext2D, p: Particle): void {
    const size = p.size * p.scale;
    ctx.fillStyle = p.color;
    ctx.shadowColor = p.color;
    ctx.shadowBlur = size * 3;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rotation);
    ctx.beginPath();
    for (let i = 0; i < 5; i++) {
      const outerAngle = (i * 4 * Math.PI) / 5 - Math.PI / 2;
      const innerAngle = outerAngle + (2 * Math.PI) / 5;
      const outerX = Math.cos(outerAngle) * size;
      const outerY = Math.sin(outerAngle) * size;
      const innerX = Math.cos(innerAngle) * size * 0.4;
      const innerY = Math.sin(innerAngle) * size * 0.4;
      if (i === 0) {
        ctx.moveTo(outerX, outerY);
      } else {
        ctx.lineTo(outerX, outerY);
      }
      ctx.lineTo(innerX, innerY);
    }
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }
}

/**
 * 弹幕预览主组件
 */
@Component
export struct BarragePreview {
  @ObjectLink config: BarrageConfig;

  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State blinkOpacity: number = 1;
  @State animScale: number = 1;
  @State animRotate: number = 0;
  @State animTranslateY: number = 0;

  @State contentWidth: number = 0;
  @State contentHeight: number = 0;
  @State containerWidth: number = 0;
  @State containerHeight: number = 0;

  private animTick: number = 0;
  private scrollTimer: number = -1;
  private blinkTimer: number = -1;
  private isAppeared: boolean = false;
  private lastIsBlinking: boolean = false;
  private lastBlinkSpeed: number = 50;
  private lastContentSignature: string = '';
  private positionInitialized: boolean = false;

  aboutToAppear(): void {
    this.isAppeared = true;
    this.lastIsBlinking = this.config.isBlinking;
    this.lastBlinkSpeed = this.config.blinkSpeed;
    this.lastContentSignature = this.buildContentSignature();
    this.startScrollAnimation();
    this.startBlinkAnimation();
  }

  aboutToDisappear(): void {
    this.isAppeared = false;
    this.stopAllAnimations();
  }

  stopAllAnimations(): void {
    if (this.scrollTimer !== -1) {
      clearInterval(this.scrollTimer);
      this.scrollTimer = -1;
    }
    if (this.blinkTimer !== -1) {
      clearInterval(this.blinkTimer);
      this.blinkTimer = -1;
    }
  }

  startScrollAnimation(): void {
    if (this.scrollTimer !== -1) {
      clearInterval(this.scrollTimer);
    }

    this.scrollTimer = setInterval(() => {
      if (!this.isAppeared) {
        return;
      }

      const currentSignature = this.buildContentSignature();
      if (currentSignature !== this.lastContentSignature) {
        this.lastContentSignature = currentSignature;
        this.positionInitialized = false;
        this.initializePosition();
      }

      if (this.lastIsBlinking !== this.config.isBlinking ||
        this.lastBlinkSpeed !== this.config.blinkSpeed) {
        this.lastIsBlinking = this.config.isBlinking;
        this.lastBlinkSpeed = this.config.blinkSpeed;
        this.startBlinkAnimation();
      }

      if (this.containerWidth <= 0 || this.containerHeight <= 0) {
        return;
      }

      const speed = Math.max(1, this.config.scrollSpeed / 5);
      const direction = this.config.scrollReverse ? -1 : 1;

      if (this.config.direction === 'horizontal') {
        this.offsetX -= speed * direction;

        if (this.contentHeight > 0 && this.containerHeight > 0) {
          this.offsetY = (this.containerHeight - this.contentHeight) / 2;
        }

        if (this.contentWidth > 0) {
          if (!this.config.scrollReverse) {
            if (this.offsetX + this.contentWidth < 0) {
              this.offsetX = this.containerWidth;
            }
          } else {
            if (this.offsetX > this.containerWidth) {
              this.offsetX = -this.contentWidth;
            }
          }
        }
      } else {
        this.offsetY -= speed * direction;

        if (this.contentWidth > 0 && this.containerWidth > 0) {
          this.offsetX = (this.containerWidth - this.contentWidth) / 2;
        }

        if (this.contentHeight > 0) {
          if (!this.config.scrollReverse) {
            if (this.offsetY + this.contentHeight < 0) {
              this.offsetY = this.containerHeight;
            }
          } else {
            if (this.offsetY > this.containerHeight) {
              this.offsetY = -this.contentHeight;
            }
          }
        }
      }

      this.updateTextAnimation();
    }, 16);
  }

  updateTextAnimation(): void {
    this.animTick++;

    if (this.config.animationType === 'scale') {
      this.animScale = 1 + Math.sin(this.animTick * 0.1) * 0.15;
      this.animRotate = 0;
      this.animTranslateY = 0;
    } else if (this.config.animationType === 'rotate') {
      this.animScale = 1;
      this.animRotate = Math.sin(this.animTick * 0.08) * 8;
      this.animTranslateY = 0;
    } else if (this.config.animationType === 'jump') {
      this.animScale = 1;
      this.animRotate = 0;
      this.animTranslateY = -Math.abs(Math.sin(this.animTick * 0.12)) * 15;
    } else if (this.config.animationType === 'shake') {
      this.animScale = 1;
      this.animRotate = (Math.random() - 0.5) * 4;
      this.animTranslateY = (Math.random() - 0.5) * 4;
    } else if (this.config.animationType === 'wave') {
      this.animScale = 1 + Math.sin(this.animTick * 0.05) * 0.05;
      this.animRotate = Math.sin(this.animTick * 0.03) * 3;
      this.animTranslateY = Math.sin(this.animTick * 0.08) * 5;
    } else {
      this.animScale = 1;
      this.animRotate = 0;
      this.animTranslateY = 0;
    }
  }

  startBlinkAnimation(): void {
    if (this.blinkTimer !== -1) {
      clearInterval(this.blinkTimer);
      this.blinkTimer = -1;
    }

    if (this.config.isBlinking) {
      const interval = Math.max(100, 1000 - this.config.blinkSpeed * 9);
      this.blinkTimer = setInterval(() => {
        if (!this.isAppeared) {
          return;
        }
        this.getUIContext()?.animateTo({
          duration: Math.min(200, interval / 3),
          curve: Curve.EaseInOut
        }, () => {
          this.blinkOpacity = this.blinkOpacity > 0.5 ? 0 : 1;
        });
      }, interval);
    } else {
      this.blinkOpacity = 1;
    }
  }

  initializePosition(): void {
    if (this.containerWidth <= 0 || this.containerHeight <= 0) {
      return;
    }
    if (this.config.direction === 'horizontal') {
      this.offsetX = this.containerWidth;
      this.offsetY = Math.max(0, (this.containerHeight - this.contentHeight) / 2);
    } else {
      this.offsetX = Math.max(0, (this.containerWidth - this.contentWidth) / 2);
      this.offsetY = this.containerHeight;
    }
    this.positionInitialized = true;
  }

  private buildContentSignature(): string {
    if (this.config.useAdvancedMode) {
      const segmentSignature = this.config.segments.map((segment: BarrageSegment) =>
      `${segment.text}|${segment.fontSize}|${segment.fontColor}|${segment.fontWeight}|${segment.fontStyle}|${segment.fontFamily}|${segment.decorationType}|${segment.hasShadow}`)
        .join('||');
      const gradientSignature = this.config.gradientColors
        .map((stop: [string, number]) => `${stop[0]}@${stop[1]}`)
        .join(',');
      return `advanced:${segmentSignature}|${this.config.direction}|${this.config.gradientEnabled}|${gradientSignature}|${this.config.gradientDirection}|${this.config.strokeEnabled}|${this.config.mirrorMode}`;
    }

    const gradientSignature = this.config.gradientColors
      .map((stop: [string, number]) => `${stop[0]}@${stop[1]}`)
      .join(',');
    return `simple:${this.config.text}|${this.config.fontSize}|${this.config.fontColor}|${this.config.fontWeight}|${this.config.fontStyle}|${this.config.fontFamily}|${this.config.letterSpacing}|${this.config.lineSpacing}|${this.config.decorationType}|${this.config.hasShadow}|${this.config.direction}|${this.config.gradientEnabled}|${gradientSignature}|${this.config.gradientDirection}|${this.config.strokeEnabled}|${this.config.strokeColor}|${this.config.strokeWidth}|${this.config.mirrorMode}`;
  }

  private getDisplayLines(): string[] {
    if (this.config.multiLineEnabled) {
      return this.config.getDisplayLines();
    }
    return this.getTextSafe().split('\n');
  }

  build() {
    Stack() {
      this.buildBackground()

      Stack() {
        Stack() {
          Column() {
            if (this.config.useAdvancedMode) {
              this.buildAdvancedContent()
            } else {
              this.buildSimpleContent()
            }
          }
          .alignItems(HorizontalAlign.Center)
          .onAreaChange((_oldArea: Area, newArea: Area) => {
            const w = newArea.width as number;
            const h = newArea.height as number;
            if (w > 0 && h > 0) {
              const widthChanged = Math.abs(w - this.contentWidth) > 0.5;
              const heightChanged = Math.abs(h - this.contentHeight) > 0.5;
              if (widthChanged || heightChanged) {
                this.contentWidth = w;
                this.contentHeight = h;
                if (!this.positionInitialized ||
                  (this.containerWidth > 0 && this.containerHeight > 0)) {
                  this.initializePosition();
                }
              }
            }
          })

          if (this.config.ledEnabled && this.contentWidth > 0 && this.contentHeight > 0) {
            LEDOverlay({
              density: this.config.ledDensity,
              shape: this.config.ledShape,
              spacing: this.config.ledSpacing,
              containerWidth: this.contentWidth,
              containerHeight: this.contentHeight
            })
              .width(this.contentWidth)
              .height(this.contentHeight)
          }
        }
        .alignContent(Alignment.TopStart)
        .clip(false)
        .scale({
          x: this.animScale * (this.config.mirrorMode ? -1 : 1),
          y: this.animScale
        })
        .rotate({ angle: this.animRotate })
        .translate({ y: this.animTranslateY })
      }
      .width(99999)
      .height(99999)
      .alignContent(Alignment.TopStart)
      .clip(false)
      .position({ x: this.offsetX, y: this.offsetY })

      if (this.config.particleEnabled && this.containerWidth > 0 && this.containerHeight > 0) {
        ParticleOverlay({
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight,
          particleType: this.config.particleType,
          particleCount: 50
        })
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const newWidth = newArea.width as number;
      const newHeight = newArea.height as number;
      if (newWidth > 0 && newHeight > 0 &&
        (Math.abs(newWidth - this.containerWidth) > 0.5 ||
          Math.abs(newHeight - this.containerHeight) > 0.5)) {
        this.containerWidth = newWidth;
        this.containerHeight = newHeight;
        this.initializePosition();
      }
    })
  }

  @Builder
  buildBackground() {
    if (this.config.backgroundType === 'image' && this.config.backgroundImage !== '') {
      Image(this.config.backgroundImage)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(this.config.backgroundOpacity)
    } else if (this.config.backgroundType === 'video' && this.config.backgroundVideo !== '') {
      Video({
        src: this.config.backgroundVideo,
        controller: new VideoController()
      })
        .width('100%')
        .height('100%')
        .autoPlay(true)
        .loop(true)
        .controls(false)
        .objectFit(ImageFit.Cover)
        .muted(true)
    } else {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.config.backgroundColor)
    }
  }

  @Builder
  buildAdvancedContent() {
    if (this.config.direction === 'horizontal') {
      Row() {
        ForEach(this.config.segments, (segment: BarrageSegment, index: number) => {
          BarrageSegmentItem({
            segment: segment,
            layoutDirection: 'horizontal',
            letterSpacing: this.config.letterSpacing,
            lineSpacing: this.config.lineSpacing,
            blinkOpacity: this.blinkOpacity,
            gradientEnabled: this.config.gradientEnabled,
            gradientColors: this.config.gradientColors,
            gradientDirection: this.config.gradientDirection,
            strokeEnabled: this.config.strokeEnabled,
            strokeColor: this.config.strokeColor,
            strokeWidth: this.config.strokeWidth
          })
        }, (segment: BarrageSegment, index: number) => 'segment_' + index.toString())
      }
    } else {
      Column() {
        ForEach(this.config.segments, (segment: BarrageSegment, index: number) => {
          BarrageSegmentItem({
            segment: segment,
            layoutDirection: 'vertical',
            letterSpacing: this.config.letterSpacing,
            lineSpacing: this.config.lineSpacing,
            blinkOpacity: this.blinkOpacity,
            gradientEnabled: this.config.gradientEnabled,
            gradientColors: this.config.gradientColors,
            gradientDirection: this.config.gradientDirection,
            strokeEnabled: this.config.strokeEnabled,
            strokeColor: this.config.strokeColor,
            strokeWidth: this.config.strokeWidth
          })
        }, (segment: BarrageSegment, index: number) => 'segment_' + index.toString())
      }
    }
  }

  @Builder
  buildSimpleContent() {
    if (this.config.direction === 'vertical') {
      Column() {
        ForEach(this.getTextSafe().split(''), (char: string, index: number) => {
          this.buildTextItem(char, index)
        }, (char: string, index: number) => 'char_' + index.toString() + '_' + char)
      }
    } else {
      Column() {
        ForEach(this.getDisplayLines(), (line: string, index: number) => {
          Row() {
            this.buildTextItem(line, index)
          }
        }, (line: string, index: number) => 'line_' + index.toString() + '_' + line)
      }
      .alignItems(HorizontalAlign.Center)
    }
  }

  getTextSafe(): string {
    if (this.config && this.config.text) {
      return this.config.text;
    }
    return '';
  }

  @Builder
  buildTextItem(text: string, index: number) {
    if (this.config.gradientEnabled && this.config.gradientColors.length >= 2) {
      GradientText({
        text: text,
        fontSize: this.config.fontSize,
        fontWeight: this.config.fontWeight,
        fontStyle: this.config.fontStyle,
        fontFamily: this.config.fontFamily,
        letterSpacing: this.config.letterSpacing,
        lineHeight: this.config.fontSize + this.config.lineSpacing,
        decorationType: this.config.decorationType,
        decorationColor: this.config.fontColor,
        gradientColors: this.config.gradientColors,
        gradientDirection: this.config.gradientDirection,
        textOpacity: this.blinkOpacity,
        hasShadow: this.config.hasShadow,
        isVertical: this.config.direction === 'vertical',
        strokeEnabled: this.config.strokeEnabled,
        strokeColor: this.config.strokeColor,
        strokeWidth: this.config.strokeWidth
      })
    } else {
      NormalText({
        text: text,
        fontSize: this.config.fontSize,
        fontColor: this.config.fontColor,
        fontWeight: this.config.fontWeight,
        fontStyle: this.config.fontStyle,
        fontFamily: this.config.fontFamily,
        letterSpacing: this.config.letterSpacing,
        lineHeight: this.config.fontSize + this.config.lineSpacing,
        decorationType: this.config.decorationType,
        decorationColor: this.config.fontColor,
        textOpacity: this.blinkOpacity,
        hasShadow: this.config.hasShadow,
        isVertical: this.config.direction === 'vertical',
        strokeEnabled: this.config.strokeEnabled,
        strokeColor: this.config.strokeColor,
        strokeWidth: this.config.strokeWidth
      })
    }
  }
}