/**
 * 使用 Canvas 实现的渐变文字组件
 * 解决 ArkUI Text 组件无法直接设置渐变字体颜色的问题
 */

import { GradientColorStop } from '../model/BarrageConfig';

/**
 * Canvas 渐变文字组件
 * 通过 Canvas 2D API 绘制渐变色文字，确保渐变效果正确应用
 */
@Component
export struct GradientTextCanvas {
  // 文字内容
  @Prop text: string = '';

  // 字体大小
  @Prop fontSize: number = 48;

  // 字体粗细 (100-900)
  @Prop fontWeight: number = 700;

  // 字体族
  @Prop fontFamily: string = 'HarmonyOS Sans';

  // 是否斜体
  @Prop isItalic: boolean = false;

  // 字间距
  @Prop letterSpacing: number = 0;

  // 渐变色数组
  @Prop gradientColors: GradientColorStop[] = [['#FF0000', 0], ['#0000FF', 1]];

  // 渐变方向 (角度，0-360)
  @Prop gradientAngle: number = 0;

  // 是否显示阴影
  @Prop hasShadow: boolean = false;

  // 阴影颜色
  @Prop shadowColor: string = 'rgba(0, 0, 0, 0.5)';

  // 阴影偏移
  @Prop shadowOffsetX: number = 4;
  @Prop shadowOffsetY: number = 4;

  // 阴影模糊半径
  @Prop shadowBlur: number = 8;

  // 透明度
  @Prop textOpacity: number = 1;

  // 是否垂直显示
  @Prop isVertical: boolean = false;

  // 描边宽度 (0 表示无描边)
  @Prop strokeWidth: number = 0;

  // 描边颜色
  @Prop strokeColor: string = '#000000';

  // Canvas 设置
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 计算后的尺寸
  @State canvasWidth: number = 100;
  @State canvasHeight: number = 100;
  @State isReady: boolean = false;

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

  /**
   * 测量文字尺寸并绘制
   */
  measureAndDraw() {
    if (!this.isReady) return;

    const ctx = this.context;

    // 构建字体样式字符串
    const fontStyle = this.buildFontStyle();
    ctx.font = fontStyle;

    // 测量文字尺寸
    let width: number;
    let height: number;

    if (this.isVertical) {
      // 垂直模式：宽度为单字宽度，高度为所有字符高度之和
      const chars = this.text.split('');
      let maxCharWidth = 0;
      let totalHeight = 0;

      chars.forEach((char, index) => {
        const metrics = ctx.measureText(char);
        maxCharWidth = Math.max(maxCharWidth, metrics.width);
        totalHeight += this.fontSize + (index < chars.length - 1 ? this.letterSpacing : 0);
      });

      width = maxCharWidth + (this.hasShadow ? this.shadowOffsetX + this.shadowBlur : 0) + this.strokeWidth * 2;
      height = totalHeight + (this.hasShadow ? this.shadowOffsetY + this.shadowBlur : 0);
    } else {
      // 水平模式
      const metrics = ctx.measureText(this.text);
      const extraWidth = this.letterSpacing * (this.text.length - 1);

      width = metrics.width + extraWidth + (this.hasShadow ? this.shadowOffsetX + this.shadowBlur : 0) + this.strokeWidth * 2;
      height = this.fontSize * 1.2 + (this.hasShadow ? this.shadowOffsetY + this.shadowBlur : 0);
    }

    // 确保最小尺寸
    width = Math.max(10, Math.ceil(width) + 20);
    height = Math.max(10, Math.ceil(height) + 10);

    // 更新 Canvas 尺寸
    if (this.canvasWidth !== width || this.canvasHeight !== height) {
      this.canvasWidth = width;
      this.canvasHeight = height;

      // 尺寸变化后需要重新绘制
      setTimeout(() => this.draw(), 16);
    } else {
      this.draw();
    }
  }

  /**
   * 构建字体样式字符串
   */
  buildFontStyle(): string {
    const style = this.isItalic ? 'italic' : 'normal';
    const weight = this.fontWeight;
    const size = this.fontSize;
    const family = this.fontFamily;

    return `${style} ${weight} ${size}px ${family}`;
  }

  /**
   * 主绘制函数
   */
  draw() {
    if (!this.isReady) return;

    const ctx = this.context;
    const width = this.canvasWidth;
    const height = this.canvasHeight;

    // 清空画布
    ctx.clearRect(0, 0, width, height);

    // 设置字体
    ctx.font = this.buildFontStyle();
    ctx.textBaseline = 'top';
    ctx.textAlign = 'left';

    if (this.isVertical) {
      this.drawVerticalText(ctx, width, height);
    } else {
      this.drawHorizontalText(ctx, width, height);
    }
  }

  /**
   * 绘制水平文字
   */
  drawHorizontalText(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const startX = 10 + this.strokeWidth;
    const startY = (height - this.fontSize) / 2;

    // 创建渐变
    const gradient = this.createGradient(ctx, startX, startY, width - 20, this.fontSize);

    // 绘制阴影层
    if (this.hasShadow) {
      ctx.save();
      ctx.shadowColor = this.shadowColor;
      ctx.shadowBlur = this.shadowBlur;
      ctx.shadowOffsetX = this.shadowOffsetX;
      ctx.shadowOffsetY = this.shadowOffsetY;
      ctx.fillStyle = this.shadowColor;

      this.drawTextWithSpacing(ctx, this.text, startX, startY);
      ctx.restore();
    }

    // 绘制描边层
    if (this.strokeWidth > 0) {
      ctx.save();
      ctx.strokeStyle = this.strokeColor;
      ctx.lineWidth = this.strokeWidth * 2;
      ctx.lineJoin = 'round';

      let x = startX;
      this.text.split('').forEach((char) => {
        ctx.strokeText(char, x, startY);
        x += ctx.measureText(char).width + this.letterSpacing;
      });
      ctx.restore();
    }

    // 绘制渐变文字
    ctx.fillStyle = gradient;
    this.drawTextWithSpacing(ctx, this.text, startX, startY);
  }

  /**
   * 绘制垂直文字
   */
  drawVerticalText(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const chars = this.text.split('');
    const startX = width / 2;
    let y = 10;

    // 创建垂直方向的渐变
    const gradient = this.createGradient(ctx, startX - this.fontSize / 2, y, this.fontSize, height - 20);

    chars.forEach((char, index) => {
      const charWidth = ctx.measureText(char).width;
      const x = startX - charWidth / 2;

      // 绘制阴影
      if (this.hasShadow) {
        ctx.save();
        ctx.shadowColor = this.shadowColor;
        ctx.shadowBlur = this.shadowBlur;
        ctx.shadowOffsetX = this.shadowOffsetX;
        ctx.shadowOffsetY = this.shadowOffsetY;
        ctx.fillStyle = this.shadowColor;
        ctx.fillText(char, x, y);
        ctx.restore();
      }

      // 绘制描边
      if (this.strokeWidth > 0) {
        ctx.save();
        ctx.strokeStyle = this.strokeColor;
        ctx.lineWidth = this.strokeWidth * 2;
        ctx.lineJoin = 'round';
        ctx.strokeText(char, x, y);
        ctx.restore();
      }

      // 绘制渐变文字
      ctx.fillStyle = gradient;
      ctx.fillText(char, x, y);

      y += this.fontSize + this.letterSpacing;
    });
  }

  /**
   * 带字间距绘制文字
   */
  drawTextWithSpacing(ctx: CanvasRenderingContext2D, text: string, x: number, y: number) {
    if (this.letterSpacing === 0) {
      ctx.fillText(text, x, y);
    } else {
      let currentX = x;
      text.split('').forEach((char) => {
        ctx.fillText(char, currentX, y);
        currentX += ctx.measureText(char).width + this.letterSpacing;
      });
    }
  }

  /**
   * 创建渐变对象
   */
  createGradient(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number): CanvasGradient {
    // 根据角度计算渐变起止点
    const angle = this.gradientAngle * (Math.PI / 180);
    const centerX = x + width / 2;
    const centerY = y + height / 2;

    // 计算渐变线的长度 (对角线)
    const diagonal = Math.sqrt(width * width + height * height);

    const dx = Math.cos(angle) * diagonal / 2;
    const dy = Math.sin(angle) * diagonal / 2;

    const x0 = centerX - dx;
    const y0 = centerY - dy;
    const x1 = centerX + dx;
    const y1 = centerY + dy;

    const gradient = ctx.createLinearGradient(x0, y0, x1, y1);

    // 添加颜色停止点
    this.gradientColors.forEach(([color, position]) => {
      gradient.addColorStop(position, color);
    });

    return gradient;
  }

  /**
   * 监听属性变化，重新绘制
   */
  onDidBuild(): void {
    if (this.isReady) {
      this.measureAndDraw();
    }
  }
}

/**
 * 高性能渐变文字组件 (使用 Image 缓存)
 * 适用于频繁动画场景，通过缓存渲染结果提升性能
 */
@Component
export struct CachedGradientText {
  @Prop text: string = '';
  @Prop fontSize: number = 48;
  @Prop fontWeight: number = 700;
  @Prop fontFamily: string = 'HarmonyOS Sans';
  @Prop gradientColors: GradientColorStop[] = [['#FF0000', 0], ['#0000FF', 1]];
  @Prop gradientAngle: number = 0;
  @Prop hasShadow: boolean = false;
  @Prop textOpacity: number = 1;

  // 缓存的图像数据
  @State cachedImage: string = '';
  @State imageWidth: number = 100;
  @State imageHeight: number = 50;

  private offscreenSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private offscreenContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.offscreenSettings);
  private needsRedraw: boolean = true;

  aboutToAppear() {
    this.renderToCache();
  }

  build() {
    if (this.cachedImage) {
      Image(this.cachedImage)
        .width(this.imageWidth)
        .height(this.imageHeight)
        .opacity(this.textOpacity)
        .objectFit(ImageFit.Contain)
    } else {
      // Fallback: 使用普通文字
      Text(this.text)
        .fontSize(this.fontSize)
        .fontWeight(this.fontWeight)
        .fontFamily(this.fontFamily)
        .fontColor(this.gradientColors[0]?.[0] ?? '#FFFFFF')
        .opacity(this.textOpacity)
    }
  }

  /**
   * 渲染到缓存
   * 注意: 这里使用 OffscreenCanvas 会更好，但 ArkUI 可能不完全支持
   * 这是一个示意实现
   */
  renderToCache() {
    // 在实际项目中，可以使用 OffscreenCanvas 或其他缓存机制
    // 这里仅作为架构示意
    this.needsRedraw = false;
  }

  onDidBuild(): void {
    if (this.needsRedraw) {
      this.renderToCache();
    }
  }
}

/**
 * 彩虹文字组件
 * 每个字符使用不同颜色，形成彩虹效果
 */
@Component
export struct RainbowText {
  @Prop text: string = '';
  @Prop fontSize: number = 48;
  @Prop fontWeight: FontWeight = FontWeight.Bold;
  @Prop fontFamily: string = 'HarmonyOS Sans';
  @Prop letterSpacing: number = 0;
  @Prop hasShadow: boolean = false;
  @Prop textOpacity: number = 1;
  @Prop isVertical: boolean = false;

  // 彩虹颜色数组
  private rainbowColors: string[] = [
    '#FF0000', // 红
    '#FF7F00', // 橙
    '#FFFF00', // 黄
    '#00FF00', // 绿
    '#00FFFF', // 青
    '#0000FF', // 蓝
    '#8B00FF'  // 紫
  ];

  build() {
    if (this.isVertical) {
      Column() {
        ForEach(this.text.split(''), (char: string, index: number) => {
          Text(char)
            .fontSize(this.fontSize)
            .fontWeight(this.fontWeight)
            .fontFamily(this.fontFamily)
            .fontColor(this.rainbowColors[index % this.rainbowColors.length])
            .textShadow(this.hasShadow ? {
              radius: 10,
              color: '#80000000',
              offsetX: 3,
              offsetY: 3
            } : undefined)
            .opacity(this.textOpacity)
        }, (char: string, index: number) => `${index}_${char}`)
      }
    } else {
      Row() {
        ForEach(this.text.split(''), (char: string, index: number) => {
          Text(char)
            .fontSize(this.fontSize)
            .fontWeight(this.fontWeight)
            .fontFamily(this.fontFamily)
            .fontColor(this.rainbowColors[index % this.rainbowColors.length])
            .letterSpacing(this.letterSpacing)
            .textShadow(this.hasShadow ? {
              radius: 10,
              color: '#80000000',
              offsetX: 3,
              offsetY: 3
            } : undefined)
            .opacity(this.textOpacity)
        }, (char: string, index: number) => `${index}_${char}`)
      }
    }
  }
}

/**
 * 霓虹发光文字组件
 * 模拟霓虹灯效果
 */
@Component
export struct NeonText {
  @Prop text: string = '';
  @Prop fontSize: number = 48;
  @Prop fontWeight: FontWeight = FontWeight.Bold;
  @Prop fontFamily: string = 'HarmonyOS Sans';
  @Prop neonColor: string = '#00FFFF';
  @Prop glowIntensity: number = 1; // 0-2
  @Prop textOpacity: number = 1;

  build() {
    Stack() {
      // 多层发光效果
      ForEach([3, 2, 1, 0], (layer: number) => {
        Text(this.text)
          .fontSize(this.fontSize)
          .fontWeight(this.fontWeight)
          .fontFamily(this.fontFamily)
          .fontColor(layer === 0 ? '#FFFFFF' : this.neonColor)
          .textShadow({
            radius: (layer + 1) * 8 * this.glowIntensity,
            color: this.neonColor,
            offsetX: 0,
            offsetY: 0
          })
          .opacity(layer === 0 ? this.textOpacity : this.textOpacity * (0.3 + layer * 0.2))
      })
    }
  }
}

/**
 * 描边文字组件
 * 使用多层叠加实现描边效果
 */
@Component
export struct StrokeText {
  @Prop text: string = '';
  @Prop fontSize: number = 48;
  @Prop fontWeight: FontWeight = FontWeight.Bold;
  @Prop fontFamily: string = 'HarmonyOS Sans';
  @Prop fillColor: string = '#FFFFFF';
  @Prop strokeColor: string = '#000000';
  @Prop strokeWidth: number = 2;
  @Prop textOpacity: number = 1;

  build() {
    Stack() {
      // 描边层 (8个方向的偏移)
      ForEach([
        [-1, -1], [0, -1], [1, -1],
        [-1, 0],          [1, 0],
        [-1, 1],  [0, 1],  [1, 1]
      ], (offset: number[]) => {
        Text(this.text)
          .fontSize(this.fontSize)
          .fontWeight(this.fontWeight)
          .fontFamily(this.fontFamily)
          .fontColor(this.strokeColor)
          .translate({
            x: offset[0] * this.strokeWidth,
            y: offset[1] * this.strokeWidth
          })
          .opacity(this.textOpacity)
      })

      // 填充层
      Text(this.text)
        .fontSize(this.fontSize)
        .fontWeight(this.fontWeight)
        .fontFamily(this.fontFamily)
        .fontColor(this.fillColor)
        .opacity(this.textOpacity)
    }
  }
}