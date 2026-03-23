import router from '@ohos.router';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { BarrageConfig } from '../model/BarrageConfig';
import { BarragePreview } from '../components/BarragePreview';
import { FontManager } from '../utils/FontManager';

@Entry
@Component
struct PlayPage {
  @State config: BarrageConfig = new BarrageConfig();
  @State fontsReady: boolean = false;
  @State hudOpacity: number = 1;
  @State showHud: boolean = true;
  private originalBrightness: number = -1;
  private fontManager: FontManager = FontManager.getInstance();
  private hudTimer: number = -1;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      if (params['configJson']) {
        const jsonStr = params['configJson'] as string;
        this.config = BarrageConfig.fromJSON(jsonStr);
      }
    }

    // 确保字体已加载
    this.initFonts();

    // 启动 HUD 淡出定时器
    this.startHudFadeOut();

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(context).then((win) => {
      win.setWindowSystemBarEnable([]);

      // 设置屏幕方向
      if (this.config.direction === 'vertical') {
        win.setPreferredOrientation(window.Orientation.PORTRAIT);
      } else {
        win.setPreferredOrientation(window.Orientation.LANDSCAPE);
      }

      // 设置屏幕亮度
      try {
        const props = win.getWindowProperties();
        this.originalBrightness = props.brightness;
        if (this.config.brightness > 0 && this.config.brightness <= 1) {
          win.setWindowBrightness(this.config.brightness);
        }
      } catch (e) {
        console.error('Barrage: Failed to set brightness: ' + JSON.stringify(e));
      }

      // 保持屏幕常亮
      if (this.config.keepScreenOn) {
        win.setWindowKeepScreenOn(true);
      }
    });
  }

  private async initFonts(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await this.fontManager.loadFonts(context);
    this.fontsReady = true;
  }

  private startHudFadeOut(): void {
    // 3秒后开始淡出
    this.hudTimer = setTimeout(() => {
      this.getUIContext()?.animateTo({
        duration: 800,
        curve: Curve.EaseOut
      }, () => {
        this.hudOpacity = 0;
      });
      // 动画完成后隐藏 HUD
      setTimeout(() => {
        this.showHud = false;
      }, 800);
    }, 2500);
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.hudTimer !== -1) {
      clearTimeout(this.hudTimer);
      this.hudTimer = -1;
    }

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(context).then((win) => {
      win.setPreferredOrientation(window.Orientation.PORTRAIT);
      win.setWindowSystemBarEnable(['status', 'navigation']);

      // 恢复屏幕亮度
      if (this.originalBrightness >= 0) {
        try {
          win.setWindowBrightness(this.originalBrightness);
        } catch (e) {
          console.error('Barrage: Failed to restore brightness: ' + JSON.stringify(e));
        }
      }

      // 取消常亮
      win.setWindowKeepScreenOn(false);
    });
  }

  private getDirectionText(): string {
    return this.config.direction === 'horizontal' ? '横向' : '纵向';
  }

  private getAnimationText(): string {
    const names: Record<string, string> = {
      'none': '无', 'scale': '缩放', 'rotate': '旋转',
      'jump': '跳跃', 'shake': '抖动', 'wave': '波浪'
    };
    return names[this.config.animationType] || '无';
  }

  build() {
    Stack() {
      // 弹幕内容
      BarragePreview({ config: this.config })

      // HUD 信息 (顶部淡出)
      if (this.showHud) {
        Column({ space: 4 }) {
          Row({ space: 16 }) {
            // 速度
            Row({ space: 4 }) {
              Text('⚡').fontSize(12)
              Text(`速度 ${this.config.scrollSpeed}`).fontSize(12).fontColor('#FFFFFF')
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#00000066')
            .borderRadius(12)

            // 方向
            Row({ space: 4 }) {
              Text(this.config.direction === 'horizontal' ? '↔' : '↕').fontSize(12)
              Text(this.getDirectionText()).fontSize(12).fontColor('#FFFFFF')
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#00000066')
            .borderRadius(12)

            // 动画
            if (this.config.animationType !== 'none') {
              Row({ space: 4 }) {
                Text('✨').fontSize(12)
                Text(this.getAnimationText()).fontSize(12).fontColor('#FFFFFF')
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#00000066')
              .borderRadius(12)
            }
          }

          Text('双击退出').fontSize(10).fontColor('#FFFFFF99')
        }
        .width('100%')
        .padding({ top: 20 })
        .alignItems(HorizontalAlign.Center)
        .opacity(this.hudOpacity)
      }
    }
    .width('100%')
    .height('100%')
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          router.back();
        })
    )
  }

  pageTransition() {
    // Apply transition based on config
    // Note: We can't easily access 'this.config' inside pageTransition in some API versions if it's not static
    // But standard PageTransitionEnter/Exit works.
    // Let's implement a generic fade/scale effect which covers most "PPT-like" needs.
    
    PageTransitionEnter({ duration: 600, curve: Curve.Smooth })
      .opacity(0)
      .scale({ x: 0.5, y: 0.5 })
      
    PageTransitionExit({ duration: 600, curve: Curve.Smooth })
      .opacity(0)
      .scale({ x: 1.5, y: 1.5 })
  }
}
