package com.example.momentflow.controller;

import com.example.momentflow.common.R;
import com.example.momentflow.entity.Diary;
import com.example.momentflow.service.AIService;
import com.example.momentflow.service.DiaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@CrossOrigin
public class AIController {

    private final AIService aiService;
    private final DiaryService diaryService;

    @PostMapping("/analyze")
    public R<String> analyze(@RequestBody Map<String, Long> req) {
        // 1. 安全获取 userId
        Object userIdObj = req.get("userId");
        if (userIdObj == null) return R.error("用户ID不能为空");
        Long userId = Long.valueOf(userIdObj.toString());

        // 2. 获取所有日记
        List<Diary> allDiaries = diaryService.findByUserId(userId);
        if (allDiaries == null || allDiaries.isEmpty()) {
            return R.error("你还没有写过日记，我没法为你分析呀~");
        }

        // 💡 核心修改：过滤出“最近 7 天”的日记
        LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);

        List<Diary> weekDiaries = allDiaries.stream()
                .filter(d -> d.getCreateTime() != null && d.getCreateTime().isAfter(sevenDaysAgo))
                .sorted((a, b) -> b.getCreateTime().compareTo(a.getCreateTime())) // 确保按时间倒序
                .collect(Collectors.toList());

        if (weekDiaries.isEmpty()) {
            return R.error("你最近一周没有写日记，建议先去记录一下生活哦！");
        }

        // 3. 拼接内容给 AI
        StringBuilder sb = new StringBuilder();
        sb.append("这是一份用户「最近一周」的日记合集，请进行情绪趋势分析：\n");

        for (Diary d : weekDiaries) {
            sb.append("【").append(d.getCreateTime().toLocalDate()).append("】")
                    .append("内容：").append(d.getContent()).append("\n");
        }

        // 4. 调用 AI Service
        // 💡 可以在这里微调下提示词，让 AI 知道这是“周报”
        String aiAdvice = aiService.analyzeMood(sb.toString());

        return R.success(aiAdvice);
    }
}