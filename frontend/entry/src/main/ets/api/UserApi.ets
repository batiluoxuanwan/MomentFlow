import http from '@ohos.net.http'
import { User } from '../model/User'
import { UserDto } from '../model/UserDto'
import { R } from '../model/R' // 💡 引入统一返回模型接口
import fs from '@ohos.file.fs';
import { buffer } from '@kit.ArkTS';

const BASE_URL = 'http://10.0.2.2:8080/api/user'

// 基础请求工具：适配后端 R<T> 协议
function request<T>(url: string, options: http.HttpRequestOptions): Promise<T | null> {
  return new Promise<T | null>((resolve, reject) => {
    const httpRequest = http.createHttp()

    httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
      httpRequest.destroy()
      if (err) {
        reject(err)
        return
      }

      const resultString = data.result as string
      if (!resultString || resultString.trim() === "") {
        resolve(null)
        return
      }

      try {
        // 💡 核心逻辑：先解析为 R<T>
        const response: R<T> = JSON.parse(resultString) as R<T>

        // 判断业务状态码
        if (response.code === 200) {
          resolve(response.data) // 成功：返回具体业务数据
        } else {
          // 失败：把后端 R.error(msg) 里的提示语抛出
          reject(new Error(response.msg))
        }
      } catch (e) {
        reject(new Error("USER_JSON_PARSE_ERROR"))
      }
    })
  })
}

export class UserApi {

  // 发送验证码
  static async sendEmailCode(email: string): Promise<boolean> {
    // 后端返回 R<String>，泛型传 string
    const res = await request<string>(`${BASE_URL}/sendCode`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({ email: email })
    })
    return res !== null;
  }

  // 注册
  static async register(user: User, code: string): Promise<User | null> {
    return request<User>(`${BASE_URL}/register`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({
        username: user.username,
        email: user.email,
        password: user.password,
        code: code
      })
    })
  }

  // 登录
  static async login(account: string, pass: string): Promise<User | null> {
    return request<User>(`${BASE_URL}/login`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({
        "account": account,
        "password": pass
      })
    })
  }

  // 修改资料
  static async update(id: number, userDto: UserDto): Promise<User | null> {
    return request<User>(`${BASE_URL}/${id}`, {
      method: http.RequestMethod.PUT,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify(userDto)
    })
  }

  // 💡 修复：合并并清理原有的两个 updatePassword，消除 any
  static async updatePassword(userId: number, oldPass: string, newPass: string): Promise<boolean> {
    const res = await request<string>(`${BASE_URL}/updatePassword`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({
        userId: userId,
        oldPass: oldPass,
        newPass: newPass
      })
    })
    return res !== null;
  }

  // 删除/注销
  static async delete(id: number): Promise<boolean> {
    const res = await request<string>(`${BASE_URL}/${id}`, {
      method: http.RequestMethod.DELETE
    })
    return res !== null
  }

  static async uploadAvatar(uri: string): Promise<string | null> {
    // 1. 读取文件并转为 Base64
    let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    let stat = fs.statSync(file.fd);
    let buf = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buf);
    fs.closeSync(file);

    // 将 ArrayBuffer 转为 Base64 字符串
    let base64Str = buffer.from(buf).toString('base64');

    // 2. 复用你现有的 request 工具函数
    // 这里的 T 传 string，因为后端 R<String> 返回的是 URL 字符串
    return request<string>(`${BASE_URL}/upload-avatar-base64`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      // 将 base64 放在对象里发过去
      extraData: JSON.stringify({
        "image": base64Str
      })
    });
  }

}