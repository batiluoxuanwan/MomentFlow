import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { UserApi } from '../api/UserApi'
import { User } from '../model/User'

@Entry
@Component
struct SecurityPage {
  @State oldPass: string = ''
  @State newPass: string = ''
  @State confirmPass: string = ''

  @StorageProp('user') user: User | null = null

  build() {
    Column() {
      Row() {
        Text('返回').onClick(() => router.back())
        Text('修改密码').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 40 })
      }.width('100%').padding(16)

      Column() {
        TextInput({ placeholder: '原密码' }).type(InputType.Password).onChange(v => this.oldPass = v).height(60)
        Divider().color('#F2F2F2')
        TextInput({ placeholder: '新密码' }).type(InputType.Password).onChange(v => this.newPass = v).height(60)
        Divider().color('#F2F2F2')
        TextInput({ placeholder: '确认新密码' }).type(InputType.Password).onChange(v => this.confirmPass = v).height(60)
      }
      .backgroundColor(Color.White).borderRadius(12).margin(16).padding({ left: 12, right: 12 })

      Button('确认提交').width('90%').height(50).margin({ top: 40 })
        .onClick(async () => {
          if (this.newPass !== this.confirmPass) {
            promptAction.showToast({ message: '两次密码输入不一致' })
            return
          }
          // 💡 2. 调用接口发起修改密码请求
          if (this.user === null || this.user.id === undefined) {
            promptAction.showToast({ message: '用户登录已失效' })
            return
          }

          // 💡 此时 ArkTS 知道 this.user.id 一定是 number 类型
          const userId: number = this.user.id
          try {
            // 调用带 userId 的版本
            const success = await UserApi.updatePassword(userId, this.oldPass, this.newPass)

            if (success) {
              promptAction.showToast({ message: '密码修改成功' })
              // 修改成功后通常建议用户重新登录
              router.back()
            }
          } catch (error) {
            // 💡 重点：这里的 error.message 会捕获后端 R.error("原密码错误") 里的提示内容
            const err = error as Error
            promptAction.showToast({ message: err.message })
          }
        })
    }.width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}