import router from '@ohos.router';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { BarrageConfig } from '../model/BarrageConfig';
import { BarragePreview } from '../components/BarragePreview';

@Entry
@Component
struct PlayPage {
  @State config: BarrageConfig = new BarrageConfig();

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      // 优先使用 JSON 序列化的配置
      if (params['configJson']) {
        const jsonStr = params['configJson'] as string;
        this.config = BarrageConfig.fromJSON(jsonStr);
      }
    }

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(context).then((win) => {
      win.setWindowSystemBarEnable([]); // Hide status bar and navigation bar
      
      // Set orientation based on scroll direction
      if (this.config.direction === 'vertical') {
        win.setPreferredOrientation(window.Orientation.PORTRAIT);
      } else {
        win.setPreferredOrientation(window.Orientation.LANDSCAPE);
      }
    });
  }

  aboutToDisappear() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(context).then((win) => {
      win.setPreferredOrientation(window.Orientation.PORTRAIT);
      win.setWindowSystemBarEnable(['status', 'navigation']); // Show status bar and navigation bar
    });
  }

  build() {
    Column() {
      BarragePreview({ config: this.config })
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      router.back();
    })
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
