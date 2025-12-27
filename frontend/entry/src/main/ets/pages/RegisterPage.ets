import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { UserApi } from '../api/UserApi'
import { User } from '../model/User'

@Entry
@Component
struct RegisterPage {
  @State username: string = ''
  @State email: string = ''
  @State verifyCode: string = ''
  @State password: string = ''
  @State confirmPass: string = ''

  // 验证码相关状态
  @State isCountDowning: boolean = false
  @State second: number = 60
  private timerId: number = -1
  @State isLoading: boolean = false

  // 销毁页面时清理定时器，防止内存泄漏
  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  // 验证码倒计时逻辑
  // 验证码倒计时逻辑
  async startCountDown() {
    if (this.isCountDowning) return

    if (!this.email.includes('@')) {
      promptAction.showToast({ message: '请输入正确的邮箱地址' })
      return
    }
    // 1. 💡 先启动本地倒计时逻辑
    this.isCountDowning = true
    this.second = 60
    this.timerId = setInterval(() => {
      if (this.second > 1) {
        this.second--
      } else {
        this.stopCountDown() // 时间到了自动停止
      }
    }, 1000)
    // 2. 💡 再发起网络请求
    try {
      const success = await UserApi.sendEmailCode(this.email)
      if (success) {
        promptAction.showToast({ message: '验证码已发送至邮箱' })
      } else {
        // 如果后端返回失败，重置状态
        this.stopCountDown()
        promptAction.showToast({ message: '发送失败，请检查邮箱是否正确' })
      }
    } catch (e) {
      // 捕获刚才那个 JSON parse error 或者网络错误
      this.stopCountDown()
      promptAction.showToast({ message: '服务器开小差了，请检查后端' })
    }
  }

  stopCountDown() {
    clearInterval(this.timerId)
    this.timerId = -1
    this.isCountDowning = false
    this.second = 60
  }

  build() {
    Column() {
      // 1. 顶部返回
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .onClick(() => router.back())
      }.width('100%').padding(20)

      Text('创建新账号').fontSize(28).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 30 })

      // 2. 注册表单
      Column({ space: 12 }) {
        TextInput({ placeholder: '用户名', text: this.username })
          .onChange(v => this.username = v).width('90%').height(50)

        TextInput({ placeholder: '邮箱地址', text: this.email })
          .onChange(v => this.email = v).width('90%').height(50)

        // --- 验证码输入行 ---
        Row() {
          TextInput({ placeholder: '验证码' })
            .onChange(v => this.verifyCode = v)
            .layoutWeight(1).height(50)

          Button(this.isCountDowning ? `${this.second}s` : '获取验证码')
            .fontSize(10)
            .height(40)
            .margin({ left: 10 })
            .width(100)
            .backgroundColor(this.isCountDowning ? '#F2F2F2' : '#007DFF')
            .fontColor(this.isCountDowning ? '#999' : Color.White)
            .enabled(!this.isCountDowning)
            .onClick(() => this.startCountDown())
        }.width('90%')

        TextInput({ placeholder: '设置密码' })
          .type(InputType.Password).onChange(v => this.password = v).width('90%').height(50)

        TextInput({ placeholder: '确认密码' })
          .type(InputType.Password).onChange(v => this.confirmPass = v).width('90%').height(50)
      }

      // 3. 注册按钮
      Button(this.isLoading ? '正在处理...' : '立即注册')
        .width('90%').height(50).margin({ top: 40 })
        .enabled(!this.isLoading)
        .onClick(() => this.handleRegister())

      Text('注册即代表同意《用户协议》').fontSize(12).fontColor('#999').margin({ top: 15 })

    }.width('100%').height('100%').backgroundColor('#F1F3F5')
  }

  async handleRegister() {
    if (!this.username || !this.email || !this.verifyCode || !this.password) {
      promptAction.showToast({ message: '请完整填写注册信息' })
      return
    }

    if (this.password !== this.confirmPass) {
      promptAction.showToast({ message: '两次密码不一致' })
      return
    }

    this.isLoading = true

    // 构造请求数据
    const newUser: User = {
      id: 0,
      username: this.username,
      email: this.email,
      password: this.password, // 后端校验验证码后处理密码加密
      signature: '记录美好生活',
      avatar: ''
    }

    try {
      const res = await UserApi.register(newUser, this.verifyCode)
      if (res) {
        // 注册成功
        AppStorage.setOrCreate('user', res)
        promptAction.showToast({ message: '注册成功！' })
        router.replaceUrl({ url: 'pages/LoginPage' })
      }
    } catch (e) {
      // 💡 改进：尝试获取后端返回的具体错误消息
      // 比如后端返回 400 时的 "该邮箱已被注册" 或 "验证码错误"
      const errorMsg:string = e.message || '注册失败，请稍后再试'
      promptAction.showToast({ message: errorMsg })
      console.error('注册环节出错:', errorMsg)
    } finally {
      this.isLoading = false
    }
  }
}