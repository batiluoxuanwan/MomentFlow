import { Diary } from '../model/Diary'
import { promptAction, router } from '@kit.ArkUI'
import { DiaryApi } from '../api/DiaryApi'
import { User } from '../model/User'

@Component
export struct DiaryPage {
  // 【单一真理源】绑定 AppStorage
  @StorageLink('diaries') localDiaries: Diary[] = []
  @StorageProp('user') user: User | null = null
  @State isRefreshing: boolean = false

  aboutToAppear() {
    // 首次进入加载
    this.loadDiariesFromServer()
  }

  async loadDiariesFromServer() {
    this.isRefreshing = true
    try {
      if(this.user!=null) {
        const list = await DiaryApi.getList(this.user.id)
        // 直接更新 AppStorage，localDiaries 会自动同步
        AppStorage.setOrCreate('diaries', list)
        console.info('✅ 数据已同步到全局仓库')
      }
      else{
        promptAction.showToast({ message: '当前还未登录！' })
        router.replaceUrl({ url: 'pages/LoginPage' })
      }
    } catch (e) {
      console.error('❌ 请求失败', e)
    } finally {
      this.isRefreshing = false
    }
  }

  async loadDiariesWithDelay() {
    this.isRefreshing = true
    const startTime = Date.now()

    try {
      if(this.user!=null) {
      const list = await DiaryApi.getList(this.user.id)
      AppStorage.setOrCreate('diaries', list)
      }
      else{
        promptAction.showToast({ message: '当前还未登录！' })
        router.replaceUrl({ url: 'pages/LoginPage' })
      }

      // 计算耗时，确保至少停留 1000ms (1秒)，让动画有个展示过程
      const elapsedTime = Date.now() - startTime
      const minDelay = 1000

      if (elapsedTime < minDelay) {
        setTimeout(() => {
          this.isRefreshing = false // 1秒后回弹
        }, minDelay - elapsedTime)
      } else {
        this.isRefreshing = false // 如果接口很慢，直接回弹
      }
    } catch (e) {
      console.error('刷新失败', e)
      this.isRefreshing = false
    }
  }

  build() {
    Column() {
      this.buildAppBar()

      Refresh({
        refreshing: $$this.isRefreshing,
        builder: this.myRefreshHeader() // 👈 调用上面定义的 builder
      }) {
        List({ space: 12 }) {
          ForEach(this.localDiaries, (item: Diary) => {
            ListItem() {
              this.diaryCard(item)
            }
          }, (item: Diary) => `${item.id}_${item.title}_${item.mood}`)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .friction(0.8)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }
      .onRefreshing(() => {
        this.loadDiariesWithDelay()
      })
      .refreshOffset(60) // 💡 触发距离稍微大于 builder 的高度，手感更好
      .pullToRefresh(true)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder
  myRefreshHeader() {
    Row() {
      LoadingProgress()
        .width(36)
        .height(36)
        .padding({top: 12})
    }
    .width('100%')
    .height(60) // 💡 这个高度就是下拉出来的空间高度，60-80 比较合适
    .justifyContent(FlexAlign.Center) // 💡 水平居中
    .alignItems(VerticalAlign.Center) // 💡 垂直居中（这就是你要的正中间）
  }

  @Builder buildAppBar() {
    Stack() {
      Text('我的日记').fontSize(22).fontWeight(FontWeight.Bold)
      Image($r('app.media.add'))
        .width(32).height(32)
        .position({ right: 16, top: 12 })
        .onClick(() => router.pushUrl({ url: 'pages/DiaryAdd' }))
    }
    .height(56).width('100%').backgroundColor(Color.White)
  }

  @Builder diaryCard(item: Diary) {
    Column() {
      // 标题：使用 maxLines 和 textOverflow 保证在固定高度内不撑开
      Text(item.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
        .maxLines(1) // 限制只有一行
        .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出显示省略号
        .margin({ bottom: 4 })

      Text(item.mood + ' · ' + new Date(item.createTime).toLocaleDateString())
        .fontSize(12)
        .fontColor(Color.Gray)
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ color: '#15000000', radius: 6 })
    .width('100%')
    .height(80) // 固定高度，确保卡片大小一模一样
    .justifyContent(FlexAlign.Center) // 内容垂直居中
    .alignItems(HorizontalAlign.Center) // 水平居中 (左右居中)
    .onClick(() => router.pushUrl({ url: 'pages/DiaryDetail', params: { id: item.id } }))
  }
}