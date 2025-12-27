import { router, promptAction } from '@kit.ArkUI';
import { Diary } from '../model/Diary'
import { DiaryApi } from '../api/DiaryApi'
import { User } from '../model/User';
import { common } from '@kit.AbilityKit';
import { ExportUtil } from '../utils/ExportUtil';

interface DiaryDetailParams {
  id: number
}

@Entry
@Component
struct DiaryDetail {
  // 1. 【核心】绑定全局仓库
  // 这样当我们在详情页删除数据并同步给 diaries 时，首页列表会自动刷新
  @StorageLink('diaries') diaries: Diary[] = []
  @StorageProp('user') user: User | null = null

  @State diaryId: number = 0
  @State diary: Diary = {
    id: 0,
    title: '加载中...',
    content: '',
    mood: '',
    createTime: '',
    updateTime: '',
    userId: this.user?.id ?? 0
  }

  // 从网络加载详情
  async loadDiary(id: number) {
    try {
      const res = await DiaryApi.detail(id)
      if (res !== null) {
        this.diary = res // 只有确定有数据才赋值
      }
      //this.diary = await DiaryApi.detail(id)
    } catch (e) {
      console.error('❌ 获取日记失败', e)
      promptAction.showToast({ message: '日记加载失败' })
    }
  }

  // 删除逻辑
  async confirmDelete() {
    const dialogRes = await promptAction.showDialog({
      title: '删除日记',
      message: '确定要删除这篇珍贵的记忆吗？',
      buttons: [
        { text: '取消', color: '#000000' },
        { text: '删除', color: '#FF0000' }
      ]
    })

    if (dialogRes.index === 1) {
      try {
        // 1. 调用 Net 层物理删除
        await DiaryApi.delete(this.diaryId)

        // 2. 【核心】更新 Store 层逻辑删除
        // 过滤掉当前 ID，产生一个新数组，首页列表会自动同步
        this.diaries = this.diaries.filter(item => item.id !== this.diaryId)

        promptAction.showToast({ message: '已删除' })
        router.back()
      } catch (e) {
        promptAction.showToast({ message: '删除失败' })
      }
    }
  }

  aboutToAppear() {
    const params = router.getParams() as DiaryDetailParams
    if (params && params.id) {
      this.diaryId = params.id
      this.loadDiary(this.diaryId)
    }
  }

  // 当从“编辑页”修改成功返回后，页面会重新显示
  onPageShow() {
    if (this.diaryId > 0) {
      this.loadDiary(this.diaryId)
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.back'))
          .width(24).height(24)
          .onClick(() => router.back())
        Blank()
        // 在 build() 的 Row 导航栏中添加
        Image($r('app.media.share')) // 记得放一个分享图标到 media
          .width(24).height(24)
          .margin({ right: 16 })
          .onClick(async () => {
            try {
              promptAction.showToast({ message: '正在准备 PDF...' });
              const context = getContext(this) as common.UIAbilityContext;
              await ExportUtil.downloadAndSharePdf(this.diaryId, context);
            } catch (e) {
              promptAction.showToast({ message: '导出失败' });
            }
          })
        // 编辑
        Image($r('app.media.edit'))
          .width(24).height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/DiaryEdit',
              params: { id: this.diaryId }
            })
          })

        // 删除
        Image($r('app.media.delete'))
          .width(24).height(24)
          .onClick(() => this.confirmDelete())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 内容区
      if (this.diary.id === 0) {
        // 加载占位
        Column() {
          LoadingProgress().width(40).height(40)
        }.justifyContent(FlexAlign.Center).layoutWeight(1).width('100%')
      } else {
        Scroll() {
          Column() {
            Text(this.diary.title)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ top: 10, bottom: 12 })

            Row() {
              Text(this.diary.mood)
                .fontSize(14)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#F1F3F5')
                .borderRadius(6)

              Text(this.formatISO(this.diary.createTime))
                .fontSize(14)
                .fontColor('#999')
                .margin({ left: 12 })
            }
            .width('100%')
            .margin({ bottom: 24 })

            Text(this.diary.content)
              .fontSize(18)
              .lineHeight(30)
              .width('100%')
              .fontColor('#333')
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 40 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.Top)
      }
    }
    .height('100%')
    .backgroundColor(Color.White)
  }

  // 格式化 ISO 字符串
  formatISO(isoString: string): string {
    if (!isoString) return ''
    const date = new Date(isoString)
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
  }
}