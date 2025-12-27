import http from '@ohos.net.http'
import { Diary } from '../model/Diary'
import { DiaryDto } from '../model/DiaryDto'
import { R } from '../model/R' // 💡 记得引入我们定义的 R 接口

const BASE_URL = 'http://10.0.2.2:8080/api/diary'

function request<T>(url: string, options: http.HttpRequestOptions): Promise<T | null> {
  return new Promise<T | null>((resolve, reject) => {
    console.log('📤 HTTP Request:', url, options)
    const httpRequest = http.createHttp()

    httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
      httpRequest.destroy()

      if (err) {
        console.error('❌ HTTP Error:', err)
        reject(err)
        return
      }

      const resultString = data.result as string;
      console.log('📥 HTTP Response:', resultString)

      if (!resultString || resultString.trim() === "") {
        resolve(null)
        return
      }

      // 💡 核心修改点：适配后端的 R<T> 结构
      try {
        // 先解析为统一响应格式 R<T>
        const response: R<T> = JSON.parse(resultString) as R<T>

        // 判断后端业务状态码
        if (response.code === 200) {
          // 💡 业务成功，只返回 data 部分
          resolve(response.data)
        } else {
          // 💡 业务失败（如后端返回 R.error），抛出后端给的消息
          reject(new Error(response.msg || '业务请求失败'))
        }
      } catch (e) {
        console.error('❌ JSON Parse Error:', e)
        reject(new Error("数据格式错误"))
      }
    })
  })
}

export class DiaryApi {
  // 获取指定用户的日记列表
  static async getList(userId: number): Promise<Diary[]> {
    const res = await request<Diary[]>(`${BASE_URL}/user/${userId}`, {
      method: http.RequestMethod.GET
    })
    return res ?? []
  }

  // 获取详情
  static async detail(id: number): Promise<Diary | null> {
    return request<Diary>(`${BASE_URL}/${id}`, {
      method: http.RequestMethod.GET
    })
  }

  // 创建日记
  static async create(diary: DiaryDto): Promise<Diary | null> {
    return request<Diary>(BASE_URL, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify(diary)
    })
  }

  // 更新日记
  static async update(id: number, diary: DiaryDto): Promise<Diary | null> {
    return request<Diary>(`${BASE_URL}/${id}`, {
      method: http.RequestMethod.PUT,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify(diary)
    })
  }

  // 删除日记
  static async delete(id: number): Promise<boolean> {
    // 后端现在返回的是 R<String>，所以泛型传 string
    const res = await request<string>(`${BASE_URL}/${id}`, {
      method: http.RequestMethod.DELETE
    })
    return res !== null
  }
}