import { DiaryPage } from './DiaryPage'
import { MinePage } from './MinePage'

import http from '@ohos.net.http';
import { AnalysisPage } from './AnalysisPage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 1
  private controller: TabsController = new TabsController()

  aboutToAppear() {
    const httpRequest = http.createHttp();

    httpRequest.request(
      'http://10.0.2.2:8080/api/diary/ping',
      {
        method: http.RequestMethod.GET
      },
      (err, data) => {
        if (err) {
          console.error('❌ 网络请求失败', JSON.stringify(err));
          return;
        }

        console.info('✅ 状态码:', data.responseCode);
        console.info('✅ 返回内容:', data.result);
      }
    );
  }

  @Builder
  NavigationItem(index: number, label: string, icon: Resource, activeIcon: Resource) {
    Column() {
      Image(this.currentIndex === index ? activeIcon : icon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
        .fillColor(this.currentIndex === index ? '#007DFF' : '#999999')

      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .onClick(() => {
      this.currentIndex = index
      this.controller.changeIndex(index)
    })
  }

  build() {
    Column() {
      // 内容区域
      Tabs({ barPosition: BarPosition.End, controller: this.controller ,index:1 }) {
        TabContent() {
          AnalysisPage()
          // Column() { Text('分析页面 (开发中)').fontSize(20).fontColor(Color.Gray) }
          // .justifyContent(FlexAlign.Center).width('100%').height('100%')
        }
        TabContent() {
          DiaryPage()
        }
        TabContent() {
          MinePage()
        }
      }
      .layoutWeight(1)
      .barHeight(0) // 隐藏系统原生的 TabBar
      .scrollable(true) // 开启平级滑动切换
      .onChange((index: number) => {
        this.currentIndex = index
      })

      // 自定义底部导航栏
      Row() {
        this.NavigationItem(0, '分析', $r('app.media.check'), $r('app.media.check_active'))
        this.NavigationItem(1, '首页', $r('app.media.home'), $r('app.media.home_active'))
        this.NavigationItem(2, '我的', $r('app.media.user'), $r('app.media.user_active'))
      }
      .height(60)
      .width('100%')
      .backgroundColor('#F7F7F7')
      .border({ width: { top: 0.5 }, color: '#E5E5E5' })
      .padding({ bottom: 4 })
    }
    .height('100%')
    .width('100%')
  }
}