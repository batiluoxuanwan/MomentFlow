package com.example.momentflow.controller;

import com.example.momentflow.common.R; // 💡 导入你刚创建的 R 类
import com.example.momentflow.entity.Diary;
import com.example.momentflow.service.DiaryService;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/diary")
@RequiredArgsConstructor
@CrossOrigin
public class DiaryController {

    private final DiaryService diaryService;

    @GetMapping("/ping")
    public R<String> ping() {
        return R.success("pong");
    }

    // --- 1. 获取指定用户的日记列表 ---
    @GetMapping("/user/{userId}")
    public R<List<Diary>> getMyDiaries(@PathVariable Long userId) {
        List<Diary> diaries = diaryService.findByUserId(userId);
        return R.success(diaries);
    }

    // 💡 建议保留但改为返回 R
    @GetMapping
    public R<List<Diary>> list() {
        return R.success(diaryService.list());
    }

    @GetMapping("/{id}")
    public R<Diary> detail(@PathVariable Long id) {
        Diary diary = diaryService.getById(id);
        if (diary == null) {
            return R.error("日记不存在");
        }
        return R.success(diary);
    }

    @PostMapping
    public R<Diary> create(@RequestBody Diary diary) {
        // 打印调试，确保 userId 传过来了
        System.out.println("Saving diary for user: " + diary.getUserId());
        return R.success(diaryService.save(diary));
    }

    @PutMapping("/{id}")
    public R<Diary> update(@PathVariable Long id, @RequestBody Diary diary) {
        diary.setId(id);
        return R.success(diaryService.save(diary));
    }

    @DeleteMapping("/{id}")
    public R<String> delete(@PathVariable Long id) {
        diaryService.delete(id);
        return R.success("删除成功");
    }
    @GetMapping("/export/pdf/{id}")
    public void exportPdf(@PathVariable Long id, HttpServletResponse response) throws Exception {
        Diary diary = diaryService.getById(id);

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=diary.pdf");

        PdfWriter writer = new PdfWriter(response.getOutputStream());
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf);

        // 💡 写入内容
        document.add(new Paragraph(diary.getTitle()).setBold().setFontSize(20));
        document.add(new Paragraph("时间：" + diary.getCreateTime() + "  心情：" + diary.getMood()));
        document.add(new Paragraph("\n" + diary.getContent()));

        document.close();
    }
}