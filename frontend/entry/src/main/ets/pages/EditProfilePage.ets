import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import picker from '@ohos.file.picker';
import { User } from '../model/User'
import { UserApi } from '../api/UserApi'
import { UserDto } from '../model/UserDto'

@Entry
@Component
struct EditProfilePage {
  @StorageLink('user') user: User | null = null

  @State tempName: string = ''
  @State tempSign: string = ''
  @State tempAvatar: string = ''
  @State tempEmail: string = ''
  @State isLoading: boolean = false
  @State avatarUri: string = '' // 本地临时显示的图片路径

  // 1. 唤起相册选头像
  async selectAvatar() {
    const photoPicker = new picker.PhotoViewPicker();
    const result = await photoPicker.select({
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    });

    if (result.photoUris.length > 0) {
      const localUri = result.photoUris[0];
      this.tempAvatar = localUri; // 💡 重点：选完立刻在界面上显示本地图片，不要等上传
      this.uploadAvatar(localUri);
    }
  }
  // 2. 上传并同步到 User 对象
  async uploadAvatar(uri: string) {
    if (this.user) {
      try {
        // 1. 获取上传后的 URL
        const remoteUrl: string | null = await UserApi.uploadAvatar(uri);

        // 💡 核心修复：只有当 remoteUrl 不为 null 时才进行赋值
        if (remoteUrl !== null) {
          // 更新本地预览（如果有 tempAvatar 状态）
          this.tempAvatar = remoteUrl;

          // 更新全局 User 对象中的头像地址
          // 在你的代码中修改这一行
          this.user.avatar = remoteUrl + '?t=' + new Date().getTime();

          // 2. 将整个用户信息同步到后端数据库
          // 注意：确保你的 UserApi 中有 update 这个方法，或者使用你定义的 updateProfile
          await UserApi.update(this.user.id, {
            username: this.user.username,
            avatar: this.user.avatar,
            signature: this.user.signature,
            email: this.user.email
          });

          promptAction.showToast({ message: '头像修改成功' });
        } else {
          // 处理返回为 null 的情况
          promptAction.showToast({ message: '上传失败：未获取到图片地址' });
        }
      } catch (e) {
        const error = e as Error;
        promptAction.showToast({ message: '操作失败: ' + error.message });
      }
    }
  }

  aboutToAppear() {
    // 💡 初始化所有字段，确保保存时不为空
    this.tempName = this.user?.username ?? ''
    this.tempSign = this.user?.signature ?? ''
    this.tempAvatar = this.user?.avatar ?? ''
    this.tempEmail = this.user?.email ?? ''
  }

  async handleSave() {
    // 💡 增加安全校验：必须有登录用户且有 ID
    if (!this.user || this.user.id === undefined) {
      promptAction.showToast({ message: '用户信息异常' })
      return
    }

    if (!this.tempName.trim()) {
      promptAction.showToast({ message: '用户名不能为空' })
      return
    }

    this.isLoading = true
    try {
      // 1. 构造 DTO 对象
      const updatedDto: UserDto = {
        username: this.tempName,
        signature: this.tempSign,
        avatar: this.tempAvatar,
        email: this.tempEmail
      }

      // 2. 调用后端接口：传入 id 和 dto
      // 💡 注意：这里必须传两个参数，对应 UserApi.update(id: number, userDto: UserDto)
      const res = await UserApi.update(this.user.id, updatedDto)

      if (res) {
        this.user = res
        promptAction.showToast({ message: '修改成功' })
        router.back()
      }
    } catch (error) {
      const err = error as Error
      promptAction.showToast({ message: err.message || '保存失败' })
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 头部导航
      Row() {
        Text('取消').onClick(() => router.back())
        Text('编辑资料').fontSize(18).fontWeight(FontWeight.Bold)

        if (this.isLoading) {
          LoadingProgress().width(24).height(24)
        } else {
          Text('保存').fontColor('#007DFF')
            .onClick(() => this.handleSave())
        }
      }.width('100%').justifyContent(FlexAlign.SpaceBetween).padding(16)

      // 头像编辑
      Image(this.tempAvatar || $r('app.media.user_placeholder'))
        .width(80).height(80).borderRadius(40).margin(30)
        .onClick(() => {
          this.selectAvatar() // 唤起图库
        })
      Text('点击更换头像').fontSize(14).fontColor('#007DFF').margin({ bottom: 30 })
        .onClick(() => {
          this.selectAvatar() // 唤起图库
        })

      // 输入表单
      Column() {
        // 用户名
        Row() {
          Text('用户名').width(80).fontSize(16)
          TextInput({ text: this.tempName })
            .onChange(v => this.tempName = v)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.End)
        }.height(60).width('100%')

        Divider().color('#F1F3F5').margin({ left: 80 })

        // 个性签名
        Row() {
          Text('个性签名').width(80).fontSize(16)
          TextInput({ text: this.tempSign })
            .onChange(v => this.tempSign = v)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.End)
        }.height(60).width('100%')

        /* --- 💡 邮箱修改功能暂时注释 ---
        Divider().color('#F1F3F5').margin({ left: 80 })
        Row() {
          Text('邮箱').width(80).fontSize(16)
          TextInput({ text: this.tempEmail })
            .onChange(v => this.tempEmail = v)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.End)
        }.height(60).width('100%')
        ------------------------------ */
      }
      .backgroundColor(Color.White)
      .padding({ left: 16, right: 16 })
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

    }.width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}