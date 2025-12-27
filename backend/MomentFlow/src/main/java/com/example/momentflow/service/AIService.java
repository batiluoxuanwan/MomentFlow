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

            // 💡 调教点 1：设定深刻的角色人格
            String systemPrompt = "你是一个专业且充满感性共情能力的心理咨询师，你的名字叫'小流'。" +
                    "你的说话风格：温暖、治愈、像老朋友一样聊天。" +
                    "你的任务：阅读用户的日记，精准识别文字背后的情绪（如焦虑、喜悦、怀念等），并给予深度共鸣。" +
                    "💡 格式要求：禁止使用 Markdown 语法（不要使用 **、##、-、> 等符号）。" +
                    "使用纯文本回复，重点内容可以用「」括号强调，段落之间使用清晰的换行。";

            messages.addObject().put("role", "system").put("content", systemPrompt);

            // 💡 调教点 2：结构化 Prompt（针对一周日记合集优化）
            String userPrompt = "这是我「最近一周」的日记内容合集：\n" +
                    "----------\n" +
                    diaryContent + "\n" + // 这里的 diaryContent 已经是你拼接好的多篇日记
                    "----------\n" +
                    "请根据这一周的记录进行深度复盘,输出时可以从以下方面去考虑：\n" +
                    "1. 情绪扫描：通过这些天的记录，你发现我这周整体的心情基调是怎样的？是否有波动？\n" +
                    "2. 共情共鸣：分享我记录中的快乐细节，或温柔地回应我这周遇到的困惑。\n" +
                    "3. 寄语：给我一个充满力量的下周生活寄语。\n" +
                    "注意：字数150字左右，必须使用纯文本，禁止任何 Markdown 符号（如 **、#、-），保持亲切的语气。且回答不可以直接暴露的按照‘1.情绪扫描：xxx’的格式回复，直接回复内容即可";

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