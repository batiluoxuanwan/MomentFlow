import { User } from "../model/User"
import { promptAction } from "@kit.ArkUI"
import { AiApi } from "../api/AIApi"
import { Diary } from "../model/Diary"


@Component
export struct AnalysisPage {
  @State aiContent: string = '点击分析，让我通过日记读懂你的心情...'
  @State isAnalyzing: boolean = false
  @StorageProp('user') user: User | null = null
  @StorageProp('diaries') diaries: Diary[] = []
  @State positiveWidth: string = '33%'
  @State neutralWidth: string = '33%'
  @State negativeWidth: string = '34%'

  updateMoodChart() {
    if (this.diaries.length === 0) return

    let posCount = 0
    let neuCount = 0
    let negCount = 0

    // 定义分类逻辑
    const positiveMoods = ['🔋 充满动力', '✨ 确幸时刻', '🤝 归属感', '🍵 回甘释然']
    const neutralMoods = ['☁️ 平淡放空', '🧊 情感隔离', '🧭 迷惘寻索','🕯️ 孤独享受']
    // 其余的归为压力

    this.diaries.forEach(d => {
      if (positiveMoods.includes(d.mood)) posCount++
      else if (neutralMoods.includes(d.mood)) neuCount++
      else negCount++
    })

    const total = this.diaries.length
    // 计算百分比并转换为字符串
    this.positiveWidth = ((posCount / total) * 100).toFixed(0) + '%'
    this.neutralWidth = ((neuCount / total) * 100).toFixed(0) + '%'
    this.negativeWidth = ((negCount / total) * 100).toFixed(0) + '%'
  }

  build() {
    Column() {
      // --- 固定区域：标题 ---
      Text('情绪空间').fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })
        .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
          if (isVisible && currentRatio >= 1.0) {
            console.info('情绪空间可见，执行更新')
            this.updateMoodChart()
          }
        })

      // --- 固定区域：优化后的统计图卡片 ---
      Column() {
        Row() {
          Text('本周情绪底色').fontSize(15).fontWeight(FontWeight.Medium)
          Blank()
          Text('近7天记录').fontSize(12).fontColor('#999')
        }.width('100%').margin({ bottom: 15 })

        Row() {
          // 1. 积极 - 绿色（左侧圆角）
          Rect()
            .width(this.positiveWidth)
            .height(14) // 稍微加粗一点更有质感
            .fill('#4CAF50')
            .radius([[7, 7], [0, 0], [0, 0], [7, 7]])

          // 2. 平稳 - 蓝色（直角无缝）
          Rect()
            .width(this.neutralWidth)
            .height(14)
            .fill('#2196F3')
          // 中间不设置 radius，就是直角

          // 3. 压力 - 灰色（右侧圆角）
          Rect()
            .width(this.negativeWidth)
            .height(14)
            .fill('#9E9E9E')
            .radius([[0, 0], [7, 7], [7, 7], [0, 0]])
        }
        .width('100%')
        .clip(true) // 确保内容不溢出
        .shadow({ radius: 2, color: '#10000000', offsetY: 1 }) // 给比例条加个微弱投影，更立体

        // 图例说明：解决“黄色不知道啥意思”的问题
        Row() {
          this.LegendItem('#4CAF50', '积极')
          this.LegendItem('#2196F3', '平稳')
          this.LegendItem('#9E9E9E', '压力/内耗')
        }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 10 })
      }
      .width('92%')
      .padding(18)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 20, color: '#08000000' })
      .margin({ top:10,bottom: 10 })

      // --- 可滚动区域：AI 周报 ---
      Scroll() {
        Column() { // 容器 1
          Column() { // 蓝色卡片容器 2
            Row() {
              Image($r('app.media.ai')).width(22).height(22)
              Text(' AI 深度报告').fontSize(16).fontWeight(FontWeight.Bold).margin({ left: 8 })
            }.width('100%').margin({ bottom: 12 })

            if (this.isAnalyzing) {
              Column() {
                LoadingProgress().width(40).height(40).color('#007DFF')
                Text('正在解析你的情绪流...').fontSize(13).fontColor('#999').margin({ top: 10 })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .width('100%')
            } else {
              Text(this.aiContent)
                .fontSize(15)
                .lineHeight(26)
                .fontColor('#444')
                .width('100%') // 确保文字撑开宽度
            }
          }
          .width('92%')
          .padding(20)
          .backgroundColor('#F5FAFF')
          .borderRadius(16)
          .border({ width: 1, color: '#E1EFFF' })
          /* 💡 核心优化：
             在 Scroll 嵌套 Column 时，minHeight 需要减去 margin 的空间，
             或者干脆直接用 layoutWeight(1) 让它在父容器里伸展。
          */
          .constraintSize({ minHeight: '100%' })
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        // 💡 关键：这里不要写死 height('100%')，有时会导致滚动失效
        // 而是确保 Column 内部能够撑开
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ top: 10, bottom: 10 })
      .padding({ bottom: 20 }) // 给底部留一点点呼吸空间
      .edgeEffect(EdgeEffect.Spring)

      // --- 底部：分析按钮 ---
      Stack({ alignContent: Alignment.Bottom }) {
        Button('开始 AI 深度分析')
          .width('85%')
          .height(50)
          .margin({ bottom: 20 })
          .linearGradient({
            direction: GradientDirection.Left,
            colors: [['#007DFF', 0.0], ['#00BFFF', 1.0]]
          })
          .shadow({ radius: 10, color: '#40007DFF' })
          .enabled(!this.isAnalyzing)
          .onClick(async () => {
            await this.handleStartAnalyze()
          })
      }.width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  // 辅助方法：图例组件
  @Builder LegendItem(color: string, label: string) {
    Row() {
      Circle().width(8).height(8).fill(color).margin({ right: 5 })
      Text(label).fontSize(12).fontColor('#666')
    }
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