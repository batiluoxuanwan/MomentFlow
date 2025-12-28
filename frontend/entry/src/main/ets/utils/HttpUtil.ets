import http from '@ohos.net.http';
import { R } from '../model/R';

export function request<T>(url: string, options: http.HttpRequestOptions): Promise<T | null> {
  return new Promise<T | null>((resolve, reject) => {
    const httpRequest = http.createHttp();

    httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
      httpRequest.destroy();

      // 1. 网络层校验 (HTTP 状态码)
      if (err || data.responseCode !== 200) {
        reject(new Error("网络连接异常"));
        return;
      }

      try {
        // 2. 这里的 T 是你在调用处传入的类型（如 User 或 string）
        const result: R<T> = JSON.parse(data.result as string) as R<T>;

        // 3. 业务层校验 (后端 R.code)a
        if (result.code === 200) {
          // 💡 业务成功，直接把里面的 data 吐给 Service 层
          resolve(result.data);
        } else {
          // 💡 业务失败（如：原密码错误），将后端给的提示语封装进 Error 抛出
          reject(new Error(result.msg));
        }
      } catch (e) {
        reject(new Error("数据解析失败"));
      }
    });
  });
}