export interface User {
  id: number;
  username: string;
  signature: string; // 个性签名
  avatar: string;    // 头像路径或Base64
  email: string;
  password?: string; // 仅注册登录时使用
}