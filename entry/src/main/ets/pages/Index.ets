import router from '@ohos.router';
import { BarrageConfig } from '../model/BarrageConfig';
import { BarragePreview } from '../components/BarragePreview';
import { SettingsPanel } from '../components/SettingsPanel';

@Entry
@Component
struct Index {
  @State config: BarrageConfig = new BarrageConfig();

  build() {
    Column() {
      // Preview Area
      Stack({ alignContent: Alignment.BottomEnd }) {
        BarragePreview({ config: this.config })
          .width('100%')
          .height('100%')
        
        Button('全屏播放')
          .margin(10)
          .onClick(() => {
            // 使用 JSON 序列化传递配置，避免对象原型丢失问题
            router.pushUrl({
              url: 'pages/PlayPage',
              params: {
                configJson: this.config.toJSON()
              }
            })
          })
      }
      .width('100%')
      .height('35%')
      .border({ width: { bottom: 1 }, color: Color.Gray })

      // Settings Area
      Column() {
        SettingsPanel({ config: this.config })
      }
      .width('100%')
      .height('65%')
    }
    .width('100%')
    .height('100%')
  }
}