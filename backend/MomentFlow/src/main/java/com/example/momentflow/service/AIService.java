package com.example.momentflow.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import okhttp3.*;
import org.springframework.stereotype.Service;
import java.util.concurrent.TimeUnit;

@Service
public class AIService {
    private final String API_KEY = "sk-15f449bec2a94cb383e9e5eeb1e69854";
    private final String BASE_URL = "https://api.deepseek.com/chat/completions";
    private final ObjectMapper objectMapper = new ObjectMapper();

    public String analyzeMood(String diaryContent) {
        OkHttpClient client = new OkHttpClient.Builder()
                .connectTimeout(60, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .build();

        try {
            ObjectNode rootNode = objectMapper.createObjectNode();
            rootNode.put("model", "deepseek-chat");

            ArrayNode messages = rootNode.putArray("messages");

            // 💡 调教点 1：强化性格，彻底封印“列表思维”
            String systemPrompt = "你叫'小流'，是知性、温暖的心理知己。" +
                    "【回复规范】：\n" +
                    "1. 像老朋友聊天一样自然对话，严禁使用 1.2.3. 或任何分类标题。字数控制在150字以内\n" +
                    "2. 仅在开头、结尾及核心情感处点缀 3-5 个 Emoji，禁止堆砌。\n" +
                    "3. 全文禁止 Markdown 符号，段落间不准空行（到结尾换行但是也不空行）。\n" +
                    "4. 结尾严格遵守此格式：\n" +
                    "————————————\n" +
                    "💡 小流的建议\n" +
                    "（此处写一句生活建议：推荐今天立马可以做的一件独处也让人快乐的小事）";

            messages.addObject().put("role", "system").put("content", systemPrompt);

            // 💡 调教点 2：结构化 Prompt（针对一周日记合集优化）
            // 💡 调教点 2：模糊化指引，避免 AI 复读标题
            String userPrompt = "小流，这是我最近一周的日记：\n" +
                    "----------\n" +
                    diaryContent + "\n" +
                    "----------\n" +
                    "请帮我读一读这些文字。我想听听你发现了我这周心情有什么样的起伏？" +
                    "如果有快乐的瞬间，请和我一起分享；如果有不开心，也请抱抱我。" +
                    "最后，别忘了给我一个下周的小建议。" +
                    "注意：字数150字左右，禁止使用 Markdown 符号（如 **、#、-），不要分点，要像老朋友一样直接对话。";

            messages.addObject().put("role", "user").put("content", userPrompt);

            RequestBody body = RequestBody.create(
                    objectMapper.writeValueAsString(rootNode),
                    MediaType.parse("application/json")
            );

            Request request = new Request.Builder()
                    .url(BASE_URL)
                    .addHeader("Authorization", "Bearer " + API_KEY)
                    .post(body)
                    .build();

            try (Response response = client.newCall(request).execute()) {
                String responseBody = response.body() != null ? response.body().string() : "";
                if (response.isSuccessful()) {
                    JsonNode resJson = objectMapper.readTree(responseBody);
                    return resJson.path("choices").get(0).path("message").path("content").asText();
                } else {
                    return "小流正在整理思绪，请稍后再来找我吧。(Error: " + response.code() + ")";
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "AI 引擎连接失败：" + e.getMessage();
        }
    }
}