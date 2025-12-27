import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { User } from '../model/User'
import { UserApi } from '../api/UserApi'

@Entry
@Component
struct LoginPage {
  @State account: string = ''
  //@State username: string = ''
  @State pass: string = ''
  @State isLoading: boolean = false

  async handleLogin() {
    if (!this.account || !this.pass) {
      promptAction.showToast({ message: '请输入账号密码' })
      return
    }
    this.isLoading = true;
    try {
      const res = await UserApi.login(this.account, this.pass)
      // 💡 只有确实拿到了 user 对象（且包含 ID）才认为登录成功
      if (res && res.id !== undefined) {
        const user: User = res;
        AppStorage.setOrCreate<User>('user', user)
        promptAction.showToast({ message: '欢迎回来，' + user.username })
        router.replaceUrl({ url: 'pages/MainPage' })
      } else {
        promptAction.showToast({ message: '登录信息无效' })
      }
    } catch (error) {
      // 💡 现在 405 错误会进入这里，而不会跳转页面
      const err = error as Error
      promptAction.showToast({ message: '登录失败：账号或密码错误' })
      console.error('Login Error:', err.message)
    }finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Text('欢迎回来').fontSize(28).fontWeight(FontWeight.Bold).margin({ top: 80, bottom: 40 })

      TextInput({ placeholder: '请输入账号', text: this.account })
        .onChange(v => this.account = v).width('90%').height(50).margin({ bottom: 20 })

      TextInput({ placeholder: '请输入密码', text: this.pass })
        .type(InputType.Password).onChange(v => this.pass = v).width('90%').height(50)

      Button(this.isLoading ? '正在登录...' : '登录')
        .width('90%').height(50).margin({ top: 40 })
        .enabled(!this.isLoading)
        .onClick(() => this.handleLogin())

      Text('没有账号？立即注册').fontColor('#007DFF').margin({ top: 20 })
        .onClick(() => router.pushUrl({ url: 'pages/RegisterPage' }))
    }.width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}