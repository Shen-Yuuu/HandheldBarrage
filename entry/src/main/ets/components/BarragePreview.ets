import { BarrageConfig, BarrageSegment } from '../model/BarrageConfig';

/**
 * 渐变文字组件 - 修复版本
 * 核心修复：
 * 1. 使用 measureText 获取真实文本宽度
 * 2. 大幅增加安全边距
 * 3. 确保字体大小与普通文字一致
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
  @Prop @Watch('onPropsChange') gradientColors: Array<[string, number]> = [['#FF0000', 0], ['#0000FF', 1]];
  @Prop @Watch('onPropsChange') gradientDirection: number = 90;
  @Prop textOpacity: number = 1;
  @Prop @Watch('onPropsChange') hasShadow: boolean = false;
  @Prop @Watch('onPropsChange') isVertical: boolean = false;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  @State canvasWidth: number = 100;
  @State canvasHeight: number = 100;
  @State isReady: boolean = false;

  // 缓存测量结果
  private measuredTextWidth: number = 0;
  private measuredTextHeight: number = 0;

  onPropsChange() {
    if (this.isReady) {
      this.measureAndDraw();
    }
  }

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .onReady(() => {
        this.isReady = true;
        this.measureAndDraw();
      })
      .opacity(this.textOpacity)
  }

  private getFontWeightValue(): number {
    switch (this.fontWeight) {
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

  private getTextSafe(): string {
    return this.text || '';
  }

  private buildFontString(): string {
    const fontStyleStr = this.fontStyle === FontStyle.Italic ? 'italic' : 'normal';
    const fontWeightVal = this.getFontWeightValue();
    return `${fontStyleStr} ${fontWeightVal} ${this.fontSize}px "${this.fontFamily}"`;
  }

  measureAndDraw(): void {
    if (!this.isReady) {
      return;
    }

    const safeText = this.getTextSafe();
    if (safeText.length === 0) {
      this.canvasWidth = 10;
      this.canvasHeight = 10;
      return;
    }

    const ctx = this.context;

    // 设置字体以便测量
    ctx.font = this.buildFontString();

    let width: number;
    let height: number;

    // 阴影需要的额外空间
    const shadowOffset = this.hasShadow ? 20 : 0;
    // 基础边距 - 大幅增加以确保大字体不被裁剪
    const basePadding = Math.max(20, this.fontSize * 0.3);

    if (this.isVertical) {
      // 竖向布局
      const chars = safeText.split('');
      let maxCharWidth: number = 0;

      // 测量每个字符的宽度，取最大值
      for (let i = 0; i < chars.length; i++) {
        const charMetrics = ctx.measureText(chars[i]);
        if (charMetrics.width > maxCharWidth) {
          maxCharWidth = charMetrics.width;
        }
      }

      const lineH = this.lineHeight > 0 ? this.lineHeight : this.fontSize * 1.4;
      const totalHeight = chars.length * lineH;

      // 宽度 = 最大字符宽度 + 边距 + 阴影
      width = maxCharWidth + basePadding * 2 + shadowOffset;
      // 高度 = 总行高 + 边距 + 阴影
      height = totalHeight + basePadding * 2 + shadowOffset;

      this.measuredTextWidth = maxCharWidth;
      this.measuredTextHeight = totalHeight;
    } else {
      // 横向布局 - 使用 measureText 获取真实宽度
      let totalTextWidth: number = 0;

      if (this.letterSpacing === 0) {
        // 无字间距，直接测量整个文本
        const metrics = ctx.measureText(safeText);
        totalTextWidth = metrics.width;
      } else {
        // 有字间距，需要逐字测量并加上间距
        const chars = safeText.split('');
        for (let i = 0; i < chars.length; i++) {
          totalTextWidth += ctx.measureText(chars[i]).width;
        }
        // 加上字间距（字符数-1 个间距）
        totalTextWidth += this.letterSpacing * Math.max(0, chars.length - 1);
      }

      // 宽度 = 文本宽度 + 边距 + 阴影
      width = totalTextWidth + basePadding * 2 + shadowOffset;
      // 高度 = 字体大小 * 1.5（考虑上下行高）+ 边距 + 阴影
      height = this.fontSize * 1.6 + basePadding * 2 + shadowOffset;

      this.measuredTextWidth = totalTextWidth;
      this.measuredTextHeight = this.fontSize;
    }

    // 确保最小尺寸
    width = Math.max(50, Math.ceil(width));
    height = Math.max(50, Math.ceil(height));

    // 检查尺寸是否需要更新
    if (Math.abs(this.canvasWidth - width) > 2 || Math.abs(this.canvasHeight - height) > 2) {
      this.canvasWidth = width;
      this.canvasHeight = height;

      // 延迟绘制，等待 Canvas 尺寸更新完成
      setTimeout(() => {
        this.draw();
      }, 20);
    } else {
      this.draw();
    }
  }

  draw(): void {
    if (!this.isReady) {
      return;
    }

    const ctx = this.context;
    const width = this.canvasWidth;
    const height = this.canvasHeight;

    // 清空画布
    ctx.clearRect(0, 0, width, height);

    // 设置字体
    ctx.font = this.buildFontString();
    ctx.textBaseline = 'middle';

    if (this.isVertical) {
      this.drawVerticalText(ctx, width, height);
    } else {
      this.drawHorizontalText(ctx, width, height);
    }
  }

  drawHorizontalText(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const safeText = this.getTextSafe();
    if (safeText.length === 0) {
      return;
    }

    // 计算绘制起始位置（居中）
    const shadowOffset = this.hasShadow ? 10 : 0;
    const centerX = (width - shadowOffset) / 2;
    const centerY = (height - shadowOffset) / 2;

    // 创建渐变
    const angle = this.gradientDirection * (Math.PI / 180);
    const gradientLength = Math.max(this.measuredTextWidth, width) / 2;
    const dx = Math.cos(angle) * gradientLength;
    const dy = Math.sin(angle) * gradientLength;

    const gradient = ctx.createLinearGradient(
      centerX - dx, centerY - dy,
      centerX + dx, centerY + dy
    );

    for (let i = 0; i < this.gradientColors.length; i++) {
      const colorStop = this.gradientColors[i];
      gradient.addColorStop(colorStop[1], colorStop[0]);
    }

    // 设置阴影
    if (this.hasShadow) {
      ctx.shadowColor = 'rgba(0, 0, 0, 0.6)';
      ctx.shadowBlur = 12;
      ctx.shadowOffsetX = 5;
      ctx.shadowOffsetY = 5;
    }

    // 绘制文字
    ctx.fillStyle = gradient;
    ctx.textAlign = 'center';

    if (this.letterSpacing === 0) {
      ctx.fillText(safeText, centerX, centerY);
    } else {
      this.drawTextWithSpacing(ctx, safeText, centerX, centerY);
    }

    // 重置阴影
    if (this.hasShadow) {
      ctx.shadowColor = 'transparent';
      ctx.shadowBlur = 0;
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 0;
    }
  }

  drawVerticalText(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const safeText = this.getTextSafe();
    if (safeText.length === 0) {
      return;
    }

    const chars = safeText.split('');
    const lineH = this.lineHeight > 0 ? this.lineHeight : this.fontSize * 1.4;
    const totalHeight = chars.length * lineH;

    const shadowOffset = this.hasShadow ? 10 : 0;
    const centerX = (width - shadowOffset) / 2;
    const startY = (height - shadowOffset - totalHeight) / 2 + lineH / 2;

    // 创建垂直渐变
    const gradient = ctx.createLinearGradient(0, startY - lineH / 2, 0, startY + totalHeight);
    for (let i = 0; i < this.gradientColors.length; i++) {
      const colorStop = this.gradientColors[i];
      gradient.addColorStop(colorStop[1], colorStop[0]);
    }

    // 设置阴影
    if (this.hasShadow) {
      ctx.shadowColor = 'rgba(0, 0, 0, 0.6)';
      ctx.shadowBlur = 12;
      ctx.shadowOffsetX = 5;
      ctx.shadowOffsetY = 5;
    }

    ctx.fillStyle = gradient;
    ctx.textAlign = 'center';

    let y = startY;
    for (let i = 0; i < chars.length; i++) {
      ctx.fillText(chars[i], centerX, y);
      y += lineH;
    }

    // 重置阴影
    if (this.hasShadow) {
      ctx.shadowColor = 'transparent';
      ctx.shadowBlur = 0;
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 0;
    }
  }

  drawTextWithSpacing(ctx: CanvasRenderingContext2D, text: string, centerX: number, centerY: number) {
    const chars = text.split('');
    const charWidths: number[] = [];
    let totalWidth = 0;

    // 测量每个字符宽度
    for (let i = 0; i < chars.length; i++) {
      const w = ctx.measureText(chars[i]).width;
      charWidths.push(w);
      totalWidth += w;
      if (i < chars.length - 1) {
        totalWidth += this.letterSpacing;
      }
    }

    // 从居中位置开始绘制
    let x = centerX - totalWidth / 2;
    ctx.textAlign = 'left';

    for (let i = 0; i < chars.length; i++) {
      ctx.fillText(chars[i], x, centerY);
      x += charWidths[i] + this.letterSpacing;
    }
  }
}

/**
 * 普通文字组件 - 支持阴影
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

  build() {
    Text(this.text)
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(this.fontWeight)
      .fontStyle(this.fontStyle)
      .fontFamily(this.fontFamily)
      .letterSpacing(this.letterSpacing)
      .lineHeight(this.lineHeight > 0 ? this.lineHeight : undefined)
      .decoration({ type: this.decorationType, color: this.decorationColor })
      .maxLines(this.isVertical ? undefined : 1)
      .textOverflow({ overflow: TextOverflow.None })
      .opacity(this.textOpacity)
      .textShadow(this.hasShadow ? {
        radius: 12,
        color: 'rgba(0, 0, 0, 0.6)',
        offsetX: 5,
        offsetY: 5
      } : undefined)
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
        isVertical: false
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
        isVertical: false
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
            isVertical: true
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
            isVertical: true
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

  drawCircleLED(ctx: CanvasRenderingContext2D, width: number, height: number, size: number, gap: number, step: number) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = 'rgba(255, 255, 255, 1)';

    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        const centerX = x + size / 2;
        const centerY = y + size / 2;
        const radius = size / 2 * 0.9;

        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    ctx.globalCompositeOperation = 'source-over';
    ctx.strokeStyle = 'rgba(40, 40, 40, 0.6)';
    ctx.lineWidth = 0.5;

    for (let y = gap / 2; y < height; y += step) {
      for (let x = gap / 2; x < width; x += step) {
        const centerX = x + size / 2;
        const centerY = y + size / 2;
        const radius = size / 2 * 0.9;

        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
        ctx.stroke();
      }
    }
  }

  drawSquareLED(ctx: CanvasRenderingContext2D, width: number, height: number, size: number, gap: number, step: number) {
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

  drawGridLED(ctx: CanvasRenderingContext2D, width: number, height: number, size: number, gap: number, step: number) {
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
        const centerX = x + size / 2;
        const centerY = y + size / 2;
        ctx.beginPath();
        ctx.arc(centerX, centerY, size * 0.35, 0, Math.PI * 2);
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
    // 空构造函数
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

    const gradient = ctx.createRadialGradient(
      p.x - size * 0.3, p.y - size * 0.3, 0,
      p.x, p.y, size
    );
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
 * 弹幕预览主组件 - 修复版本
 * 核心修复：
 * 1. 使用实际测量的 contentWidth/contentHeight 进行滚动判断
 * 2. 增加滚动缓冲区
 * 3. 修复渐变模式下的尺寸计算
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

  aboutToAppear(): void {
    this.isAppeared = true;
    this.lastIsBlinking = this.config.isBlinking;
    this.lastBlinkSpeed = this.config.blinkSpeed;
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

      // 检查闪烁配置变化
      if (this.lastIsBlinking !== this.config.isBlinking ||
        this.lastBlinkSpeed !== this.config.blinkSpeed) {
        this.lastIsBlinking = this.config.isBlinking;
        this.lastBlinkSpeed = this.config.blinkSpeed;
        this.startBlinkAnimation();
      }

      const speed = Math.max(1, this.config.scrollSpeed / 5);

      if (this.config.direction === 'horizontal') {
        this.offsetX -= speed;

        // 保持垂直居中
        if (this.contentHeight > 0 && this.containerHeight > 0) {
          this.offsetY = (this.containerHeight - this.contentHeight) / 2;
        }

        // 【关键修复】使用实际测量的 contentWidth，加上额外缓冲区
        // 只有当内容完全滚出左侧时才重置
        const effectiveWidth = this.contentWidth > 0 ? this.contentWidth : this.containerWidth;
        const scrollBuffer = 50; // 额外缓冲区，确保内容完全滚出

        if (this.offsetX < -(effectiveWidth + scrollBuffer)) {
          // 从右侧屏幕外开始
          this.offsetX = this.containerWidth + scrollBuffer;
        }
      } else {
        this.offsetY -= speed;

        // 保持水平居中
        if (this.contentWidth > 0 && this.containerWidth > 0) {
          this.offsetX = (this.containerWidth - this.contentWidth) / 2;
        }

        // 使用实际测量的 contentHeight
        const effectiveHeight = this.contentHeight > 0 ? this.contentHeight : this.containerHeight;
        const scrollBuffer = 50;

        if (this.offsetY < -(effectiveHeight + scrollBuffer)) {
          this.offsetY = this.containerHeight + scrollBuffer;
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
          if (this.blinkOpacity > 0.5) {
            this.blinkOpacity = 0;
          } else {
            this.blinkOpacity = 1;
          }
        });
      }, interval);
    } else {
      this.blinkOpacity = 1;
    }
  }

  initializePosition(): void {
    if (this.config.direction === 'horizontal') {
      this.offsetX = this.containerWidth;
      this.offsetY = (this.containerHeight - this.contentHeight) / 2;
    } else {
      this.offsetX = (this.containerWidth - this.contentWidth) / 2;
      this.offsetY = this.containerHeight;
    }
  }

  build() {
    Stack() {
      // === 背景层 ===
      this.buildBackground()

      // === 内容层 ===
      Column() {
        if (this.config.useAdvancedMode) {
          this.buildAdvancedContent()
        } else {
          this.buildSimpleContent()
        }
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .scale({ x: this.animScale, y: this.animScale })
      .rotate({ angle: this.animRotate })
      .translate({ y: this.animTranslateY })
      .position({ x: this.offsetX, y: this.offsetY })
      .onAreaChange((oldArea: Area, newArea: Area) => {
        const newWidth = newArea.width as number;
        const newHeight = newArea.height as number;

        // 【关键】更新实际内容尺寸
        if (newWidth !== this.contentWidth || newHeight !== this.contentHeight) {
          this.contentWidth = newWidth;
          this.contentHeight = newHeight;
        }
      })

      // === 粒子效果层 ===
      if (this.config.particleEnabled) {
        ParticleOverlay({
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight,
          particleType: this.config.particleType,
          particleCount: 50
        })
      }

      // === LED 效果层 ===
      if (this.config.ledEnabled) {
        LEDOverlay({
          density: this.config.ledDensity,
          shape: this.config.ledShape,
          spacing: this.config.ledSpacing,
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight
        })
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .onAreaChange((oldArea: Area, newArea: Area) => {
      const newWidth = newArea.width as number;
      const newHeight = newArea.height as number;

      if (newWidth !== this.containerWidth || newHeight !== this.containerHeight) {
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
            gradientDirection: this.config.gradientDirection
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
            gradientDirection: this.config.gradientDirection
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
        ForEach(this.getTextSafe().split('\n'), (line: string, index: number) => {
          Row() {
            this.buildTextItem(line, index)
          }
        }, (line: string, index: number) => 'line_' + index.toString())
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
        isVertical: this.config.direction === 'vertical'
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
        isVertical: this.config.direction === 'vertical'
      })
    }
  }
}