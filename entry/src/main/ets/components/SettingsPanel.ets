import { BarrageConfig, BarrageSegment } from '../model/BarrageConfig';
import { CustomColorPicker } from './ColorPicker';
import { TemplateManager } from '../utils/TemplateManager';
import picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import font from '@ohos.font';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

/**
 * 将 ResourceColor 转换为 string
 */
function toColorString(color: ResourceColor): string {
  if (typeof color === 'string') {
    return color;
  } else if (typeof color === 'number') {
    // 将数字颜色转换为十六进制字符串
    return '#' + (color & 0xFFFFFF).toString(16).padStart(6, '0').toUpperCase();
  }
  return '#FFFFFF'; // 默认颜色
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
  @State fontOptions: SelectOption[] = [
    { value: 'HarmonyOS Sans' },
    { value: 'serif' },
    { value: 'monospace' }
  ];
  @State loadedFontCount: number = 0;
  @State templateList: string[] = [];
  @State newTemplateName: string = '';
  @State editingGradientColorIndex: number = -1;
  private templateManager: TemplateManager | null = null;

  // Static map for known fonts (English Filename -> Chinese Display Name)
  private staticFontMap: Record<string, string> = {
    'FangSong_GB2312': '仿宋_GB2312',
    'ChuangYiJianKaiTi': '创艺简楷体',
    'KaiTi_GB2312': '楷体_GB2312',
    'WangHanZongCuKaiTi': '王汉宗粗楷体',
    'JingDianZhongYuan': '经典中圆',
    'JingDianSongTi': '经典宋体',
    'JingDianXiYuan': '经典细圆',
    'JingDianZongYi': '经典综艺',
    'JingDianQuTi': '经典趣体',
    'MiNiJianXingKai': '迷你简行楷'
  };
  // Dynamic maps for lookup
  private displayNameToFamilyName: Record<string, string> = {};
  private familyNameToDisplayName: Record<string, string> = {};

  aboutToAppear() {
    // Init default fonts
    this.registerMap('HarmonyOS Sans', 'HarmonyOS Sans');
    this.registerMap('serif', 'serif');
    this.registerMap('monospace', 'monospace');

    this.loadRawFileFonts();
    
    // Init Template Manager
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.templateManager = new TemplateManager(context);
    this.refreshTemplateList();
  }

  /**
   * 将 FontWeight 枚举转换为数字值
   */
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

  /**
   * 将数字值转换为 FontWeight 枚举
   */
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

  async saveTemplate() {
    if (!this.templateManager) return;
    try {
      const res = await promptAction.showDialog({
        title: '保存模板',
        message: '请输入模板名称',
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '保存', color: '#0000FF' }
        ],
      });
      
      // Note: promptAction.showDialog doesn't support input directly in API 9/10 easily without custom dialog
      // For simplicity in this iteration, we'll use a timestamp or generic name if we can't get input easily
      // Or we can use a TextInput in the UI to bind a "New Template Name" variable.
      // Let's assume we add a TextInput for template name in the UI.
    } catch (err) {
      // Cancelled
    }
  }
  
  // Simplified save for now - we will add UI for it
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
        // Copy properties to current config
        this.config.copyFrom(loaded);
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

  registerMap(familyName: string, displayName: string) {
    this.displayNameToFamilyName[displayName] = familyName;
    this.familyNameToDisplayName[familyName] = displayName;
  }

  async loadRawFileFonts() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceManager = context.resourceManager;
      // List files in 'fonts' directory of rawfile
      const files = await resourceManager.getRawFileList('fonts');
      console.info(`Barrage: Found ${files.length} font files in rawfile/fonts`);
      let fileIndex = 0;
      const newOptions: SelectOption[] = [];

      for (const filename of files) {
        console.info(`Barrage: Processing file: ${filename}`);
        fileIndex++;
        // Normalize: trim spaces and use regex to find extension (case-insensitive, allow spaces before dot)
        const cleaned = filename.trim();
        const matchResult = cleaned.match(/(.+?)\s*\.(ttf|otf)$/i);
        if (!matchResult) {
          console.warn(`Barrage: Skip non-font or malformed filename: ${filename}`);
          continue;
        }
        let fontName = matchResult[1]; // This is now the English filename (e.g. FangSong_GB2312)
        const extension = `.${matchResult[2].toLowerCase()}`;

        // Determine Display Name (Chinese)
        let displayName = fontName;
        if (this.staticFontMap[fontName]) {
          displayName = this.staticFontMap[fontName];
        }

        console.info(`Barrage: Parsed fontName (Family): ${fontName}, DisplayName: ${displayName}`);

        // Avoid duplicates
        if (this.fontOptions.some(opt => opt.value === displayName) ||
        newOptions.some(opt => opt.value === displayName)) {
          console.info(`Barrage: Font ${displayName} already exists in options.`);
          continue;
        }

        // Use safe ASCII filename for storage to avoid path issues
        const safeTargetName = `font_asset_${new Date().getTime()}_${fileIndex}${extension}`;
        const targetPath = `${context.filesDir}/${safeTargetName}`;

        try {
          // Read from rawfile and write to filesDir
          console.info(`Barrage: Reading rawfile fonts/${filename}`);
          const fileData = await resourceManager.getRawFileContent(`fonts/${filename}`);
          console.info(`Barrage: Writing to ${targetPath}, size: ${fileData.byteLength}`);

          const file = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
          // Ensure we write only the valid data range from the buffer
          fs.writeSync(file.fd, fileData.buffer, { offset: fileData.byteOffset, length: fileData.byteLength });
          fs.closeSync(file);

          // Register Font with Display Name (Chinese) as Family Name
          // This ensures the UI and internal logic use the same name
          console.info(`Barrage: Registering font family '${displayName}' from src 'file://${targetPath}'`);
          this.getUIContext().getFont().registerFont({
            familyName: displayName,
            familySrc: `file://${targetPath}`
          });

          newOptions.push({ value: displayName });

          console.info(`Barrage: Successfully registered font ${displayName}`);
        } catch (e) {
          console.error(`Barrage: Failed to register font ${filename}: ${JSON.stringify(e)}`);
        }
      }
      if (newOptions.length > 0) {
        this.fontOptions = [...this.fontOptions, ...newOptions];
        this.loadedFontCount = newOptions.length;
        
        // Auto select the first loaded font if not in advanced mode and using default
        if (!this.config.useAdvancedMode && newOptions.length > 0) {
           // Use the Display Name (value) from the option
           this.config.fontFamily = newOptions[0].value;
        }
      }
    } catch (err) {
      console.error('Barrage: Failed to load rawfile fonts: ' + JSON.stringify(err));
    }
  }

  async pickCustomFont() {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = ['.ttf', '.otf'];
      const documentViewPicker = new picker.DocumentViewPicker();
      const documentSelectResult = await documentViewPicker.select(documentSelectOptions);

      if (documentSelectResult.length > 0) {
        const uri = documentSelectResult[0];
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const fontName = `CustomFont_${new Date().getTime()}`;
        const targetPath = `${context.filesDir}/${fontName}.ttf`;

        const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const targetFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

        // Copy file content
        let buf = new ArrayBuffer(4096);
        let len = 0;
        while ((len = fs.readSync(file.fd, buf)) > 0) {
          fs.writeSync(targetFile.fd, buf, { length: len });
        }

        fs.closeSync(file);
        fs.closeSync(targetFile);

        // Register Font
        this.getUIContext().getFont().registerFont({
          familyName: fontName,
          familySrc: `file://${targetPath}`
        });

        // Update Options
        this.fontOptions.push({ value: fontName });

        // Auto select if not in advanced mode
        if (!this.config.useAdvancedMode) {
          this.config.fontFamily = fontName;
        }
      }
    } catch (err) {
      console.error('Pick font failed: ' + JSON.stringify(err));
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
        const uri = photoSelectResult.photoUris[0];
        console.info(`Barrage: Picked background image: ${uri}`);
        this.config.backgroundImage = uri;
      }
    } catch (err) {
      console.error('PhotoViewPicker failed with err: ' + JSON.stringify(err));
    }
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        // Text Input
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
          // Advanced Mode: Segment List
          Column({ space: 10 }) {
            ForEach(this.config.segments, (segment: BarrageSegment, index: number) => {
              Column() {
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
                  // Color
                  Circle().width(20).height(20).fill(segment.fontColor)
                    .onClick(() => {
                      this.editingSegmentIndex = this.editingSegmentIndex === index ? -1 : index;
                    })

                  // Size
                  Slider({ value: segment.fontSize, min: 10, max: 300 })
                    .layoutWeight(1)
                    .onChange((value) => segment.fontSize = value)

                  // Style
                  Row() {
                    Toggle({ type: ToggleType.Checkbox, isOn: segment.fontStyle === FontStyle.Italic })
                      .onChange((isOn) => segment.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
                    Text('斜体').fontSize(12)

                    Toggle({ type: ToggleType.Checkbox, isOn: segment.hasShadow })
                      .onChange((isOn) => segment.hasShadow = isOn)
                    Text('阴影').fontSize(12)
                  }
                }

                Row() {
                  Select(this.fontOptions)
                    .value(this.familyNameToDisplayName[segment.fontFamily] || segment.fontFamily)
                    .onSelect((idx, val) => {
                      segment.fontFamily = this.displayNameToFamilyName[val] || val;
                    })

                  Select([{ value: '无装饰' }, { value: '下划线' }, { value: '删除线' }])
                    .value(segment.decorationType === TextDecorationType.Underline ? '下划线' :
                      (segment.decorationType === TextDecorationType.LineThrough ? '删除线' : '无装饰'))
                    .onSelect((idx, val) => {
                      if (idx === 0) {
                        segment.decorationType = TextDecorationType.None;
                      } else if (idx ===
                        1) {
                        segment.decorationType = TextDecorationType.Underline;
                      } else if (idx ===
                        2) {
                        segment.decorationType = TextDecorationType.LineThrough;
                      }
                    })
                    .layoutWeight(1)
                }

                if (this.editingSegmentIndex === index) {
                  CustomColorPicker({
                    selectedColor: toColorString(segment.fontColor),
                    onChange: (color) => segment.fontColor = color
                  })
                }
              }
              .padding(10)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
            })

            Button('+ 添加文本片段')
              .onClick(() => {
                const newSegment = new BarrageSegment();
                newSegment.text = '';
                newSegment.fontColor = this.config.fontColor;
                newSegment.fontSize = this.config.fontSize;
                newSegment.fontWeight = this.config.fontWeight;
                newSegment.fontStyle = this.config.fontStyle;
                // Re-assign array to trigger update
                this.config.segments = this.config.segments.concat([newSegment]);
              })
              .width('100%')
          }
        }

        // Font Settings (Global)
        if (!this.config.useAdvancedMode) {
          Text('字体设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
          Row() {
            Text('大小').width(50)
            Slider({ value: this.config.fontSize, min: 10, max: 300 })
              .onChange((value) => this.config.fontSize = value)
              .layoutWeight(1)
            Text(this.config.fontSize.toFixed(0)).width(40)
          }.width('100%')

          Row() {
            Text('字重').width(50)
            Slider({
              value: this.getFontWeightValue(this.config.fontWeight),
              min: 100,
              max: 900,
              step: 100
            })
              .onChange((value) => this.config.fontWeight = this.numberToFontWeight(value))
              .layoutWeight(1)
            Text(this.getFontWeightValue(this.config.fontWeight).toFixed(0)).width(40)
          }.width('100%')

          Row() {
            Toggle({ type: ToggleType.Switch, isOn: this.config.fontStyle === FontStyle.Italic })
              .onChange((isOn) => this.config.fontStyle = isOn ? FontStyle.Italic : FontStyle.Normal)
            Text('斜体').margin({ left: 10 })

            Toggle({ type: ToggleType.Switch, isOn: this.config.hasShadow })
              .onChange((isOn) => this.config.hasShadow = isOn)
            Text('阴影').margin({ left: 10 })
          }.width('100%')

          Row() {
            Select(this.fontOptions)
              .value(this.config.fontFamily)
              .onSelect((idx, val) => this.config.fontFamily = val)
              .layoutWeight(1)

            Button('导入字体')
              .fontSize(12)
              .onClick(() => this.pickCustomFont())
              .margin({ left: 5, right: 5 })

            if (this.loadedFontCount > 0) {
              Text(`已加载${this.loadedFontCount}个字体`).fontSize(10).fontColor(Color.Gray)
            }

            Select([{ value: '无装饰' }, { value: '下划线' }, { value: '删除线' }])
              .value(this.config.decorationType === TextDecorationType.Underline ? '下划线' :
                (this.config.decorationType === TextDecorationType.LineThrough ? '删除线' : '无装饰'))
              .onSelect((idx, val) => {
                if (idx === 0) {
                  this.config.decorationType = TextDecorationType.None;
                } else if (idx ===
                  1) {
                  this.config.decorationType = TextDecorationType.Underline;
                } else if (idx ===
                  2) {
                  this.config.decorationType = TextDecorationType.LineThrough;
                }
              })
              .layoutWeight(1)
          }.width('100%')

          // Colors
          Row() {
            Text('字体颜色').layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.config.gradientEnabled })
              .onChange((isOn) => this.config.gradientEnabled = isOn)
            Text('渐变').fontSize(12).margin({ left: 5, right: 10 })

            if (!this.config.gradientEnabled) {
              Circle()
                .width(30)
                .height(30)
                .fill(this.config.fontColor)
                .stroke(Color.Gray)
                .strokeWidth(1)
                .onClick(() => {
                  this.showFontColorPicker = !this.showFontColorPicker;
                  this.showBgColorPicker = false;
                })
            }
          }.width('100%')

          if (this.config.gradientEnabled) {
            Column() {
              Text('渐变方向 (角度)').fontSize(12)
              Slider({ value: this.config.gradientDirection, min: 0, max: 360 })
                .onChange((val) => this.config.gradientDirection = val)
              
              Row({ space: 20 }) {
                Column() {
                  Text('起始色').fontSize(12)
                  Circle().width(30).height(30)
                    .fill(this.config.gradientColors[0][0])
                    .stroke(Color.Gray).strokeWidth(1)
                    .onClick(() => {
                      this.editingGradientColorIndex = 0;
                      this.showFontColorPicker = false;
                      this.showBgColorPicker = false;
                    })
                }
                
                Column() {
                  Text('终止色').fontSize(12)
                  Circle().width(30).height(30)
                    .fill(this.config.gradientColors[1][0])
                    .stroke(Color.Gray).strokeWidth(1)
                    .onClick(() => {
                      this.editingGradientColorIndex = 1;
                      this.showFontColorPicker = false;
                      this.showBgColorPicker = false;
                    })
                }
              }.width('100%').justifyContent(FlexAlign.Start).margin({ top: 5 })

              if (this.editingGradientColorIndex >= 0) {
                 CustomColorPicker({
                    selectedColor: this.config.gradientColors[this.editingGradientColorIndex][0],
                    onChange: (color) => {
                       const newColors: Array<[string, number]> = [
                         [this.config.gradientColors[0][0], 0.0],
                         [this.config.gradientColors[1][0], 1.0]
                       ];
                       newColors[this.editingGradientColorIndex] = [color, this.editingGradientColorIndex === 0 ? 0.0 : 1.0];
                       this.config.gradientColors = newColors;
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

        // LED Simulation
        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.config.ledEnabled })
            .onChange((isOn) => this.config.ledEnabled = isOn)
          Text('LED 仿真模式').margin({ left: 10 }).fontWeight(FontWeight.Bold)
        }.width('100%')

        if (this.config.ledEnabled) {
          Column() {
            Row() {
              Text('灯珠密度').width(60)
              Slider({ value: this.config.ledDensity, min: 2, max: 20 })
                .onChange((val) => this.config.ledDensity = val)
                .layoutWeight(1)
            }.width('100%')
            
            Row() {
              Text('形状').width(60)
              Select([{ value: 'circle' }, { value: 'square' }])
                .value(this.config.ledShape)
                .onSelect((idx, val) => this.config.ledShape = val as 'circle' | 'square')
            }.width('100%')
          }.padding({ left: 20 })
        }

        // Special Effects
        Text('特效设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 10 })
        
        // Particle
        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.config.particleEnabled })
            .onChange((isOn) => this.config.particleEnabled = isOn)
          Text('粒子特效').margin({ left: 10 })
        }.width('100%')

        if (this.config.particleEnabled) {
           Row() {
             Text('类型').width(50)
             Select([
               { value: 'sparkle', icon: undefined },
               { value: 'bubble', icon: undefined },
               { value: 'fire', icon: undefined },
               { value: 'snow', icon: undefined },
               { value: 'star', icon: undefined }
             ])
               .value(this.config.particleType)
               .onSelect((idx, val) => this.config.particleType = val as 'sparkle' | 'bubble' | 'fire' | 'snow' | 'star')
               .layoutWeight(1)
           }.width('100%')
        }

        // Text Animation
        Row() {
          Text('文字动画').width(70)
          Select([
            { value: 'none', icon: undefined },
            { value: 'scale', icon: undefined },
            { value: 'rotate', icon: undefined },
            { value: 'jump', icon: undefined },
            { value: 'shake', icon: undefined },
            { value: 'wave', icon: undefined }
          ])
            .value(this.config.animationType)
            .onSelect((idx, val) => this.config.animationType = val as 'none' | 'scale' | 'rotate' | 'jump' | 'shake' | 'wave')
            .layoutWeight(1)
        }.width('100%')

        Row() {
          Text('背景设置').fontWeight(FontWeight.Bold).layoutWeight(1)
        }.width('100%')
        
        Row() {
          Select([{ value: 'color' }, { value: 'image' }, { value: 'video' }])
            .value(this.config.backgroundType)
            .onSelect((idx, val) => this.config.backgroundType = val as 'color' | 'image' | 'video')
            .width('100%')
        }

        if (this.config.backgroundType === 'color') {
          Row() {
            Text('背景颜色').layoutWeight(1)
            Circle()
              .width(30)
              .height(30)
              .fill(this.config.backgroundColor)
              .stroke(Color.Gray)
              .strokeWidth(1)
              .onClick(() => {
                this.showBgColorPicker = !this.showBgColorPicker;
                this.showFontColorPicker = false;
              })
          }.width('100%')

          if (this.showBgColorPicker) {
            CustomColorPicker({
              selectedColor: toColorString(this.config.backgroundColor),
              onChange: (color) => this.config.backgroundColor = color
            })
          }
        } else if (this.config.backgroundType === 'image') {
          Button('选择背景图片')
            .onClick(() => this.pickImage())
            .width('100%')
          if (this.config.backgroundImage) {
             Text('已选择图片').fontSize(10).fontColor(Color.Gray)
          }
        } else if (this.config.backgroundType === 'video') {
           Button('选择背景视频 (暂未实现文件选择)')
             .enabled(false)
             .width('100%')
           Text('演示模式: 默认视频').fontSize(10).fontColor(Color.Gray)
           // In a real app, we would use picker.PhotoViewPicker with VIDEO_TYPE
        }

        // Animation
        Text('动画设置').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
        Row() {
          Text('速度').width(50)
          Slider({ value: this.config.scrollSpeed, min: 1, max: 100 })
            .onChange((value) => this.config.scrollSpeed = value)
            .layoutWeight(1)
        }.width('100%')

        Row() {
          Text('方向').width(50)
          Select([{ value: 'horizontal' }, { value: 'vertical' }])
            .value(this.config.direction)
            .onSelect((index, value) => {
              this.config.direction = value as 'horizontal' | 'vertical';
            })
            .layoutWeight(1)
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
              .onChange((value) => this.config.blinkSpeed = value)
              .layoutWeight(1)
          }.width('100%')
        }

        // --- Preset Templates ---
        Text('预设模板').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 20 })
        
        Scroll() {
          Row({ space: 10 }) {
            Button('🎤 演唱会')
              .fontSize(14)
              .backgroundColor('#FF1493')
              .fontColor(Color.White)
              .onClick(() => {
                this.config.loadPreset('concert');
                promptAction.showToast({ message: '已应用演唱会模板' });
              })
            
            Button('💪 体育')
              .fontSize(14)
              .backgroundColor('#00FF00')
              .fontColor(Color.Black)
              .onClick(() => {
                this.config.loadPreset('sports');
                promptAction.showToast({ message: '已应用体育模板' });
              })
            
            Button('🎂 生日')
              .fontSize(14)
              .backgroundColor('#FFD700')
              .fontColor(Color.Black)
              .onClick(() => {
                this.config.loadPreset('birthday');
                promptAction.showToast({ message: '已应用生日模板' });
              })
            
            Button('⚡ 霓虹')
              .fontSize(14)
              .backgroundColor('#00FFFF')
              .fontColor(Color.Black)
              .onClick(() => {
                this.config.loadPreset('neon');
                promptAction.showToast({ message: '已应用霓虹模板' });
              })
            
            Button('🎄 圣诞')
              .fontSize(14)
              .backgroundColor('#228B22')
              .fontColor(Color.White)
              .onClick(() => {
                this.config.loadPreset('christmas');
                promptAction.showToast({ message: '已应用圣诞模板' });
              })
            
            Button('🎃 万圣')
              .fontSize(14)
              .backgroundColor('#FF6600')
              .fontColor(Color.Black)
              .onClick(() => {
                this.config.loadPreset('halloween');
                promptAction.showToast({ message: '已应用万圣节模板' });
              })
            
            Button('❤️ 浪漫')
              .fontSize(14)
              .backgroundColor('#FF69B4')
              .fontColor(Color.White)
              .onClick(() => {
                this.config.loadPreset('romantic');
                promptAction.showToast({ message: '已应用浪漫模板' });
              })
            
            Button('🎮 游戏')
              .fontSize(14)
              .backgroundColor('#0D0D0D')
              .fontColor('#00FF00')
              .onClick(() => {
                this.config.loadPreset('gaming');
                promptAction.showToast({ message: '已应用游戏模板' });
              })
          }
        }
        .width('100%')
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        // --- Template Management ---
        Text('模板管理').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 20 })
        
        Row({ space: 10 }) {
          TextInput({ placeholder: '输入模板名称' })
            .layoutWeight(1)
            .onChange((val) => {
               // We need a state variable for this input, but for now let's use a simple approach
               // Since we can't easily add a state var inside build() without re-structuring,
               // we will assume the user types and then clicks save.
               // Actually, let's add a @State for newTemplateName at the top of the class in next step.
               this.newTemplateName = val;
            })
          
          Button('保存')
            .onClick(() => {
              if (this.newTemplateName) {
                this.saveTemplateWithName(this.newTemplateName);
                this.newTemplateName = ''; // Clear (UI won't clear without binding, but logic is fine)
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
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .shadow({ radius: 2, color: '#DDDDDD', offsetY: 1 })
              }
            })
          }
          .width('100%')
          .height(150) // Limit height
        }
      }
      .padding(20)
      .width('100%')
    }
    .height('100%')
    .align(Alignment.Top)
  }
}
