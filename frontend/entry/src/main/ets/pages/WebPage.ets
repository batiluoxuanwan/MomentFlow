import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';

// 1. 定义一个接口来约束跳转参数
interface WebParams {
  url: string;
  title: string;
}

@Entry
@Component
struct WebPage {
  controller: webview.WebviewController = new webview.WebviewController();

  // 2. 使用具体类型代替 any
  // router.getParams() 返回的是 object | undefined，我们需要进行类型断言
  @State params: WebParams = router.getParams() as WebParams;

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .onClick(() => router.back())

        // 3. 此时访问属性会有代码提示，且不会报错
        Text(this.params?.title || '网页浏览')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // Web 组件
      Web({ src: this.params?.url || 'https://github.com', controller: this.controller })
        .domStorageAccess(true)
        .zoomAccess(true)
        .layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor('#F1F3F5')
  }
}