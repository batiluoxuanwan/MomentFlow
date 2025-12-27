import { router, promptAction } from '@kit.ArkUI';
import { Diary } from '../model/Diary'
import { DiaryApi } from '../api/DiaryApi'
import { DiaryDto } from '../model/DiaryDto';
import { User } from '../model/User';

const moods: string[] = ['😊 开心', '😐 平静', '😰 焦虑', '😭 难过']

interface EditParams {
  id: number
}

@Entry
@Component
struct DiaryEdit {
  // 1. 【核心】链接全局仓库
  @StorageLink('diaries') diaries: Diary[] = []
  @StorageProp('user') user: User | null = null

  @State title: string = ''
  @State content: string = ''
  @State mood: string = '😐 平静'
  @State moodIndex: number = 1
  private diaryId: number = 0

  options: SelectOption[] = moods.map((item: string): SelectOption => { return { value: item } })

  aboutToAppear() {
    const params = router.getParams() as EditParams
    if (params && params.id) {
      this.diaryId = params.id
      // 优先从本地仓库读，没读到再查网络
      const localDiary = this.diaries.find(item => item.id === this.diaryId)
      if (localDiary) {
        this.initState(localDiary)
      } else {
        this.loadDiary(this.diaryId)
      }
    }
  }

  async loadDiary(id: number) {
    try {
      // 找到 loadDiary 之类的方法
      const res = await DiaryApi.detail(id)
      if (res !== null) {
        this.initState(res) // 只有确定有数据才赋值
      }
      // const diary = await DiaryApi.detail(id)
      // this.initState(diary)
    } catch (e) {
      promptAction.showToast({ message: '加载失败' })
    }
  }

  initState(diary: Diary) {
    this.title = diary.title
    this.content = diary.content
    this.mood = diary.mood
    this.moodIndex = moods.indexOf(diary.mood)
  }

  async saveDiary() {
    if (!this.title.trim() || !this.content.trim()) {
      promptAction.showToast({ message: '标题和内容不能为空' })
      return
    }

    const updatedData: DiaryDto = {
      title: this.title,
      content: this.content,
      mood: this.mood,
      userId: this.user?.id ?? 0
    }

    try {
      const res = await DiaryApi.update(this.diaryId, updatedData)
      if (res !== null) {
        this.diaries = this.diaries.map(item => item.id === this.diaryId ? res : item)
      }
      // 1. 提交网络更新
      // 这里的逻辑通常是保存成功后刷新本地列表
      //const result = await DiaryApi.update(this.diaryId, updatedData)
      // 2. 【核心】更新全局 Store
      // 找到数组中对应的那条数据并替换它
      //this.diaries = this.diaries.map(item => item.id === this.diaryId ? result : item)

      promptAction.showToast({ message: '修改成功' })
      router.back()
    } catch (e) {
      promptAction.showToast({ message: '修改失败' })
    }
  }

  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Text('取消').fontColor(Color.Gray).onClick(() => router.back())
        Text('修改日记').fontSize(18).fontWeight(FontWeight.Bold)
        Text('保存')
          .fontColor(this.title.trim() ? '#007DFF' : '#999999')
          .fontWeight(FontWeight.Bold)
          .onClick(() => { if(this.title.trim()) this.saveDiary() })
      }
      .width('100%').justifyContent(FlexAlign.SpaceBetween).padding(16).backgroundColor(Color.White)

      Column() {
        TextInput({ placeholder: '请输入标题', text: this.title })
          .fontSize(20).fontWeight(FontWeight.Bold).backgroundColor(Color.Transparent)
          .onChange((v) => this.title = v)

        Divider().margin({ top: 10, bottom: 10 }).color('#F2F2F2')

        Row() {
          Text('心情').fontColor('#666')
          Blank()
          Select(this.options)
            .selected(this.moodIndex)
            .value(this.mood)
            .onSelect((index: number) => {
              this.moodIndex = index
              this.mood = moods[index]
            })
        }.width('100%')
        .padding({left:16})

        Divider().margin({ top: 10, bottom: 10 }).color('#F2F2F2')

        TextArea({ placeholder: '在此修改你的日记...', text: this.content })
          .fontSize(16).placeholderColor('#BBB').backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((v) => this.content = v)
      }
      .padding(20).backgroundColor(Color.White).borderRadius(16).margin(16).layoutWeight(1)
    }
    .height('100%').backgroundColor('#F1F3F5')
  }
}