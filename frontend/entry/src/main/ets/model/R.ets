// model/R.ts
export interface R<T> {
  code: number;    // 业务状态码 (200成功, 500失败)
  msg: string;     // 后端返回的提示信息
  data: T;         // 泛型数据主体
}