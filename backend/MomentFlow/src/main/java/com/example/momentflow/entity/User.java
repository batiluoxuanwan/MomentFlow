package com.example.momentflow.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "users")
@Data // Lombok 注解
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    private String password; // 生产环境记得加密

    @Column(unique = true, nullable = false)
    private String email;

    private String signature;
    private String avatar;
}