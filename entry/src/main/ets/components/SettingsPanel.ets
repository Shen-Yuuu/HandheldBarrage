import { BarrageConfig, BarrageSegment } from '../model/BarrageConfig';
import { CustomColorPicker } from './ColorPicker';
import { TemplateManager } from '../utils/TemplateManager';
import { FontManager, FontInfo } from '../utils/FontManager';  // 使用统一管理器
import picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

function toColorString(color: ResourceColor): string {
  if (typeof color === 'string') return color;
  if (typeof color === 'number') {
    return '#' + (color & 0xFFFFFF).toString(16).padStart(6, '0').toUpperCase();
  }
  return '#FFFFFF';
}

interface SelectOption {
  value: string;
}

@Component
export struct SettingsPanel {
  @ObjectLink config: BarrageConfig;
  @State showFontColorPicker: boolean = false;
  @State showBgColorPicker: boolean = false;
  @State editingSegmentIndex: number = -1;
  @State loadedFontCount: number = 0;
  @State templateList: string[] = [];
  @State newTemplateName: string = '';
  @State editingGradientColorIndex: number = -1;
  @State showStrokeColorPicker: boolean = false;

  // 字体相关状态
  @State fontInfoList: FontInfo[] = [];
  @State fontOptions: SelectOption[] = [];
  @State selectedFontIndex: number = 0;

  private templateManager: TemplateManager | null = null;
  private fontManager: FontManager = FontManager.getInstance();

  aboutToAppear() {
    // 初始化字体（使用统一管理器）
    this.initFonts();

    // 初始化模板管理器
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.templateManager = new TemplateManager(context);
    this.refreshTemplateList();
  }

  /**
   * 初始化字体：通过 FontManager 统一加载
   */
  private async initFonts(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;

    // 加载字体（FontManager 内部保证只加载一次）
    await this.fontManager.loadFonts(context);

    // 从 FontManager 获取字体列表
    this.fontInfoList = this.fontManager.getFontList();
    this.loadedFontCount = this.fontManager.getLoadedCount();
    this.rebuildFontOptions();
  }

  private rebuildFontOptions(): void {
    this.fontOptions = this.fontInfoList.map(
      (info: FontInfo) => ({ value: info.displayName } as SelectOption)
    );
    this.syncSelectedFontIndex();
  }

  private syncSelectedFontIndex(): void {
    const currentFamily = this.config.fontFamily;
    const idx = this.fontInfoList.findIndex(
      (info: FontInfo) => info.familyName === currentFamily
    );
    this.selectedFontIndex = idx >= 0 ? idx : 0;
  }

  private getCurrentFontDisplayName(): string {
    if (this.selectedFontIndex >= 0 && this.selectedFontIndex < this.fontInfoList.length) {
      return this.fontInfoList[this.selectedFontIndex].displayName;
    }
    return this.config.fontFamily;
  }

  private onFontSelected(index: number): void {
    if (index >= 0 && index < this.fontInfoList.length) {
      this.selectedFontIndex = index;
      this.config.fontFamily = this.fontInfoList[index].familyName;
    }
  }

  private getDisplayNameForFamily(familyName: string): string {
    return this.fontManager.getDisplayName(familyName);
  }

  private getFontWeightValue(fontWeight: FontWeight): number {
    switch (fontWeight) {
      case FontWeight.Lighter: return 100;
      case FontWeight.Normal: return 400;
      case FontWeight.Regular: return 400;
      case FontWeight.Medium: return 500;
      case FontWeight.Bold: return 700;
      case FontWeight.Bolder: return 900;
      default: return 400;
    }
  }

  private numberToFontWeight(value: number): FontWeight {
    if (value <= 100) return FontWeight.Lighter;
    if (value <= 400) return FontWeight.Normal;
    if (value <= 500) return FontWeight.Medium;
    if (value <= 700) return FontWeight.Bold;
    return FontWeight.Bolder;
  }

  async refreshTemplateList() {
    if (this.templateManager) {
      this.templateList = await this.templateManager.getAllTemplates();
    }
  }

  async saveTemplateWithName(name: string) {
    if (this.templateManager && name) {
      await this.templateManager.saveTemplate(name, this.config);
      promptAction.showToast({ message: '模板保存成功' });
      this.refreshTemplateList();
    }
  }

  async loadTemplate(name: string) {
    if (this.templateManager) {
      const loaded = await this.templateManager.loadTemplate(name);
      if (loaded) {
        this.config.copyFrom(loaded);
        this.syncSelectedFontIndex();
        promptAction.showToast({ message: `已加载模板: ${name}` });
      }
    }
  }

  async deleteTemplate(name: string) {
    if (this.templateManager) {
      await this.templateManager.deleteTemplate(name);
      this.refreshTemplateList();
      promptAction.showToast({ message: '模板已删除' });
    }
  }

  /**
   * 导入自定义字体 — 通过 FontManager 统一注册
   */
  async pickCustomFont() {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = ['*.ttf', '*.otf'];
      const documentViewPicker = new picker.DocumentViewPicker();
      const result = await documentViewPicker.select(documentSelectOptions);

      if (result && result.length > 0) {
        const uri = result[0];
        console.info('[SettingsPanel] Selected font file: ' + uri);
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const timestamp = Date.now();
        const familyName = `自定义字体_${timestamp}`;
        const targetPath = `${context.filesDir}/custom_font_${timestamp}.ttf`;

        // 复制文件
        const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const dstFile = fs.openSync(targetPath,
          fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        const buf = new ArrayBuffer(4096);
        let len = 0;
        while ((len = fs.readSync(srcFile.fd, buf)) > 0) {
          fs.writeSync(dstFile.fd, buf, { length: len });
        }
        fs.closeSync(srcFile);
        fs.closeSync(dstFile);

        // 通过 FontManager 注册
        const success = this.fontManager.registerCustomFont(familyName, targetPath);
        if (success) {
          // 刷新列表
          this.fontInfoList = this.fontManager.getFontList();
          this.loadedFontCount = this.fontManager.getLoadedCount();
          this.rebuildFontOptions();

          // 自动选中
          if (!this.config.useAdvancedMode) {
            this.config.fontFamily = familyName;
            this.syncSelectedFontIndex();
          }
          promptAction.showToast({ message: '字体导入成功' });
        } else {
          promptAction.showToast({ message: '字体注册失败' });
        }
      }
    } catch (err) {
      console.error('Pick font failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: '字体导入失败: ' + JSON.stringify(err) });
    }
  }

  async pickImage() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris.length > 0) {
        this.config.backgroundImage = photoSelectResult.photoUris[0];
      }
    } catch (err) {
      console.error('PhotoViewPicker failed: ' + JSON.stringify(err));
    }
  }

  private closeAllColorPickers(): void {
    this.showFontColorPicker = false;
    this.showBgColorPicker = false;
    this.showStrokeColorPicker = false;
    this.editingGradientColorIndex = -1;
  }

  // ==================== build 方法与上一版 SettingsPanel 完全相同 ====================
  // 直接复用上一版的 build() 和所有 @Builder 方法
  // 唯一区别是不再有 loadRawFileFonts() 方法，改用 initFonts()

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text('弹幕内容').fontSize(16).fontWeight(FontWeight.Bold).width('100%')

        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.config.useAdvancedMode })
            .onChange((isOn) => this.config.useAdvancedMode = isOn)
          Text('高级模式 (多样式)').margin({ left: 10 })
        }.width('100%')

        if (!this.config.useAdvancedMode) {
          TextArea({ text: this.config.text, placeholder: '输入弹幕内容' })
            .onChange((value) => this.config.text = value)
            .height(100)
            .width('100%')
        } else {
          this.buildAdvancedSegments()
        }

        if (!this.config.useAdvancedMode) {
          this.buildSimpleFontSettings()
        }

        this.buildLEDSettings()
        this.buildEffectSettings()
        this.buildBackgroundSettings()
        this.buildAnimationSettings()
        this.buildPresetTemplates()
        this.buildTemplateManagement()

        Text('全屏设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 20 })
        Row() {
          Text('屏幕亮度').width(70)
          Slider({ value: this.config.brightness * 100, min: 10, max: 100 })
            .onChange((value) => this.config.brightness = value / 100)
            .layoutWeight(1)
          Text((this.config.brightness * 100).toFixed(0) + '%').width(45)
        }.width('100%')

        Button('恢复默认设置')
          .width('100%')
          .margin({ top: 20, bottom: 30 })
          .backgroundColor('#E53935')
          .fontColor(Color.White)
          .onClick(() => {
            this.config.reset();
            this.syncSelectedFontIndex();
            this.closeAllColorPickers();
            promptAction.showToast({ message: '已恢复默认设置' });
          })
      }
      .padding(20)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }

  // 以下 @Builder 方法与上一版完全一致，直接复用
  @Builder
  buildAdvancedSegments() {
    Column({ space: 10 }) {
      ForEach(this.config.segments, (segment: BarrageSegment, index: number) => {
        Column({ space: 8 }) {
          Row() {
            TextInput({ text: segment.text, placeholder: '片段内容' })
              .layoutWeight(1)
              .onChange((value) => segment.text = value)
            Button('X')
              .fontColor(Color.Red)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.config.segments.splice(index, 1);
              })
          }
          Row({ space: 10 }) {
            Circle().width(20).height(20).fill(segment.fontColor)
              .onClick(() => {
                this.editingSegmentIndex = this.editingSegmentIndex === index ? -1 : index;
              })
            Slider({ value: segment.fontSize, min: 10, max: 300 })
              .layoutWeight(1)
              .onChange((value) => segment.fontSize = value)
            Row() {
              Toggle({ type: ToggleType.Checkbox, isOn: segment.fontStyle === FontStyle.Italic })
                .onChange((isOn) => segment.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
              Text('斜体').fontSize(12)
              Toggle({ type: ToggleType.Checkbox, isOn: segment.hasShadow })
                .onChange((isOn) => segment.hasShadow = isOn)
              Text('阴影').fontSize(12)
            }
          }
          Row({ space: 5 }) {
            Select(this.fontOptions)
              .value(this.getDisplayNameForFamily(segment.fontFamily))
              .onSelect((idx: number) => {
                if (idx >= 0 && idx < this.fontInfoList.length) {
                  segment.fontFamily = this.fontInfoList[idx].familyName;
                }
              })
              .layoutWeight(1)
            Select([{ value: '无装饰' }, { value: '下划线' }, { value: '删除线' }])
              .value(segment.decorationType === TextDecorationType.Underline ? '下划线' :
                (segment.decorationType === TextDecorationType.LineThrough ? '删除线' : '无装饰'))
              .onSelect((idx: number) => {
                if (idx === 0) segment.decorationType = TextDecorationType.None;
                else if (idx === 1) segment.decorationType = TextDecorationType.Underline;
                else if (idx === 2) segment.decorationType = TextDecorationType.LineThrough;
              })
              .layoutWeight(1)
          }
          if (this.editingSegmentIndex === index) {
            CustomColorPicker({
              selectedColor: toColorString(segment.fontColor),
              onChange: (color) => segment.fontColor = color
            })
          }
        }.padding(10).backgroundColor('#F5F5F5').borderRadius(8)
      })
      Button('+ 添加文本片段')
        .onClick(() => {
          const s = new BarrageSegment();
          s.text = '';
          s.fontColor = this.config.fontColor;
          s.fontSize = this.config.fontSize;
          s.fontWeight = this.config.fontWeight;
          s.fontStyle = this.config.fontStyle;
          s.fontFamily = this.config.fontFamily;
          this.config.segments = this.config.segments.concat([s]);
        })
        .width('100%')
    }
  }

  @Builder
  buildSimpleFontSettings() {
    Text('字体设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
    Row() {
      Text('大小').width(50)
      Slider({ value: this.config.fontSize, min: 10, max: 300 })
        .onChange((v) => this.config.fontSize = v).layoutWeight(1)
      Text(this.config.fontSize.toFixed(0)).width(40)
    }.width('100%')
    Row() {
      Text('字重').width(50)
      Slider({ value: this.getFontWeightValue(this.config.fontWeight), min: 100, max: 900, step: 100 })
        .onChange((v) => this.config.fontWeight = this.numberToFontWeight(v)).layoutWeight(1)
      Text(this.getFontWeightValue(this.config.fontWeight).toFixed(0)).width(40)
    }.width('100%')
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.fontStyle === FontStyle.Italic })
        .onChange((isOn) => this.config.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
      Text('斜体').margin({ left: 5, right: 15 })
      Toggle({ type: ToggleType.Switch, isOn: this.config.hasShadow })
        .onChange((isOn) => this.config.hasShadow = isOn)
      Text('阴影').margin({ left: 5, right: 15 })
      Toggle({ type: ToggleType.Switch, isOn: this.config.mirrorMode })
        .onChange((isOn) => this.config.mirrorMode = isOn)
      Text('镜像').margin({ left: 5 })
    }.width('100%')
    Row() {
      Text('字间距').width(60)
      Slider({ value: this.config.letterSpacing, min: 0, max: 50 })
        .onChange((v) => this.config.letterSpacing = v).layoutWeight(1)
      Text(this.config.letterSpacing.toFixed(0)).width(30)
    }.width('100%')
    Row() {
      Text('行间距').width(60)
      Slider({ value: this.config.lineSpacing, min: 0, max: 50 })
        .onChange((v) => this.config.lineSpacing = v).layoutWeight(1)
      Text(this.config.lineSpacing.toFixed(0)).width(30)
    }.width('100%')

    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.strokeEnabled })
        .onChange((isOn) => {
          this.config.strokeEnabled = isOn;
          if (!isOn) this.showStrokeColorPicker = false;
        })
      Text('文字描边').margin({ left: 10 })
    }.width('100%')

    if (this.config.strokeEnabled) {
      Column({ space: 8 }) {
        Row() {
          Text('描边宽度').width(70)
          Slider({ value: this.config.strokeWidth, min: 1, max: 10 })
            .onChange((v) => this.config.strokeWidth = v).layoutWeight(1)
          Text(this.config.strokeWidth.toFixed(0)).width(30)
        }.width('100%')
        Row() {
          Text('描边颜色').layoutWeight(1)
          Circle().width(25).height(25).fill(this.config.strokeColor)
            .stroke(Color.Gray).strokeWidth(1)
            .onClick(() => {
              this.showStrokeColorPicker = !this.showStrokeColorPicker;
              this.showFontColorPicker = false;
              this.showBgColorPicker = false;
              this.editingGradientColorIndex = -1;
            })
        }.width('100%')
        if (this.showStrokeColorPicker) {
          CustomColorPicker({
            selectedColor: this.config.strokeColor,
            onChange: (color) => this.config.strokeColor = color
          })
        }
      }.padding({ left: 20 })
    }

    Row({ space: 5 }) {
      Select(this.fontOptions)
        .value(this.getCurrentFontDisplayName())
        .onSelect((idx: number) => this.onFontSelected(idx))
        .layoutWeight(1)
      Button('导入').fontSize(12).onClick(() => this.pickCustomFont())
      if (this.loadedFontCount > 0) {
        Text(`+${this.loadedFontCount}`).fontSize(10).fontColor(Color.Gray)
      }
    }.width('100%')

    Row() {
      Text('装饰线').width(50)
      Select([{ value: '无装饰' }, { value: '下划线' }, { value: '删除线' }])
        .value(this.config.decorationType === TextDecorationType.Underline ? '下划线' :
          (this.config.decorationType === TextDecorationType.LineThrough ? '删除线' : '无装饰'))
        .onSelect((idx: number) => {
          if (idx === 0) this.config.decorationType = TextDecorationType.None;
          else if (idx === 1) this.config.decorationType = TextDecorationType.Underline;
          else if (idx === 2) this.config.decorationType = TextDecorationType.LineThrough;
        })
        .layoutWeight(1)
    }.width('100%')

    Row() {
      Text('字体颜色').layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.config.gradientEnabled })
        .onChange((isOn) => {
          this.config.gradientEnabled = isOn;
          this.closeAllColorPickers();
        })
      Text('渐变').fontSize(12).margin({ left: 5, right: 10 })
      if (!this.config.gradientEnabled) {
        Circle().width(30).height(30).fill(this.config.fontColor)
          .stroke(Color.Gray).strokeWidth(1)
          .onClick(() => {
            this.showFontColorPicker = !this.showFontColorPicker;
            this.showBgColorPicker = false;
            this.showStrokeColorPicker = false;
            this.editingGradientColorIndex = -1;
          })
      }
    }.width('100%')

    if (this.config.gradientEnabled) {
      Column({ space: 8 }) {
        Text('渐变方向').fontSize(12)
        Row() {
          Slider({ value: this.config.gradientDirection, min: 0, max: 360 })
            .onChange((v) => this.config.gradientDirection = v).layoutWeight(1)
          Text(this.config.gradientDirection.toFixed(0) + '°').width(40)
        }.width('100%')
        Row({ space: 20 }) {
          Column() {
            Text('起始色').fontSize(12)
            Circle().width(30).height(30)
              .fill(this.config.gradientColors[0][0])
              .stroke(Color.Gray).strokeWidth(1)
              .onClick(() => {
                this.editingGradientColorIndex = this.editingGradientColorIndex === 0 ? -1 : 0;
                this.showFontColorPicker = false;
                this.showBgColorPicker = false;
                this.showStrokeColorPicker = false;
              })
          }
          Column() {
            Text('终止色').fontSize(12)
            Circle().width(30).height(30)
              .fill(this.config.gradientColors[1][0])
              .stroke(Color.Gray).strokeWidth(1)
              .onClick(() => {
                this.editingGradientColorIndex = this.editingGradientColorIndex === 1 ? -1 : 1;
                this.showFontColorPicker = false;
                this.showBgColorPicker = false;
                this.showStrokeColorPicker = false;
              })
          }
        }.width('100%').justifyContent(FlexAlign.Start)
        if (this.editingGradientColorIndex >= 0) {
          CustomColorPicker({
            selectedColor: this.config.gradientColors[this.editingGradientColorIndex][0],
            onChange: (color) => {
              const nc: Array<[string, number]> = [
                [this.config.gradientColors[0][0], 0.0],
                [this.config.gradientColors[1][0], 1.0]
              ];
              nc[this.editingGradientColorIndex] =
                [color, this.editingGradientColorIndex === 0 ? 0.0 : 1.0];
              this.config.gradientColors = nc;
            }
          })
        }
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 10 })
    } else if (this.showFontColorPicker) {
      CustomColorPicker({
        selectedColor: toColorString(this.config.fontColor),
        onChange: (color) => this.config.fontColor = color
      })
    }
  }

  @Builder
  buildLEDSettings() {
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.ledEnabled })
        .onChange((isOn) => this.config.ledEnabled = isOn)
      Text('LED 仿真模式').margin({ left: 10 }).fontWeight(FontWeight.Bold)
    }.width('100%')
    if (this.config.ledEnabled) {
      Column({ space: 8 }) {
        Row() {
          Text('灯珠密度').width(60)
          Slider({ value: this.config.ledDensity, min: 2, max: 20 })
            .onChange((v) => this.config.ledDensity = v).layoutWeight(1)
        }.width('100%')
        Row() {
          Text('形状').width(60)
          Select([{ value: 'circle' }, { value: 'square' }])
            .value(this.config.ledShape)
            .onSelect((idx: number, val: string) =>
            this.config.ledShape = val as 'circle' | 'square')
        }.width('100%')
      }.padding({ left: 20 })
    }
  }

  @Builder
  buildEffectSettings() {
    Text('特效设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 10 })
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.particleEnabled })
        .onChange((isOn) => this.config.particleEnabled = isOn)
      Text('粒子特效').margin({ left: 10 })
    }.width('100%')
    if (this.config.particleEnabled) {
      Row() {
        Text('类型').width(50)
        Select([{ value: 'sparkle' }, { value: 'bubble' }, { value: 'fire' },
          { value: 'snow' }, { value: 'star' }])
          .value(this.config.particleType)
          .onSelect((idx: number, val: string) =>
          this.config.particleType = val as 'sparkle' | 'bubble' | 'fire' | 'snow' | 'star')
          .layoutWeight(1)
      }.width('100%')
    }
    Row() {
      Text('文字动画').width(70)
      Select([{ value: 'none' }, { value: 'scale' }, { value: 'rotate' },
        { value: 'jump' }, { value: 'shake' }, { value: 'wave' }])
        .value(this.config.animationType)
        .onSelect((idx: number, val: string) =>
        this.config.animationType = val as 'none' | 'scale' | 'rotate' | 'jump' | 'shake' | 'wave')
        .layoutWeight(1)
    }.width('100%')
  }

  @Builder
  buildBackgroundSettings() {
    Text('背景设置').fontWeight(FontWeight.Bold).width('100%')
    Select([{ value: 'color' }, { value: 'image' }, { value: 'video' }])
      .value(this.config.backgroundType)
      .onSelect((idx: number, val: string) =>
      this.config.backgroundType = val as 'color' | 'image' | 'video')
      .width('100%')
    if (this.config.backgroundType === 'color') {
      Row() {
        Text('背景颜色').layoutWeight(1)
        Circle().width(30).height(30).fill(this.config.backgroundColor)
          .stroke(Color.Gray).strokeWidth(1)
          .onClick(() => {
            this.showBgColorPicker = !this.showBgColorPicker;
            this.showFontColorPicker = false;
            this.showStrokeColorPicker = false;
            this.editingGradientColorIndex = -1;
          })
      }.width('100%')
      if (this.showBgColorPicker) {
        CustomColorPicker({
          selectedColor: toColorString(this.config.backgroundColor),
          onChange: (color) => this.config.backgroundColor = color
        })
      }
    } else if (this.config.backgroundType === 'image') {
      Button('选择背景图片').onClick(() => this.pickImage()).width('100%')
      if (this.config.backgroundImage) {
        Text('已选择图片').fontSize(10).fontColor(Color.Gray)
      }
    } else if (this.config.backgroundType === 'video') {
      Button('选择背景视频 (暂未实现)').enabled(false).width('100%')
    }
    if (this.config.backgroundType !== 'color') {
      Row() {
        Text('背景透明度').width(80)
        Slider({ value: this.config.backgroundOpacity * 100, min: 0, max: 100 })
          .onChange((v) => this.config.backgroundOpacity = v / 100).layoutWeight(1)
        Text((this.config.backgroundOpacity * 100).toFixed(0) + '%').width(45)
      }.width('100%')
    }
  }

  @Builder
  buildAnimationSettings() {
    Text('动画设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
    Row() {
      Text('速度').width(50)
      Slider({ value: this.config.scrollSpeed, min: 1, max: 100 })
        .onChange((v) => this.config.scrollSpeed = v).layoutWeight(1)
      Text(this.config.scrollSpeed.toFixed(0)).width(30)
    }.width('100%')
    Row() {
      Text('方向').width(50)
      Select([{ value: 'horizontal' }, { value: 'vertical' }])
        .value(this.config.direction)
        .onSelect((idx: number, val: string) =>
        this.config.direction = val as 'horizontal' | 'vertical')
        .layoutWeight(1)
    }.width('100%')
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.scrollReverse })
        .onChange((isOn) => this.config.scrollReverse = isOn)
      Text('反向滚动').margin({ left: 10 })
    }.width('100%')
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.config.isBlinking })
        .onChange((isOn) => this.config.isBlinking = isOn)
      Text('闪烁特效').margin({ left: 10 })
    }.width('100%')
    if (this.config.isBlinking) {
      Row() {
        Text('闪烁速度').width(70)
        Slider({ value: this.config.blinkSpeed, min: 1, max: 100 })
          .onChange((v) => this.config.blinkSpeed = v).layoutWeight(1)
      }.width('100%')
    }
  }

  @Builder
  buildPresetTemplates() {
    Text('预设模板').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 20 })
    Scroll() {
      Row({ space: 10 }) {
        Button('🎤 演唱会').fontSize(14).backgroundColor('#FF1493').fontColor(Color.White)
          .onClick(() => {
            this.config.loadPreset('concert');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用演唱会模板' });
          })
        Button('💪 体育').fontSize(14).backgroundColor('#00FF00').fontColor(Color.Black)
          .onClick(() => {
            this.config.loadPreset('sports');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用体育模板' });
          })
        Button('🎂 生日').fontSize(14).backgroundColor('#FFD700').fontColor(Color.Black)
          .onClick(() => {
            this.config.loadPreset('birthday');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用生日模板' });
          })
        Button('⚡ 霓虹').fontSize(14).backgroundColor('#00FFFF').fontColor(Color.Black)
          .onClick(() => {
            this.config.loadPreset('neon');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用霓虹模板' });
          })
        Button('🎄 圣诞').fontSize(14).backgroundColor('#228B22').fontColor(Color.White)
          .onClick(() => {
            this.config.loadPreset('christmas');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用圣诞模板' });
          })
        Button('🎃 万圣').fontSize(14).backgroundColor('#FF6600').fontColor(Color.Black)
          .onClick(() => {
            this.config.loadPreset('halloween');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用万圣节模板' });
          })
        Button('❤️ 浪漫').fontSize(14).backgroundColor('#FF69B4').fontColor(Color.White)
          .onClick(() => {
            this.config.loadPreset('romantic');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用浪漫模板' });
          })
        Button('🎮 游戏').fontSize(14).backgroundColor('#0D0D0D').fontColor('#00FF00')
          .onClick(() => {
            this.config.loadPreset('gaming');
            this.syncSelectedFontIndex();
            promptAction.showToast({ message: '已应用游戏模板' });
          })
      }
    }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
  }

  @Builder
  buildTemplateManagement() {
    Text('模板管理').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 20 })
    Row({ space: 10 }) {
      TextInput({ text: this.newTemplateName, placeholder: '输入模板名称' })
        .layoutWeight(1)
        .onChange((val) => this.newTemplateName = val)
      Button('保存')
        .onClick(() => {
          if (this.newTemplateName) {
            this.saveTemplateWithName(this.newTemplateName);
            this.newTemplateName = '';
          } else {
            promptAction.showToast({ message: '请输入名称' });
          }
        })
        .width(80)
    }.width('100%')
    if (this.templateList.length > 0) {
      Text('已保存的模板:').fontSize(14).margin({ top: 10 })
      List({ space: 10 }) {
        ForEach(this.templateList, (name: string) => {
          ListItem() {
            Row() {
              Text(name).layoutWeight(1).fontSize(16)
              Button('加载').fontSize(12).margin({ right: 5 })
                .onClick(() => this.loadTemplate(name))
              Button('删除').fontSize(12).backgroundColor(Color.Red)
                .onClick(() => this.deleteTemplate(name))
            }.width('100%').padding(10).backgroundColor('#FFFFFF')
            .borderRadius(8).shadow({ radius: 2, color: '#DDDDDD', offsetY: 1 })
          }
        })
      }.width('100%').height(150)
    }
  }
}