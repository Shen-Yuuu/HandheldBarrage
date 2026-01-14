/**
 * 弹幕配置数据模型
 * 用于手持弹幕播报器应用
 */

/**
 * 辅助类型定义
 */
export class LineStyle {
  fontSize: number = 48;
  fontColor: ResourceColor = '#FFFFFF';
  scale: number = 1;
}

export class RgbColor {
  r: number = 0;
  g: number = 0;
  b: number = 0;
}

/**
 * 弹幕片段 - 用于高级模式下的富文本支持
 */
@Observed
export class BarrageSegment {
  // 唯一标识
  id: string = '';

  // 文本内容
  text: string = '';

  // 字体大小 (px)
  fontSize: number = 48;

  // 字体颜色
  fontColor: ResourceColor = '#FFFFFF';

  // 字体粗细
  fontWeight: FontWeight = FontWeight.Bold;

  // 字体样式 (正常/斜体)
  fontStyle: FontStyle = FontStyle.Normal;

  // 字体族
  fontFamily: string = 'HarmonyOS Sans';

  // 文字装饰 (下划线/删除线等)
  decorationType: TextDecorationType = TextDecorationType.None;

  // 是否有阴影
  hasShadow: boolean = true;

  // 是否是图片类型
  isImage: boolean = false;

  // 图片资源 (当 isImage 为 true 时使用)
  imageSource: string | Resource = '';

  // 图片宽度
  imageWidth: number = 48;

  // 图片高度
  imageHeight: number = 48;

  constructor(options?: Partial<BarrageSegment>) {
    if (options) {
      this.id = options.id ?? this.generateId();
      this.text = options.text ?? this.text;
      this.fontSize = options.fontSize ?? this.fontSize;
      this.fontColor = options.fontColor ?? this.fontColor;
      this.fontWeight = options.fontWeight ?? this.fontWeight;
      this.fontStyle = options.fontStyle ?? this.fontStyle;
      this.fontFamily = options.fontFamily ?? this.fontFamily;
      this.decorationType = options.decorationType ?? this.decorationType;
      this.hasShadow = options.hasShadow ?? this.hasShadow;
      this.isImage = options.isImage ?? this.isImage;
      this.imageSource = options.imageSource ?? this.imageSource;
      this.imageWidth = options.imageWidth ?? this.imageWidth;
      this.imageHeight = options.imageHeight ?? this.imageHeight;
    } else {
      this.id = this.generateId();
    }
  }

  private generateId(): string {
    return `segment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // 创建文本片段
  static createText(text: string, options?: Partial<BarrageSegment>): BarrageSegment {
    const segment = new BarrageSegment(options);
    segment.text = text;
    segment.isImage = false;
    return segment;
  }

  // 创建图片片段
  static createImage(source: string | Resource, width: number = 48, height: number = 48): BarrageSegment {
    const segment = new BarrageSegment();
    segment.isImage = true;
    segment.imageSource = source;
    segment.imageWidth = width;
    segment.imageHeight = height;
    segment.text = '';
    return segment;
  }

  // 复制片段
  clone(): BarrageSegment {
    const segment = new BarrageSegment();
    segment.id = this.generateId();
    segment.text = this.text;
    segment.fontSize = this.fontSize;
    segment.fontColor = this.fontColor;
    segment.fontWeight = this.fontWeight;
    segment.fontStyle = this.fontStyle;
    segment.fontFamily = this.fontFamily;
    segment.decorationType = this.decorationType;
    segment.hasShadow = this.hasShadow;
    segment.isImage = this.isImage;
    segment.imageSource = this.imageSource;
    segment.imageWidth = this.imageWidth;
    segment.imageHeight = this.imageHeight;
    return segment;
  }
}

/**
 * 渐变色停止点类型
 */
export type GradientColorStop = [string, number]; // [颜色, 位置(0-1)]

/**
 * 动画类型枚举
 */
export type AnimationType = 'none' | 'scale' | 'rotate' | 'jump' | 'shake' | 'wave';

/**
 * 滚动方向枚举
 */
export type ScrollDirection = 'horizontal' | 'vertical';

/**
 * 背景类型枚举
 */
export type BackgroundType = 'color' | 'image' | 'video';

/**
 * LED形状枚举
 */
export type LEDShape = 'circle' | 'square' | 'grid';

/**
 * 粒子类型枚举 - 增强版
 */
export type ParticleType = 'sparkle' | 'bubble' | 'fire' | 'snow' | 'star';

/**
 * 预设模板类型 - 增强版
 */
export type PresetType = 'concert' | 'sports' | 'birthday' | 'neon' | 'christmas' | 'halloween' | 'romantic' | 'gaming' | 'custom';

/**
 * 弹幕主配置类
 */
@Observed
export class BarrageConfig {
  // ===== 基础内容 =====

  // 简单模式文本内容
  text: string = '手持弹幕 🎉';

  // 是否使用高级模式 (富文本)
  useAdvancedMode: boolean = false;

  // 高级模式片段列表
  segments: BarrageSegment[] = [];

  // ===== 字体样式 =====

  // 字体大小 (px)
  fontSize: number = 64;

  // 字体颜色
  fontColor: ResourceColor = '#FF0000';

  // 字体粗细
  fontWeight: FontWeight = FontWeight.Bold;

  // 字体样式
  fontStyle: FontStyle = FontStyle.Normal;

  // 字体族
  fontFamily: string = 'HarmonyOS Sans';

  // 文字装饰类型
  decorationType: TextDecorationType = TextDecorationType.None;

  // 字间距 (px)
  letterSpacing: number = 2;

  // 行间距 (px)
  lineSpacing: number = 10;

  // 是否有阴影
  hasShadow: boolean = true;

  // ===== 渐变色设置 =====

  // 是否启用渐变色
  gradientEnabled: boolean = false;

  // 渐变色数组
  gradientColors: GradientColorStop[] = [
    ['#FF0000', 0],
    ['#FFFF00', 0.5],
    ['#00FF00', 1]
  ];

  // 渐变方向 (角度)
  gradientDirection: number = 90;

  // ===== 背景设置 =====

  // 背景类型
  backgroundType: BackgroundType = 'color';

  // 背景颜色
  backgroundColor: ResourceColor = '#000000';

  // 背景图片
  backgroundImage: string | Resource = '';

  // 背景视频
  backgroundVideo: string | Resource = '';

  // 背景透明度 (0-1)
  backgroundOpacity: number = 1;

  // 背景模糊程度
  backgroundBlur: number = 0;

  // ===== 滚动设置 =====

  // 滚动方向
  direction: ScrollDirection = 'horizontal';

  // 滚动速度 (1-100)
  scrollSpeed: number = 50;

  // ===== 动画效果 =====

  // 动画类型
  animationType: AnimationType = 'none';

  // 是否启用闪烁
  isBlinking: boolean = false;

  // 闪烁速度 (1-100)
  blinkSpeed: number = 50;

  // ===== LED效果 =====

  // 是否启用LED效果
  ledEnabled: boolean = false;

  // LED密度 (像素大小)
  ledDensity: number = 4;

  // LED形状
  ledShape: LEDShape = 'circle';

  // LED间距
  ledSpacing: number = 2;

  // ===== 粒子效果 =====

  // 是否启用粒子效果
  particleEnabled: boolean = false;

  // 粒子类型
  particleType: ParticleType = 'sparkle';

  // ===== 屏幕设置 =====

  // 屏幕方向锁定
  orientationLock: 'auto' | 'landscape' | 'portrait' = 'auto';

  // 是否保持屏幕常亮
  keepScreenOn: boolean = true;

  // ===== 多行弹幕设置 =====

  // 是否启用多行模式
  multiLineEnabled: boolean = false;

  // 行数
  lineCount: number = 1;

  // 是否所有行内容相同
  sameContent: boolean = true;

  // 多行内容列表 (当 sameContent 为 false 时使用)
  lineContents: string[] = [];

  // 特殊行设置类型
  specialLineType: 'none' | 'middle-large' | 'first-color' | 'gradient-size' | 'alternate-color' | 'rainbow' = 'none';

  // 特殊行颜色
  specialLineColor: ResourceColor = '#FFD700';

  // 中间行放大倍数
  middleLineScale: number = 1.5;

  constructor(options?: Partial<BarrageConfig>) {
    if (options) {
      this.copyFromPartial(options);
    }
  }

  // ===== 预设模板 =====

  /**
   * 加载预设模板
   */
  loadPreset(preset: PresetType): void {
    switch (preset) {
      case 'concert':
        this.applyConcertPreset();
        break;
      case 'sports':
        this.applySportsPreset();
        break;
      case 'birthday':
        this.applyBirthdayPreset();
        break;
      case 'neon':
        this.applyNeonPreset();
        break;
      case 'christmas':
        this.applyChristmasPreset();
        break;
      case 'halloween':
        this.applyHalloweenPreset();
        break;
      case 'romantic':
        this.applyRomanticPreset();
        break;
      case 'gaming':
        this.applyGamingPreset();
        break;
      default:
        // custom - 不做任何改变
        break;
    }
  }

  private applyConcertPreset(): void {
    this.text = '我爱你！❤️🎤✨';
    this.fontSize = 80;
    this.fontColor = '#FF1493';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#000000';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const concertColors: GradientColorStop[] = [
      ['#FF1493', 0],
      ['#FF69B4', 0.5],
      ['#FFB6C1', 1]
    ];
    this.gradientColors = concertColors;
    this.isBlinking = true;
    this.blinkSpeed = 30;
    this.particleEnabled = true;
    this.particleType = 'sparkle';
  }

  private applySportsPreset(): void {
    this.text = '加油！冲冲冲！💪🔥';
    this.fontSize = 72;
    this.fontColor = '#00FF00';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#1A1A2E';
    this.hasShadow = true;
    this.gradientEnabled = false;
    this.animationType = 'shake';
    this.isBlinking = false;
  }

  private applyBirthdayPreset(): void {
    this.text = '生日快乐！🎂🎉🎈';
    this.fontSize = 68;
    this.fontColor = '#FFD700';
    this.fontWeight = FontWeight.Bold;
    this.backgroundColor = '#FF69B4';
    this.gradientEnabled = true;
    const birthdayColors: GradientColorStop[] = [
      ['#FFD700', 0],
      ['#FFA500', 0.5],
      ['#FF6347', 1]
    ];
    this.gradientColors = birthdayColors;
    this.animationType = 'jump';
    this.particleEnabled = true;
    this.particleType = 'bubble';
  }

  private applyNeonPreset(): void {
    this.text = 'HELLO WORLD ⚡';
    this.fontSize = 76;
    this.fontColor = '#00FFFF';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#0A0A0A';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const neonColors: GradientColorStop[] = [
      ['#00FFFF', 0],
      ['#FF00FF', 0.5],
      ['#00FFFF', 1]
    ];
    this.gradientColors = neonColors;
    this.ledEnabled = true;
    this.ledShape = 'circle';
    this.ledDensity = 3;
    this.ledSpacing = 1;
  }

  private applyChristmasPreset(): void {
    this.text = '圣诞快乐！🎄🎅❄️';
    this.fontSize = 72;
    this.fontColor = '#FFFFFF';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#228B22';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const christmasColors: GradientColorStop[] = [
      ['#FF0000', 0],
      ['#FFFFFF', 0.5],
      ['#00FF00', 1]
    ];
    this.gradientColors = christmasColors;
    this.particleEnabled = true;
    this.particleType = 'snow';
    this.animationType = 'wave';
  }

  private applyHalloweenPreset(): void {
    this.text = 'TRICK OR TREAT 🎃👻💀';
    this.fontSize = 68;
    this.fontColor = '#FF6600';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#1A0A2E';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const halloweenColors: GradientColorStop[] = [
      ['#FF6600', 0],
      ['#8B00FF', 0.5],
      ['#FF6600', 1]
    ];
    this.gradientColors = halloweenColors;
    this.particleEnabled = true;
    this.particleType = 'fire';
    this.animationType = 'shake';
    this.isBlinking = true;
    this.blinkSpeed = 50;
  }

  private applyRomanticPreset(): void {
    this.text = 'I LOVE YOU ❤️💕💖';
    this.fontSize = 80;
    this.fontColor = '#FF1493';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#2D0A2E';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const romanticColors: GradientColorStop[] = [
      ['#FF69B4', 0],
      ['#FF1493', 0.3],
      ['#DC143C', 0.7],
      ['#FF69B4', 1]
    ];
    this.gradientColors = romanticColors;
    this.particleEnabled = true;
    this.particleType = 'star';
    this.animationType = 'scale';
  }

  private applyGamingPreset(): void {
    this.text = 'GG WP 🎮🏆⚔️';
    this.fontSize = 76;
    this.fontColor = '#00FF00';
    this.fontWeight = FontWeight.Bolder;
    this.backgroundColor = '#0D0D0D';
    this.hasShadow = true;
    this.gradientEnabled = true;
    const gamingColors: GradientColorStop[] = [
      ['#00FF00', 0],
      ['#00BFFF', 0.5],
      ['#FF00FF', 1]
    ];
    this.gradientColors = gamingColors;
    this.ledEnabled = true;
    this.ledShape = 'square';
    this.ledDensity = 4;
    this.ledSpacing = 1;
    this.animationType = 'jump';
  }

  // ===== 工具方法 =====

  /**
   * 添加文本片段 (高级模式)
   */
  addTextSegment(text: string, options?: Partial<BarrageSegment>): void {
    this.segments.push(BarrageSegment.createText(text, options));
  }

  /**
   * 添加图片片段 (高级模式)
   */
  addImageSegment(source: string | Resource, width?: number, height?: number): void {
    this.segments.push(BarrageSegment.createImage(source, width, height));
  }

  /**
   * 删除片段
   */
  removeSegment(index: number): void {
    if (index >= 0 && index < this.segments.length) {
      this.segments.splice(index, 1);
    }
  }

  /**
   * 移动片段位置
   */
  moveSegment(fromIndex: number, toIndex: number): void {
    if (fromIndex >= 0 && fromIndex < this.segments.length &&
        toIndex >= 0 && toIndex < this.segments.length) {
      const removed = this.segments.splice(fromIndex, 1);
      const segment = removed[0];
      this.segments.splice(toIndex, 0, segment);
    }
  }

  /**
   * 清空所有片段
   */
  clearSegments(): void {
    this.segments = [];
  }

  /**
   * 获取用于显示的文本行数组
   */
  getDisplayLines(): string[] {
    if (this.multiLineEnabled && !this.sameContent) {
      return this.lineContents.slice(0, this.lineCount);
    } else if (this.multiLineEnabled) {
      const result: string[] = [];
      for (let i = 0; i < this.lineCount; i++) {
        result.push(this.text);
      }
      return result;
    } else {
      return [this.text];
    }
  }

  /**
   * 根据行索引获取行样式
   */
  getLineStyle(lineIndex: number, totalLines: number): LineStyle {
    const result = new LineStyle();
    result.fontSize = this.fontSize;
    result.fontColor = this.fontColor;
    result.scale = 1;

    const middleIndex = Math.floor(totalLines / 2);

    switch (this.specialLineType) {
      case 'middle-large':
        if (lineIndex === middleIndex) {
          result.scale = this.middleLineScale;
        }
        break;

      case 'first-color':
        if (lineIndex === 0) {
          result.fontColor = this.specialLineColor;
        }
        break;

      case 'gradient-size':
        // 中间大，两边小
        const distanceFromMiddle = Math.abs(lineIndex - middleIndex);
        result.scale = 1 - (distanceFromMiddle / totalLines) * 0.4;
        break;

      case 'alternate-color':
        if (lineIndex % 2 === 1) {
          result.fontColor = this.specialLineColor;
        }
        break;

      case 'rainbow':
        const rainbowColors = ['#FF0000', '#FF7F00', '#FFFF00', '#00FF00', '#0000FF', '#4B0082', '#9400D3'];
        result.fontColor = rainbowColors[lineIndex % rainbowColors.length];
        break;
    }

    return result;
  }

  /**
   * 导出配置为JSON
   */
  toJSON(): string {
    return JSON.stringify({
      // 基础内容
      text: this.text,
      useAdvancedMode: this.useAdvancedMode,
      
      // 字体设置
      fontSize: this.fontSize,
      fontColor: this.fontColor,
      fontWeight: this.fontWeight,
      fontStyle: this.fontStyle,
      fontFamily: this.fontFamily,
      decorationType: this.decorationType,
      letterSpacing: this.letterSpacing,
      lineSpacing: this.lineSpacing,
      hasShadow: this.hasShadow,
      
      // 渐变设置
      gradientEnabled: this.gradientEnabled,
      gradientColors: this.gradientColors,
      gradientDirection: this.gradientDirection,
      
      // 背景设置
      backgroundType: this.backgroundType,
      backgroundColor: this.backgroundColor,
      backgroundImage: this.backgroundImage,
      backgroundVideo: this.backgroundVideo,
      backgroundOpacity: this.backgroundOpacity,
      backgroundBlur: this.backgroundBlur,
      
      // 滚动设置
      direction: this.direction,
      scrollSpeed: this.scrollSpeed,
      
      // 动画设置
      animationType: this.animationType,
      isBlinking: this.isBlinking,
      blinkSpeed: this.blinkSpeed,
      
      // LED 设置
      ledEnabled: this.ledEnabled,
      ledDensity: this.ledDensity,
      ledShape: this.ledShape,
      ledSpacing: this.ledSpacing,
      
      // 粒子设置
      particleEnabled: this.particleEnabled,
      particleType: this.particleType,
      
      // 多行设置
      multiLineEnabled: this.multiLineEnabled,
      lineCount: this.lineCount,
      sameContent: this.sameContent,
      lineContents: this.lineContents,
      specialLineType: this.specialLineType,
      specialLineColor: this.specialLineColor,
      middleLineScale: this.middleLineScale,
      
      // 系统设置
      orientationLock: this.orientationLock,
      keepScreenOn: this.keepScreenOn
    });
  }

  /**
   * 从JSON导入配置
   */
  static fromJSON(json: string): BarrageConfig {
    try {
      const data = JSON.parse(json) as Partial<BarrageConfig>;
      return new BarrageConfig(data);
    } catch (e) {
      const error = e as Error;
      console.error('Failed to parse BarrageConfig from JSON:', error.message);
      return new BarrageConfig();
    }
  }

  /**
   * 重置为默认值
   */
  reset(): void {
    const defaultConfig = new BarrageConfig();
    defaultConfig.copyTo(this);
  }

  /**
   * 复制配置
   */
  clone(): BarrageConfig {
    const cloned = new BarrageConfig();
    this.copyTo(cloned);
    return cloned;
  }

  /**
   * 从另一个配置复制属性
   */
  copyFrom(source: BarrageConfig | Partial<BarrageConfig>): void {
    if (source instanceof BarrageConfig) {
      source.copyTo(this);
    } else {
      this.copyFromPartial(source);
    }
  }

  /**
   * 从部分配置复制属性
   */
  private copyFromPartial(source: Partial<BarrageConfig>): void {
    if (source.text !== undefined) this.text = source.text;
    if (source.useAdvancedMode !== undefined) this.useAdvancedMode = source.useAdvancedMode;
    if (source.fontSize !== undefined) this.fontSize = source.fontSize;
    if (source.fontColor !== undefined) this.fontColor = source.fontColor;
    if (source.fontWeight !== undefined) this.fontWeight = source.fontWeight;
    if (source.fontStyle !== undefined) this.fontStyle = source.fontStyle;
    if (source.fontFamily !== undefined) this.fontFamily = source.fontFamily;
    if (source.decorationType !== undefined) this.decorationType = source.decorationType;
    if (source.letterSpacing !== undefined) this.letterSpacing = source.letterSpacing;
    if (source.lineSpacing !== undefined) this.lineSpacing = source.lineSpacing;
    if (source.hasShadow !== undefined) this.hasShadow = source.hasShadow;
    if (source.gradientEnabled !== undefined) this.gradientEnabled = source.gradientEnabled;
    if (source.gradientDirection !== undefined) this.gradientDirection = source.gradientDirection;
    if (source.backgroundType !== undefined) this.backgroundType = source.backgroundType;
    if (source.backgroundColor !== undefined) this.backgroundColor = source.backgroundColor;
    if (source.backgroundImage !== undefined) this.backgroundImage = source.backgroundImage;
    if (source.backgroundVideo !== undefined) this.backgroundVideo = source.backgroundVideo;
    if (source.backgroundOpacity !== undefined) this.backgroundOpacity = source.backgroundOpacity;
    if (source.backgroundBlur !== undefined) this.backgroundBlur = source.backgroundBlur;
    if (source.direction !== undefined) this.direction = source.direction;
    if (source.scrollSpeed !== undefined) this.scrollSpeed = source.scrollSpeed;
    if (source.animationType !== undefined) this.animationType = source.animationType;
    if (source.isBlinking !== undefined) this.isBlinking = source.isBlinking;
    if (source.blinkSpeed !== undefined) this.blinkSpeed = source.blinkSpeed;
    if (source.ledEnabled !== undefined) this.ledEnabled = source.ledEnabled;
    if (source.ledDensity !== undefined) this.ledDensity = source.ledDensity;
    if (source.ledShape !== undefined) this.ledShape = source.ledShape;
    if (source.ledSpacing !== undefined) this.ledSpacing = source.ledSpacing;
    if (source.particleEnabled !== undefined) this.particleEnabled = source.particleEnabled;
    if (source.particleType !== undefined) this.particleType = source.particleType;
    if (source.orientationLock !== undefined) this.orientationLock = source.orientationLock;
    if (source.keepScreenOn !== undefined) this.keepScreenOn = source.keepScreenOn;
    if (source.multiLineEnabled !== undefined) this.multiLineEnabled = source.multiLineEnabled;
    if (source.lineCount !== undefined) this.lineCount = source.lineCount;
    if (source.sameContent !== undefined) this.sameContent = source.sameContent;
    if (source.specialLineType !== undefined) this.specialLineType = source.specialLineType;
    if (source.specialLineColor !== undefined) this.specialLineColor = source.specialLineColor;
    if (source.middleLineScale !== undefined) this.middleLineScale = source.middleLineScale;

    // 处理数组
    if (source.gradientColors !== undefined) {
      this.gradientColors = source.gradientColors;
    }
    if (source.segments !== undefined) {
      this.segments = source.segments;
    }
    if (source.lineContents !== undefined) {
      this.lineContents = source.lineContents;
    }
  }

  /**
   * 将属性复制到目标配置
   */
  private copyTo(target: BarrageConfig): void {
    target.text = this.text;
    target.useAdvancedMode = this.useAdvancedMode;
    target.fontSize = this.fontSize;
    target.fontColor = this.fontColor;
    target.fontWeight = this.fontWeight;
    target.fontStyle = this.fontStyle;
    target.fontFamily = this.fontFamily;
    target.decorationType = this.decorationType;
    target.letterSpacing = this.letterSpacing;
    target.lineSpacing = this.lineSpacing;
    target.hasShadow = this.hasShadow;
    target.gradientEnabled = this.gradientEnabled;
    target.gradientDirection = this.gradientDirection;
    target.backgroundType = this.backgroundType;
    target.backgroundColor = this.backgroundColor;
    target.backgroundImage = this.backgroundImage;
    target.backgroundVideo = this.backgroundVideo;
    target.backgroundOpacity = this.backgroundOpacity;
    target.backgroundBlur = this.backgroundBlur;
    target.direction = this.direction;
    target.scrollSpeed = this.scrollSpeed;
    target.animationType = this.animationType;
    target.isBlinking = this.isBlinking;
    target.blinkSpeed = this.blinkSpeed;
    target.ledEnabled = this.ledEnabled;
    target.ledDensity = this.ledDensity;
    target.ledShape = this.ledShape;
    target.ledSpacing = this.ledSpacing;
    target.particleEnabled = this.particleEnabled;
    target.particleType = this.particleType;
    target.orientationLock = this.orientationLock;
    target.keepScreenOn = this.keepScreenOn;
    target.multiLineEnabled = this.multiLineEnabled;
    target.lineCount = this.lineCount;
    target.sameContent = this.sameContent;
    target.specialLineType = this.specialLineType;
    target.specialLineColor = this.specialLineColor;
    target.middleLineScale = this.middleLineScale;
    
    // 深拷贝数组
    target.segments = this.segments.map(s => s.clone());
    const gradientColorsCopy: GradientColorStop[] = [];
    for (let i = 0; i < this.gradientColors.length; i++) {
      const item = this.gradientColors[i];
      const copy: GradientColorStop = [item[0], item[1]];
      gradientColorsCopy.push(copy);
    }
    target.gradientColors = gradientColorsCopy;
    
    const lineContentsCopy: string[] = [];
    for (let i = 0; i < this.lineContents.length; i++) {
      lineContentsCopy.push(this.lineContents[i]);
    }
    target.lineContents = lineContentsCopy;
  }
}

/**
 * 颜色工具类
 */
export class ColorUtils {
  /**
   * 将 HSL 转换为 HEX
   */
  static hslToHex(h: number, s: number, l: number): string {
    s /= 100;
    l /= 100;

    const a = s * Math.min(l, 1 - l);
    const f = (n: number) => {
      const k = (n + h / 30) % 12;
      const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
      return Math.round(255 * color).toString(16).padStart(2, '0');
    };

    return `#${f(0)}${f(8)}${f(4)}`.toUpperCase();
  }

  /**
   * 将 HEX 转换为 RGB
   */
  static hexToRgb(hex: string): RgbColor | null {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (result) {
      const rgb = new RgbColor();
      rgb.r = parseInt(result[1], 16);
      rgb.g = parseInt(result[2], 16);
      rgb.b = parseInt(result[3], 16);
      return rgb;
    }
    return null;
  }

  /**
   * 将 RGB 转换为 HEX
   */
  static rgbToHex(r: number, g: number, b: number): string {
    return '#' + [r, g, b].map(x => {
      const hex = Math.max(0, Math.min(255, Math.round(x))).toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    }).join('').toUpperCase();
  }

  /**
   * 生成随机颜色
   */
  static randomColor(): string {
    return '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0').toUpperCase();
  }

  /**
   * 获取对比色 (用于确保文字可读性)
   */
  static getContrastColor(hexColor: string): string {
    const rgb = ColorUtils.hexToRgb(hexColor);
    if (!rgb) return '#FFFFFF';

    // 计算亮度
    const luminance = (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255;
    return luminance > 0.5 ? '#000000' : '#FFFFFF';
  }

  /**
   * 调整颜色亮度
   */
  static adjustBrightness(hexColor: string, percent: number): string {
    const rgb = ColorUtils.hexToRgb(hexColor);
    if (!rgb) return hexColor;

    const adjustValue = (value: number): number => {
      const adjusted = value + (255 * percent / 100);
      return Math.min(255, Math.max(0, adjusted));
    };

    return ColorUtils.rgbToHex(adjustValue(rgb.r), adjustValue(rgb.g), adjustValue(rgb.b));
  }
}

/**
 * 常用预设颜色
 */
export class PresetColors {
  // 基础色
  static readonly red: string = '#FF0000';
  static readonly orange: string = '#FF7F00';
  static readonly yellow: string = '#FFFF00';
  static readonly green: string = '#00FF00';
  static readonly cyan: string = '#00FFFF';
  static readonly blue: string = '#0000FF';
  static readonly purple: string = '#8B00FF';
  static readonly pink: string = '#FF1493';
  static readonly white: string = '#FFFFFF';
  static readonly black: string = '#000000';

  // 霓虹色
  static readonly neonPink: string = '#FF6EC7';
  static readonly neonBlue: string = '#00D4FF';
  static readonly neonGreen: string = '#39FF14';
  static readonly neonYellow: string = '#FFFF33';
  static readonly neonOrange: string = '#FF6600';
  static readonly neonPurple: string = '#BF00FF';

  // 金属色
  static readonly gold: string = '#FFD700';
  static readonly silver: string = '#C0C0C0';
  static readonly bronze: string = '#CD7F32';

  // 应援色 (常见偶像团体应援色)
  static readonly sakuraPink: string = '#FFB7C5';
  static readonly skyBlue: string = '#87CEEB';
  static readonly lemonYellow: string = '#FFF44F';
  static readonly mintGreen: string = '#98FF98';
  static readonly lavender: string = '#E6E6FA';
}

/**
 * 常用渐变预设
 */
export class PresetGradients {
  static readonly sunset: GradientColorStop[] = [['#FF512F', 0], ['#DD2476', 1]];
  static readonly ocean: GradientColorStop[] = [['#2193B0', 0], ['#6DD5ED', 1]];
  static readonly forest: GradientColorStop[] = [['#134E5E', 0], ['#71B280', 1]];
  static readonly fire: GradientColorStop[] = [['#F12711', 0], ['#F5AF19', 1]];
  static readonly purple: GradientColorStop[] = [['#8E2DE2', 0], ['#4A00E0', 1]];
  static readonly rainbow: GradientColorStop[] = [['#FF0000', 0], ['#FF7F00', 0.17], ['#FFFF00', 0.33], ['#00FF00', 0.5], ['#0000FF', 0.67], ['#4B0082', 0.83], ['#9400D3', 1]];
  static readonly gold: GradientColorStop[] = [['#F7971E', 0], ['#FFD200', 1]];
  static readonly silver: GradientColorStop[] = [['#bdc3c7', 0], ['#2c3e50', 1]];
  static readonly neon: GradientColorStop[] = [['#00FFFF', 0], ['#FF00FF', 0.5], ['#00FFFF', 1]];
  static readonly candy: GradientColorStop[] = [['#FF61D2', 0], ['#FE9090', 0.5], ['#FFCC70', 1]];
}