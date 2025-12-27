package com.example.momentflow.repository;

import com.example.momentflow.entity.Diary;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DiaryRepository extends JpaRepository<Diary, Long> {
    List<Diary> findByUserIdOrderByCreateTimeDesc(Long userId);
}
