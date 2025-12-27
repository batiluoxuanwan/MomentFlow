package com.example.momentflow.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDateTime;

@Entity
@Table(name = "diary")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Diary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String mood;

    @Column(columnDefinition = "TEXT")
    private String content;

    // 💡 新增：所属用户ID，用于数据隔离
    @Column(name = "user_id")
    private Long userId;

    @CreatedDate
    @Column(updatable = false) // 只有创建时插入，后续不更新
    private LocalDateTime createTime;

    @LastModifiedDate
    private LocalDateTime updateTime;
}