import { font } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';

/**
 * 字体信息
 */
export interface FontInfo {
  familyName: string;   // 注册名 = config.fontFamily 使用的值
  displayName: string;  // UI 显示名
}

/**
 * 全局字体管理器（单例）
 * 统一负责字体注册，避免重复注册和名称冲突
 */
export class FontManager {
  private static instance: FontManager | null = null;
  private registeredFonts: Map<string, FontInfo> = new Map();
  private isLoaded: boolean = false;
  private loadingPromise: Promise<void> | null = null;

  // 字体列表（包含默认字体 + 已加载字体）
  private fontList: FontInfo[] = [];

  // 静态映射：英文文件名 -> 中文显示名
  private staticFontMap: Record<string, string> = {
    'FeiYunTi': '飞云体',
    'MaokenAssortedSans': '什锦黑',
    'MaokenZhuyuanTi': '珠圆体',
    'yuanqituantuan': '元气团团',
    'SmileySans-Oblique': '得意黑',
    'LXGWWenKai-Medium': '文楷',
  };

  private constructor() {
    // 初始化默认字体
    this.fontList = [
      { familyName: 'HarmonyOS Sans', displayName: 'HarmonySans' },
    ];
  }

  /**
   * 获取单例
   */
  static getInstance(): FontManager {
    if (!FontManager.instance) {
      FontManager.instance = new FontManager();
    }
    return FontManager.instance;
  }

  /**
   * 获取所有可用字体列表
   */
  getFontList(): FontInfo[] {
    return [...this.fontList];
  }

  /**
   * 获取已加载的自定义字体数量（不含默认字体）
   */
  getLoadedCount(): number {
    return Math.max(0, this.fontList.length - 3);
  }

  /**
   * 是否已完成加载
   */
  getIsLoaded(): boolean {
    return this.isLoaded;
  }

  /**
   * 检查字体是否已注册
   */
  isRegistered(familyName: string): boolean {
    return this.registeredFonts.has(familyName);
  }

  /**
   * 根据 familyName 查找 displayName
   */
  getDisplayName(familyName: string): string {
    const info = this.fontList.find(f => f.familyName === familyName);
    return info ? info.displayName : familyName;
  }

  /**
   * 加载 rawfile/fonts 目录下的所有字体
   * 使用 Promise 确保只加载一次，多次调用返回同一个 Promise
   */
  async loadFonts(context: common.UIAbilityContext): Promise<void> {
    // 如果已经加载完成，直接返回
    if (this.isLoaded) {
      return;
    }

    // 如果正在加载，返回同一个 Promise（防止并发重复加载）
    if (this.loadingPromise) {
      return this.loadingPromise;
    }

    this.loadingPromise = this.doLoadFonts(context);
    return this.loadingPromise;
  }

  private async doLoadFonts(context: common.UIAbilityContext): Promise<void> {
    try {
      const resourceManager = context.resourceManager;
      const files = await resourceManager.getRawFileList('fonts');
      console.info(`[FontManager] Found ${files.length} font files in rawfile/fonts`);

      let fileIndex = 0;

      for (const filename of files) {
        fileIndex++;
        const cleaned = filename.trim();
        const matchResult = cleaned.match(/(.+?)\s*\.(ttf|otf)$/i);
        if (!matchResult) {
          console.warn(`[FontManager] Skip non-font file: ${filename}`);
          continue;
        }

        const baseName = matchResult[1];
        const extension = `.${matchResult[2].toLowerCase()}`;

        // 确定显示名和注册名（统一使用显示名作为 familyName）
        const displayName = this.staticFontMap[baseName] || baseName;
        const familyName = displayName;

        // 跳过已注册的
        if (this.registeredFonts.has(familyName)) {
          console.info(`[FontManager] Font ${familyName} already registered, skip`);
          continue;
        }

        // 安全文件名
        const safeTargetName = `font_${Date.now()}_${fileIndex}${extension}`;
        const targetPath = `${context.filesDir}/${safeTargetName}`;

        try {
          // 读取 rawfile 并写入 filesDir
          const fileData = await resourceManager.getRawFileContent(`fonts/${filename}`);
          const file = fs.openSync(targetPath,
            fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
          fs.writeSync(file.fd, fileData.buffer, {
            offset: fileData.byteOffset,
            length: fileData.byteLength
          });
          fs.closeSync(file);

          // 注册字体
          font.registerFont({
            familyName: familyName,
            familySrc: `file://${targetPath}`
          });

          const info: FontInfo = { familyName, displayName };
          this.registeredFonts.set(familyName, info);
          this.fontList.push(info);

          console.info(`[FontManager] Registered: ${familyName} (${filename})`);
        } catch (e) {
          console.error(`[FontManager] Failed to register ${filename}: ${JSON.stringify(e)}`);
        }
      }

      this.isLoaded = true;
      console.info(`[FontManager] Load complete. Total fonts: ${this.fontList.length}`);
    } catch (err) {
      console.error(`[FontManager] Load failed: ${JSON.stringify(err)}`);
      this.isLoaded = true; // 即使失败也标记完成，避免反复重试
    }
  }

  /**
   * 注册用户导入的自定义字体
   */
  registerCustomFont(familyName: string, filePath: string): boolean {
    if (this.registeredFonts.has(familyName)) {
      console.warn(`[FontManager] Font ${familyName} already registered`);
      return false;
    }

    try {
      font.registerFont({
        familyName: familyName,
        familySrc: `file://${filePath}`
      });

      const info: FontInfo = { familyName, displayName: familyName };
      this.registeredFonts.set(familyName, info);
      this.fontList.push(info);

      console.info(`[FontManager] Custom font registered: ${familyName}`);
      return true;
    } catch (e) {
      console.error(`[FontManager] Failed to register custom font: ${JSON.stringify(e)}`);
      return false;
    }
  }
}