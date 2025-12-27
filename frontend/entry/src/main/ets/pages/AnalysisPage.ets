import { User } from "../model/User"
import { promptAction } from "@kit.ArkUI"
import { AiApi } from "../api/AIApi"


@Component
export struct AnalysisPage {
  @State aiContent: string = '点击分析，让我通过日记读懂你的心情...'
  @State isAnalyzing: boolean = false
  @StorageProp('user') user: User | null = null

  build() {
    Column() {
      // 头部
      Text('AI 情绪周报').fontSize(24).fontWeight(FontWeight.Bold).margin(20)

      // AI 回复区域
      Scroll() {
        Column() {
          if (this.isAnalyzing) {
            LoadingProgress().width(40).height(40)
          } else {
            Text(this.aiContent)
              .fontSize(16)
              .lineHeight(24)
              .fontColor('#333')
              .padding(15)
          }
        }
      }
      .layoutWeight(1)
      .width('90%')
      .backgroundColor(Color.White)
      .borderRadius(15)
      .shadow({ radius: 10, color: '#10000000' })

      // 触发按钮
      Button('开始 AI 深度分析')
        .width('80%')
        .height(50)
        .margin(30)
        .linearGradient({
          direction: GradientDirection.Left,
          colors: [['#007DFF', 0.0], ['#00BFFF', 1.0]]
        })
        .onClick(async () => {
          await this.handleStartAnalyze()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  // 💡 显式定义返回类型为 Promise<void>
  async handleStartAnalyze(): Promise<void> {
    if (this.user === null || this.user.id === undefined) {
      promptAction.showToast({ message: '请先登录后再使用分析功能' })
      return
    }

    this.isAnalyzing = true
    const currentUserId: number = this.user.id

    try {
      // 这里的 result 会被自动推断为 string
      const result: string = await AiApi.analyzeDiary(currentUserId)
      this.aiContent = result
    } catch (err) {
      // 💡 显式断言为 Error 类型，解决 arkts-no-any-unknown
      const error = err as Error
      this.aiContent = `分析出错啦: ${error.message}`
      promptAction.showToast({ message: '分析失败，请稍后重试' })
    } finally {
      this.isAnalyzing = false
    }
  }
}