import { Diary } from '../model/Diary'
import { User } from '../model/User' // 💡 记得导入 User 模型
import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'

@Component
export struct MinePage {
  @StorageProp('diaries') diaries: Diary[] = []
  // 💡 获取全局存储的登录用户信息
  @StorageProp('user') user: User | null = null

  aboutToAppear() {
    // 💡 打印一下，看看全局存储里现在到底存了什么
    const globalUser = AppStorage.get<User>('user')
    console.info('DEBUG_MINE: 当前全局存储中的用户信息为: ' + JSON.stringify(globalUser))

    // 如果全局有，但本地没拿到，强制同步一次
    if (globalUser && !this.user) {
      this.user = globalUser
    }
  }

  getTotalWords(): string {
    if (!this.diaries || this.diaries.length === 0) {
      return '0';
    }

    let total = 0;
    this.diaries.forEach(diary => {
      // 累计每篇日记内容的长度
      if (diary.content) {
        total += diary.content.length;
      }
    });

    // 💡 演示小技巧：如果字数很多，显示为 k (千) 结尾，显得更高级
    if (total >= 1000) {
      return (total / 1000).toFixed(1) + 'k';
    }
    return total.toString();
  }

  @Builder
  SettingItem(icon: Resource, title: string, rightText: string = '', action: () => void = () => {}) {
    Row() {
      Image(icon).width(22).height(22).margin({ right: 12 })
      Text(title).fontSize(16).fontColor('#333')
      Blank()
      Text(rightText).fontSize(14).fontColor('#999').margin({ right: 4 })
      Image($r('sys.media.ohos_ic_public_arrow_right')).width(18).height(18).fillColor('#CCC')
    }
    .width('100%').height(56).padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .onClick(() => action())
  }

  build() {
    Column() {
      // 1. 头部卡片
      Column() {
        Row() {
          // 💡 头像适配：如果用户没有头像，使用默认占位图
          Image(this.user?.avatar || $r('app.media.user_placeholder'))
            .width(70).height(70).borderRadius(35).margin({ right: 16 })

          Column() {
            // 💡 替换：使用真实用户名
            Text(this.user?.username || '未登录用户')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)

            // 💡 替换：使用真实签名
            Text(this.user?.signature || '暂无个性签名')
              .fontSize(14).fontColor('#CCFFFFFF').margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start)
        }
        .width('100%').padding({ top: 40, bottom: 30, left: 24 })

        Row() {
          Column() {
            Text(this.diaries.length.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
            Text('日记篇数').fontSize(12).fontColor('#CCFFFFFF')
          }.layoutWeight(1)
          Divider().vertical(true).height(20).color('#40FFFFFF')
          Column() {
            Text(this.getTotalWords()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
            Text('总字数').fontSize(12).fontColor('#CCFFFFFF')
          }.layoutWeight(1)
        }.padding({ bottom: 20 })
      }
      .backgroundColor('#007DFF').borderRadius({ bottomLeft: 24, bottomRight: 24 })

      // 2. 列表
      List() {
        ListItem() {
          Column() {
            this.SettingItem($r('app.media.edit'), '编辑资料',"",() => {router.pushUrl({ url: 'pages/EditProfilePage' })})
            Divider().margin({ left: 50, right: 16 }).color('#F2F2F2')
            this.SettingItem($r('app.media.security'), '账号安全',"",() => router.pushUrl({ url: 'pages/SecurityPage' }))
          }.backgroundColor(Color.White).borderRadius(12).margin({ top: 20 }).clip(true)
        }
        ListItem() {
          Column() {
            this.SettingItem($r('app.media.about'), '关于我们', 'v1.0.0',() => {
              router.pushUrl({
                url: 'pages/WebPage',
                params: {
                  // url: 'https://github.com/batiluoxuanwan/MomentFlow', // 密码的打不开
                  url: 'https://gitee.com/GleeDean/MomentFlow',
                  title: '项目源码'
                }
              })
            })
          }.backgroundColor(Color.White).borderRadius(12).margin({ top: 12 }).clip(true)
        }
        ListItem() {
          Button('退出登录').width('100%').height(50).backgroundColor(Color.White)
            .fontColor(Color.Red).margin({ top: 30 }).borderRadius(12)
            .onClick(() => {
              // 1. 清空全局状态
              AppStorage.setOrCreate('user', null)
              AppStorage.setOrCreate('diaries', [])

              // 2. 跳转回登录页
              router.replaceUrl({ url: 'pages/LoginPage' })

              promptAction.showToast({ message: '已退出登录' })
            })
        }
      }
      .layoutWeight(1).padding({ left: 16, right: 16 })
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}