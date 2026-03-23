import { BarrageConfig, BarrageSegment } from '../model/BarrageConfig';
import { CustomColorPicker } from './ColorPicker';
import { TemplateManager } from '../utils/TemplateManager';
import { FontManager, FontInfo } from '../utils/FontManager';
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

// 预设模板配置
interface PresetInfo {
  key: string;
  emoji: string;
  name: string;
  bgColor: string;
  textColor: string;
}

const PRESET_LIST: PresetInfo[] = [
  { key: 'concert', emoji: '🎤', name: '演唱会', bgColor: '#FF1493', textColor: '#FFFFFF' },
  { key: 'sports', emoji: '💪', name: '体育', bgColor: '#00FF00', textColor: '#000000' },
  { key: 'birthday', emoji: '🎂', name: '生日', bgColor: '#FFD700', textColor: '#000000' },
  { key: 'neon', emoji: '⚡', name: '霓虹', bgColor: '#00FFFF', textColor: '#000000' },
  { key: 'christmas', emoji: '🎄', name: '圣诞', bgColor: '#228B22', textColor: '#FFFFFF' },
  { key: 'halloween', emoji: '🎃', name: '万圣', bgColor: '#FF6600', textColor: '#000000' },
  { key: 'romantic', emoji: '❤️', name: '浪漫', bgColor: '#FF69B4', textColor: '#FFFFFF' },
  { key: 'gaming', emoji: '🎮', name: '游戏', bgColor: '#0D0D0D', textColor: '#00FF00' }
];

@Component
export struct SettingsPanel {
  @ObjectLink config: BarrageConfig;
  @State currentTabIndex: number = 0;
  @State showFontColorPicker: boolean = false;
  @State showBgColorPicker: boolean = false;
  @State editingSegmentIndex: number = -1;
  @State loadedFontCount: number = 0;
  @State templateList: string[] = [];
  @State newTemplateName: string = '';
  @State editingGradientColorIndex: number = -1;
  @State showStrokeColorPicker: boolean = false;

  // 最近使用的颜色
  @State recentColors: string[] = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF'];

  // 字体相关状态
  @State fontInfoList: FontInfo[] = [];
  @State fontOptions: SelectOption[] = [];
  @State selectedFontIndex: number = 0;

  private templateManager: TemplateManager | null = null;
  private fontManager: FontManager = FontManager.getInstance();
  private tabController: TabsController = new TabsController();

  aboutToAppear() {
    this.initFonts();
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.templateManager = new TemplateManager(context);
    this.refreshTemplateList();
  }

  private async initFonts(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await this.fontManager.loadFonts(context);
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
      // 检查重名
      if (this.templateList.includes(name)) {
        promptAction.showDialog({
          title: '模板已存在',
          message: `是否覆盖模板 "${name}"？`,
          buttons: [
            { text: '取消', color: '#666666' },
            { text: '覆盖', color: '#E53935' }
          ]
        }).then((result) => {
          if (result.index === 1) {
            this.doSaveTemplate(name);
          }
        });
      } else {
        this.doSaveTemplate(name);
      }
    }
  }

  private async doSaveTemplate(name: string) {
    if (this.templateManager) {
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

        const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const dstFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        const buf = new ArrayBuffer(4096);
        let len = 0;
        while ((len = fs.readSync(srcFile.fd, buf)) > 0) {
          fs.writeSync(dstFile.fd, buf, { length: len });
        }
        fs.closeSync(srcFile);
        fs.closeSync(dstFile);

        const success = this.fontManager.registerCustomFont(familyName, targetPath);
        if (success) {
          this.fontInfoList = this.fontManager.getFontList();
          this.loadedFontCount = this.fontManager.getLoadedCount();
          this.rebuildFontOptions();

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
      promptAction.showToast({ message: '字体导入失败' });
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

  private addToRecentColors(color: string): void {
    const filtered = this.recentColors.filter(c => c !== color);
    this.recentColors = [color, ...filtered].slice(0, 6);
  }

  build() {
    Column() {
      // 标签栏
      Tabs({ barPosition: BarPosition.Start, controller: this.tabController }) {
        TabContent() {
          this.buildContentTab()
        }.tabBar(this.buildTabBar('内容', 0))

        TabContent() {
          this.buildStyleTab()
        }.tabBar(this.buildTabBar('样式', 1))

        TabContent() {
          this.buildEffectTab()
        }.tabBar(this.buildTabBar('效果', 2))

        TabContent() {
          this.buildAdvancedTab()
        }.tabBar(this.buildTabBar('高级', 3))
      }
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(48)
      .onChange((index: number) => {
        this.currentTabIndex = index;
        this.closeAllColorPickers();
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabBar(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#1890FF' : '#666666')
      if (this.currentTabIndex === index) {
        Divider()
          .width(24)
          .height(2)
          .backgroundColor('#1890FF')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 内容标签页 ====================
  @Builder
  buildContentTab() {
    Scroll() {
      Column({ space: 16 }) {
        // 模式切换
        Row() {
          Text('编辑模式').fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text('简单').fontSize(12).fontColor(this.config.useAdvancedMode ? '#999' : '#1890FF')
            Toggle({ type: ToggleType.Switch, isOn: this.config.useAdvancedMode })
              .onChange((isOn) => this.config.useAdvancedMode = isOn)
              .margin({ left: 8, right: 8 })
            Text('高级').fontSize(12).fontColor(this.config.useAdvancedMode ? '#1890FF' : '#999')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 内容输入
        if (!this.config.useAdvancedMode) {
          Column({ space: 8 }) {
            Text('弹幕内容').fontWeight(FontWeight.Medium).width('100%')
            TextArea({ text: this.config.text, placeholder: '输入弹幕内容...' })
              .onChange((value) => this.config.text = value)
              .height(120)
              .width('100%')
              .borderRadius(8)
          }
        } else {
          this.buildAdvancedSegments()
        }

        // 预设模板
        this.buildPresetSection()
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  buildPresetSection() {
    Column({ space: 12 }) {
      Text('快速预设').fontWeight(FontWeight.Medium).width('100%')

      Grid() {
        ForEach(PRESET_LIST, (preset: PresetInfo) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(preset.emoji).fontSize(24)
              Text(preset.name).fontSize(11).fontColor('#666')
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(preset.bgColor)
            .borderRadius(8)
            .onClick(() => {
              this.config.loadPreset(preset.key as 'concert' | 'sports' | 'birthday' | 'neon' |
                'christmas' | 'halloween' | 'romantic' | 'gaming');
              this.syncSelectedFontIndex();
              promptAction.showToast({ message: `已应用${preset.name}模板` });
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .height(136)
    }
  }

  @Builder
  buildAdvancedSegments() {
    Column({ space: 12 }) {
      Text('文本片段').fontWeight(FontWeight.Medium).width('100%')

      ForEach(this.config.segments, (segment: BarrageSegment, index: number) => {
        Column({ space: 8 }) {
          Row() {
            TextInput({ text: segment.text, placeholder: '片段内容' })
              .layoutWeight(1)
              .onChange((value) => segment.text = value)
            Button('X')
              .width(32)
              .height(32)
              .fontColor(Color.Red)
              .backgroundColor('#FFEBEE')
              .borderRadius(16)
              .margin({ left: 8 })
              .onClick(() => {
                this.config.segments.splice(index, 1);
              })
          }

          Row({ space: 12 }) {
            // 颜色选择（放大）
            Column({ space: 4 }) {
              Circle().width(36).height(36).fill(segment.fontColor)
                .stroke('#DDD').strokeWidth(2)
                .onClick(() => {
                  this.editingSegmentIndex = this.editingSegmentIndex === index ? -1 : index;
                })
              Text('颜色').fontSize(10).fontColor('#999')
            }

            // 字号滑块
            Column({ space: 4 }) {
              Row() {
                Text(segment.fontSize.toFixed(0)).fontSize(12).width(30)
                Slider({ value: segment.fontSize, min: 10, max: 300 })
                  .layoutWeight(1)
                  .onChange((value) => segment.fontSize = value)
              }.layoutWeight(1)
              Text('字号').fontSize(10).fontColor('#999')
            }.layoutWeight(1)
          }

          Row({ space: 8 }) {
            Toggle({ type: ToggleType.Checkbox, isOn: segment.fontStyle === FontStyle.Italic })
              .onChange((isOn) => segment.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
            Text('斜体').fontSize(12)
            Toggle({ type: ToggleType.Checkbox, isOn: segment.hasShadow })
              .onChange((isOn) => segment.hasShadow = isOn)
            Text('阴影').fontSize(12)
          }

          if (this.editingSegmentIndex === index) {
            this.buildColorPickerWithRecent(toColorString(segment.fontColor), (color: string) => {
              segment.fontColor = color;
              this.addToRecentColors(color);
            })
          }
        }
        .padding(12)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
      })

      Button('+ 添加文本片段')
        .width('100%')
        .height(44)
        .backgroundColor('#E3F2FD')
        .fontColor('#1890FF')
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
    }
  }

  // ==================== 样式标签页 ====================
  @Builder
  buildStyleTab() {
    Scroll() {
      Column({ space: 16 }) {
        if (!this.config.useAdvancedMode) {
          this.buildFontSettings()
          this.buildColorSettings()
        }
        this.buildBackgroundSettings()
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  buildFontSettings() {
    Column({ space: 12 }) {
      Text('字体设置').fontWeight(FontWeight.Medium).width('100%')

      // 字体选择
      Row({ space: 8 }) {
        Select(this.fontOptions)
          .value(this.getCurrentFontDisplayName())
          .onSelect((idx: number) => this.onFontSelected(idx))
          .layoutWeight(1)
        Button('导入')
          .fontSize(12)
          .height(36)
          .onClick(() => this.pickCustomFont())
        if (this.loadedFontCount > 0) {
          Text(`+${this.loadedFontCount}`).fontSize(10).fontColor('#1890FF')
        }
      }.width('100%')

      // 字号
      this.buildSliderRow('字号', this.config.fontSize, 10, 300, (v) => this.config.fontSize = v)

      // 字重
      this.buildSliderRow('字重', this.getFontWeightValue(this.config.fontWeight), 100, 900,
        (v) => this.config.fontWeight = this.numberToFontWeight(v), 100)

      // 字间距
      this.buildSliderRow('字间距', this.config.letterSpacing, 0, 50, (v) => this.config.letterSpacing = v)

      // 行间距
      this.buildSliderRow('行间距', this.config.lineSpacing, 0, 50, (v) => this.config.lineSpacing = v)

      // 开关选项
      Row({ space: 16 }) {
        this.buildToggleChip('斜体', this.config.fontStyle === FontStyle.Italic,
          (isOn) => this.config.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
        this.buildToggleChip('阴影', this.config.hasShadow, (isOn) => this.config.hasShadow = isOn)
        this.buildToggleChip('镜像', this.config.mirrorMode, (isOn) => this.config.mirrorMode = isOn)
      }.width('100%')

      // 装饰线
      Row() {
        Text('装饰线').width(60)
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
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildColorSettings() {
    Column({ space: 12 }) {
      Text('颜色设置').fontWeight(FontWeight.Medium).width('100%')

      // 渐变开关
      Row() {
        Text('启用渐变').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.gradientEnabled })
          .onChange((isOn) => {
            this.config.gradientEnabled = isOn;
            this.closeAllColorPickers();
          })
      }.width('100%')

      if (this.config.gradientEnabled) {
        // 渐变方向
        this.buildSliderRow('渐变方向', this.config.gradientDirection, 0, 360,
          (v) => this.config.gradientDirection = v, 1, '°')

        // 渐变颜色
        Row({ space: 24 }) {
          this.buildColorButton('起始色', this.config.gradientColors[0][0], () => {
            this.editingGradientColorIndex = this.editingGradientColorIndex === 0 ? -1 : 0;
            this.showFontColorPicker = false;
          })
          this.buildColorButton('终止色', this.config.gradientColors[1][0], () => {
            this.editingGradientColorIndex = this.editingGradientColorIndex === 1 ? -1 : 1;
            this.showFontColorPicker = false;
          })
        }.width('100%').justifyContent(FlexAlign.Start)

        if (this.editingGradientColorIndex >= 0) {
          this.buildColorPickerWithRecent(this.config.gradientColors[this.editingGradientColorIndex][0],
            (color: string) => {
              const nc: Array<[string, number]> = [
                [this.config.gradientColors[0][0], 0.0],
                [this.config.gradientColors[1][0], 1.0]
              ];
              nc[this.editingGradientColorIndex] = [color, this.editingGradientColorIndex === 0 ? 0.0 : 1.0];
              this.config.gradientColors = nc;
              this.addToRecentColors(color);
            })
        }
      } else {
        // 单色
        Row() {
          Text('字体颜色').layoutWeight(1)
          Circle().width(40).height(40).fill(this.config.fontColor)
            .stroke('#DDD').strokeWidth(2)
            .onClick(() => {
              this.showFontColorPicker = !this.showFontColorPicker;
              this.showBgColorPicker = false;
              this.showStrokeColorPicker = false;
            })
        }.width('100%')

        if (this.showFontColorPicker) {
          this.buildColorPickerWithRecent(toColorString(this.config.fontColor), (color: string) => {
            this.config.fontColor = color;
            this.addToRecentColors(color);
          })
        }
      }

      // 描边设置
      Row() {
        Text('文字描边').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.strokeEnabled })
          .onChange((isOn) => {
            this.config.strokeEnabled = isOn;
            if (!isOn) this.showStrokeColorPicker = false;
          })
      }.width('100%')

      if (this.config.strokeEnabled) {
        Column({ space: 8 }) {
          this.buildSliderRow('描边宽度', this.config.strokeWidth, 1, 10, (v) => this.config.strokeWidth = v)

          Row() {
            Text('描边颜色').layoutWeight(1)
            Circle().width(40).height(40).fill(this.config.strokeColor)
              .stroke('#DDD').strokeWidth(2)
              .onClick(() => {
                this.showStrokeColorPicker = !this.showStrokeColorPicker;
                this.showFontColorPicker = false;
                this.showBgColorPicker = false;
              })
          }.width('100%')

          if (this.showStrokeColorPicker) {
            this.buildColorPickerWithRecent(this.config.strokeColor, (color: string) => {
              this.config.strokeColor = color;
              this.addToRecentColors(color);
            })
          }
        }.padding({ left: 16 })
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildBackgroundSettings() {
    Column({ space: 12 }) {
      Text('背景设置').fontWeight(FontWeight.Medium).width('100%')

      Select([{ value: '纯色背景' }, { value: '图片背景' }])
        .value(this.config.backgroundType === 'image' ? '图片背景' : '纯色背景')
        .onSelect((idx: number) => {
          this.config.backgroundType = idx === 1 ? 'image' : 'color';
        })
        .width('100%')

      if (this.config.backgroundType === 'color') {
        Row() {
          Text('背景颜色').layoutWeight(1)
          Circle().width(40).height(40).fill(this.config.backgroundColor)
            .stroke('#DDD').strokeWidth(2)
            .onClick(() => {
              this.showBgColorPicker = !this.showBgColorPicker;
              this.showFontColorPicker = false;
              this.showStrokeColorPicker = false;
            })
        }.width('100%')

        if (this.showBgColorPicker) {
          this.buildColorPickerWithRecent(toColorString(this.config.backgroundColor), (color: string) => {
            this.config.backgroundColor = color;
            this.addToRecentColors(color);
          })
        }
      } else {
        Button('选择背景图片')
          .width('100%')
          .height(44)
          .backgroundColor('#E3F2FD')
          .fontColor('#1890FF')
          .onClick(() => this.pickImage())

        if (this.config.backgroundImage !== '') {
          Text('已选择图片').fontSize(12).fontColor('#52C41A')
        }

        this.buildSliderRow('透明度', this.config.backgroundOpacity * 100, 0, 100,
          (v) => this.config.backgroundOpacity = v / 100, 1, '%')
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  // ==================== 效果标签页 ====================
  @Builder
  buildEffectTab() {
    Scroll() {
      Column({ space: 16 }) {
        this.buildScrollSettings()
        this.buildAnimationSettings()
        this.buildParticleSettings()
        this.buildLEDSettings()
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  buildScrollSettings() {
    Column({ space: 12 }) {
      Text('滚动设置').fontWeight(FontWeight.Medium).width('100%')

      Row() {
        Text('方向').width(60)
        Select([{ value: '横向滚动' }, { value: '纵向滚动' }])
          .value(this.config.direction === 'horizontal' ? '横向滚动' : '纵向滚动')
          .onSelect((idx: number) => {
            this.config.direction = idx === 0 ? 'horizontal' : 'vertical';
          })
          .layoutWeight(1)
      }.width('100%')

      this.buildSliderRow('速度', this.config.scrollSpeed, 1, 60, (v) => this.config.scrollSpeed = v)

      Row() {
        Text('反向滚动').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.scrollReverse })
          .onChange((isOn) => this.config.scrollReverse = isOn)
      }.width('100%')
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildAnimationSettings() {
    Column({ space: 12 }) {
      Text('动画效果').fontWeight(FontWeight.Medium).width('100%')

      Row() {
        Text('文字动画').width(70)
        Select([
          { value: '无' },
          { value: '缩放' },
          { value: '旋转' },
          { value: '跳跃' },
          { value: '抖动' },
          { value: '波浪' }
        ])
          .value(this.getAnimationName(this.config.animationType))
          .onSelect((idx: number) => {
            const types: Array<'none' | 'scale' | 'rotate' | 'jump' | 'shake' | 'wave'> =
              ['none', 'scale', 'rotate', 'jump', 'shake', 'wave'];
            this.config.animationType = types[idx];
          })
          .layoutWeight(1)
      }.width('100%')

      Row() {
        Text('闪烁效果').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.isBlinking })
          .onChange((isOn) => this.config.isBlinking = isOn)
      }.width('100%')

      if (this.config.isBlinking) {
        this.buildSliderRow('闪烁速度', this.config.blinkSpeed, 1, 100, (v) => this.config.blinkSpeed = v)
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildParticleSettings() {
    Column({ space: 12 }) {
      Row() {
        Text('粒子特效').fontWeight(FontWeight.Medium).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.particleEnabled })
          .onChange((isOn) => this.config.particleEnabled = isOn)
      }.width('100%')

      if (this.config.particleEnabled) {
        Row() {
          Text('类型').width(50)
          Select([
            { value: '✨ 闪光' },
            { value: '🫧 气泡' },
            { value: '🔥 火焰' },
            { value: '❄️ 雪花' },
            { value: '⭐ 星星' }
          ])
            .value(this.getParticleName(this.config.particleType))
            .onSelect((idx: number) => {
              const types: Array<'sparkle' | 'bubble' | 'fire' | 'snow' | 'star'> =
                ['sparkle', 'bubble', 'fire', 'snow', 'star'];
              this.config.particleType = types[idx];
            })
            .layoutWeight(1)
        }.width('100%')
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildLEDSettings() {
    Column({ space: 12 }) {
      Row() {
        Text('LED 仿真').fontWeight(FontWeight.Medium).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.ledEnabled })
          .onChange((isOn) => this.config.ledEnabled = isOn)
      }.width('100%')

      if (this.config.ledEnabled) {
        this.buildSliderRow('灯珠密度', this.config.ledDensity, 2, 20, (v) => this.config.ledDensity = v)

        Row() {
          Text('形状').width(50)
          Select([{ value: '圆形' }, { value: '方形' }])
            .value(this.config.ledShape === 'circle' ? '圆形' : '方形')
            .onSelect((idx: number) => {
              this.config.ledShape = idx === 0 ? 'circle' : 'square';
            })
            .layoutWeight(1)
        }.width('100%')
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  // ==================== 高级标签页 ====================
  @Builder
  buildAdvancedTab() {
    Scroll() {
      Column({ space: 16 }) {
        this.buildScreenSettings()
        this.buildTemplateManagement()

        // 恢复默认
        Button('恢复默认设置')
          .width('100%')
          .height(44)
          .backgroundColor('#FFEBEE')
          .fontColor('#E53935')
          .margin({ top: 16 })
          .onClick(() => {
            this.config.reset();
            this.syncSelectedFontIndex();
            this.closeAllColorPickers();
            promptAction.showToast({ message: '已恢复默认设置' });
          })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  buildScreenSettings() {
    Column({ space: 12 }) {
      Text('全屏设置').fontWeight(FontWeight.Medium).width('100%')

      this.buildSliderRow('屏幕亮度', this.config.brightness * 100, 10, 100,
        (v) => this.config.brightness = v / 100, 1, '%')

      Row() {
        Text('屏幕常亮').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.config.keepScreenOn })
          .onChange((isOn) => this.config.keepScreenOn = isOn)
      }.width('100%')
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  buildTemplateManagement() {
    Column({ space: 12 }) {
      Text('模板管理').fontWeight(FontWeight.Medium).width('100%')

      Row({ space: 8 }) {
        TextInput({ text: this.newTemplateName, placeholder: '输入模板名称' })
          .layoutWeight(1)
          .height(40)
          .onChange((val) => this.newTemplateName = val)
        Button('保存')
          .height(40)
          .onClick(() => {
            if (this.newTemplateName) {
              this.saveTemplateWithName(this.newTemplateName);
              this.newTemplateName = '';
            } else {
              promptAction.showToast({ message: '请输入名称' });
            }
          })
      }.width('100%')

      if (this.templateList.length > 0) {
        Text('已保存的模板').fontSize(12).fontColor('#999').width('100%')

        List({ space: 8 }) {
          ForEach(this.templateList, (name: string) => {
            ListItem() {
              Row() {
                Text(name).layoutWeight(1).fontSize(14)
                Button('加载')
                  .fontSize(11)
                  .height(28)
                  .backgroundColor('#E3F2FD')
                  .fontColor('#1890FF')
                  .margin({ right: 8 })
                  .onClick(() => this.loadTemplate(name))
                Button('删除')
                  .fontSize(11)
                  .height(28)
                  .backgroundColor('#FFEBEE')
                  .fontColor('#E53935')
                  .onClick(() => this.deleteTemplate(name))
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .shadow({ radius: 2, color: '#0000001A', offsetY: 1 })
            }
          })
        }.width('100%').height(160)
      }
    }
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  // ==================== 通用组件 ====================
  @Builder
  buildSliderRow(label: string, value: number, min: number, max: number,
    onChange: (value: number) => void, step: number = 1, unit: string = '') {
    Row() {
      Text(label).width(70).fontSize(14)
      Slider({ value: value, min: min, max: max, step: step })
        .layoutWeight(1)
        .onChange(onChange)
      Text(value.toFixed(0) + unit).width(45).fontSize(12).textAlign(TextAlign.End)
    }.width('100%')
  }

  @Builder
  buildToggleChip(label: string, isOn: boolean, onChange: (isOn: boolean) => void) {
    Row({ space: 4 }) {
      Toggle({ type: ToggleType.Checkbox, isOn: isOn })
        .onChange(onChange)
        .width(16)
        .height(16)
      Text(label).fontSize(12)
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor(isOn ? '#E3F2FD' : '#F5F5F5')
    .borderRadius(16)
  }

  @Builder
  buildColorButton(label: string, color: string, onClick: () => void) {
    Column({ space: 4 }) {
      Circle().width(44).height(44).fill(color)
        .stroke('#DDD').strokeWidth(2)
        .onClick(onClick)
      Text(label).fontSize(11).fontColor('#666')
    }
  }

  @Builder
  buildColorPickerWithRecent(currentColor: string, onChange: (color: string) => void) {
    Column({ space: 8 }) {
      // 最近使用的颜色
      Row({ space: 8 }) {
        Text('最近').fontSize(11).fontColor('#999').width(30)
        ForEach(this.recentColors, (color: string) => {
          Circle()
            .width(28)
            .height(28)
            .fill(color)
            .stroke(color === currentColor ? '#1890FF' : '#DDD')
            .strokeWidth(color === currentColor ? 3 : 1)
            .onClick(() => onChange(color))
        })
      }.width('100%')

      // 完整颜色选择器
      CustomColorPicker({
        selectedColor: currentColor,
        onChange: onChange
      })
    }
  }

  // ==================== 辅助方法 ====================
  private getAnimationName(type: string): string {
    const names: Record<string, string> = {
      'none': '无', 'scale': '缩放', 'rotate': '旋转',
      'jump': '跳跃', 'shake': '抖动', 'wave': '波浪'
    };
    return names[type] || '无';
  }

  private getParticleName(type: string): string {
    const names: Record<string, string> = {
      'sparkle': '✨ 闪光', 'bubble': '🫧 气泡', 'fire': '🔥 火焰',
      'snow': '❄️ 雪花', 'star': '⭐ 星星'
    };
    return names[type] || '✨ 闪光';
  }
}
