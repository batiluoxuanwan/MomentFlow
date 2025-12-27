import { request } from '../utils/HttpUtil'
import { http } from '@kit.NetworkKit';

// AI 回复的消息体
export interface AiMessage {
  role: string;
  content: string;
}

// AI 返回的选择项
export interface AiChoice {
  index: number;
  message: AiMessage;
  finish_reason: string;
}

// DeepSeek/OpenAI 标准响应结构
interface GeneratedTypeLiteralInterface_1 {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

export interface DeepSeekResponse {
  id: string;
  choices: AiChoice[];
  created: number;
  model: string;
  usage: GeneratedTypeLiteralInterface_1;
}

export class AiApi {
  /**
   * 发送日记给后端，由后端转调 DeepSeek
   * @param userId 用户ID
   * @returns AI 分析后的纯文字内容
   */
  static async analyzeDiary(userId: number): Promise<string> {
    // 💡 泛型传 string，因为我们后端的 R<T> 最终会返回处理好的字符串
    const res = await request<string>('http://10.0.2.2:8080/api/ai/analyze', {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({ userId: userId })
    })

    return res ?? "AI 还没准备好，请稍后再试"
  }
}