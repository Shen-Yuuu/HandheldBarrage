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
  private originalBrightness: number = -1;
  private fontManager: FontManager = FontManager.getInstance();

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

  aboutToDisappear() {
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

  build() {
    Column() {
      BarragePreview({ config: this.config })
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
