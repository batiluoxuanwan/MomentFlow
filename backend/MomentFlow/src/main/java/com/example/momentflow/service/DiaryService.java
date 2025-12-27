package com.example.momentflow.service;

import com.example.momentflow.entity.Diary;

import java.util.List;

public interface DiaryService {

    List<Diary> list();

    Diary getById(Long id);

    Diary save(Diary diary);

    void delete(Long id);

    List<Diary> findByUserId(Long userId);
}
