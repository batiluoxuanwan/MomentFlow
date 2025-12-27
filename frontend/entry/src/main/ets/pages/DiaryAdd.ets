import { router, promptAction } from '@kit.ArkUI';
import { Diary } from '../model/Diary'
import { DiaryDto } from '../model/DiaryDto'
import { DiaryApi } from '../api/DiaryApi'
import { User } from '../model/User';

const moods: string[] = ['😊 开心', '😐 平静', '😰 焦虑', '😭 难过']

@Entry
@Component
struct DiaryAdd {
  @State title: string = ''
  @State content: string = ''
  // 设置默认值，防止 Select 组件初始显示为空
  @State mood: string = moods[1]
  @State moodIndex: number = 1

  // 使用 StorageLink，这样我们在 addDiary 时直接修改它，首页会自动变
  @StorageLink('diaries') diaries: Diary[] = []
  @StorageProp('user') user: User | null = null

  options: SelectOption[] = moods.map((item: string): SelectOption => {
    return { value: item }
  })

  async saveDiary() {
    if (!this.title.trim() || !this.content.trim()) {
      promptAction.showToast({ message: '标题和内容不能为空' })
      return
    }

    const newDiaryDto: DiaryDto = {
      title: this.title,
      content: this.content,
      mood: this.mood,
      userId: this.user?.id ?? 0
    }

    try {
      const res = await DiaryApi.create(newDiaryDto)
      if (res !== null) {
        // 这里原先可能是把 res 塞进列表或者跳转
        this.diaries = [res, ...this.diaries]
      }
      // 1. 发送到服务器
      //const result = await DiaryApi.create(newDiaryDto)
      // 2. 【关键：同步本地 Store】
      // 直接通过 StorageLink 更新全局数组，触发首页自动刷新
      // 使用扩展运算符 [...] 确保触发 ArkUI 的状态监听
      //this.diaries = [result, ...this.diaries]

      promptAction.showToast({ message: '新增成功' })

      // 3. 返回上一页
      router.back()
    } catch (e) {
      console.error('❌ 新增失败', e)
      promptAction.showToast({ message: '发送失败，请检查网络' })
    }
  }

  build() {
    Column() {
      // 自定义顶部栏
      Row() {
        Text('取消').fontColor(Color.Gray).onClick(() => router.back())
        Text('写日记').fontSize(18).fontWeight(FontWeight.Bold)
        Text('完成')
          .fontColor(this.title.trim() ? '#007DFF' : '#999999')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if(this.title.trim()) this.saveDiary()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(16)
      .backgroundColor(Color.White)

      // 输入区域
      Column() {
        TextInput({ placeholder: '请输入标题', text: this.title })
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .placeholderColor('#999')
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => this.title = value)
          .padding({ top: 20, bottom: 20 })

        Divider().color('#F2F2F2').strokeWidth(1)

        Row() {
          Text('当前心情').fontSize(16).fontColor('#666')
          Blank()
          Select(this.options)
            .selected(this.moodIndex)
            .value(this.mood)
            .font({ size: 16 })
            .onSelect((index: number) => {
              this.moodIndex = index
              this.mood = moods[index]
            })
        }
        .width('100%')
        .padding({ top: 10, bottom: 10,left: 16 })

        Divider().color('#F2F2F2').strokeWidth(1)

        TextArea({ placeholder: '记录下这一刻的想法...', text: this.content })
          .placeholderColor('#BBB')
          .fontSize(16)
          .layoutWeight(1) // 让内容区域占满剩余空间
          .backgroundColor(Color.Transparent)
          .padding({ top: 20 })
          .onChange((value: string) => this.content = value)
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .margin(16)
      .layoutWeight(1) // 整体容器占满，以便 TextArea 伸缩
    }
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}