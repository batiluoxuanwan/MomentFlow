package com.example.momentflow.common;

import lombok.Data;

@Data
public class R<T> {
    private Integer code;    // 业务状态码：200-成功，500-失败
    private String msg;      // 提示消息
    private T data;          // 数据主体

    public static <T> R<T> success(T data) {
        R<T> r = new R<>();
        r.code = 200;
        r.data = data;
        r.msg = "操作成功";
        return r;
    }

    public static <T> R<T> error(String msg) {
        R<T> r = new R<>();
        r.code = 500;
        r.msg = msg;
        return r;
    }
}