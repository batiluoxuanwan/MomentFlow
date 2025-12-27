package com.example.momentflow.service.impl;

import com.example.momentflow.entity.Diary;
import com.example.momentflow.repository.DiaryRepository;
import com.example.momentflow.service.DiaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DiaryServiceImpl implements DiaryService {

    private final DiaryRepository diaryRepository;

    @Override
    public List<Diary> list() {
        return diaryRepository.findAll();
    }

    @Override
    public Diary getById(Long id) {
        return diaryRepository.findById(id).orElse(null);
    }

    @Override
    public Diary save(Diary diary) {
        if (diary.getCreateTime() == null) {
            diary.setCreateTime(LocalDateTime.now());
        }
        return diaryRepository.save(diary);
    }

    @Override
    public void delete(Long id) {
        diaryRepository.deleteById(id);
    }

    @Override
    public List<Diary> findByUserId(Long userId) {
        // 调用我们之前在 Repository 定义的排序查询
        return diaryRepository.findByUserIdOrderByCreateTimeDesc(userId);
    }
}
