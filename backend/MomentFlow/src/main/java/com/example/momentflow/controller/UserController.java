package com.example.momentflow.controller;

import com.example.momentflow.common.R; // 💡 导入你的封装类
import com.example.momentflow.entity.User;
import com.example.momentflow.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@RestController
@CrossOrigin
@RequestMapping("/api/user")
public class UserController {
    @Value("${spring.mail.username}")
    private String fromEmail;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JavaMailSender mailSender;

    @Autowired
    private StringRedisTemplate redisTemplate;

    // --- 1. 发送验证码 ---
    @PostMapping("/sendCode")
    public R<String> sendCode(@RequestBody Map<String, String> req) {
        String email = req.get("email");
        String code = String.valueOf((int)((Math.random()*9+1)*100000));

        redisTemplate.opsForValue().set("CODE:" + email, code, 5, TimeUnit.MINUTES);

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("验证码");
        message.setText("您的验证码是：" + code);
        mailSender.send(message);

        return R.success("发送成功");
    }

    // --- 2. 注册 ---
    @PostMapping("/register")
    public R<User> register(@RequestBody Map<String, String> req) {
        String email = req.get("email");
        String code = req.get("code");

        if (userRepository.existsByEmail(email)) {
            return R.error("该邮箱已被注册");
        }

        String savedCode = redisTemplate.opsForValue().get("CODE:" + email);
        if (savedCode == null || !savedCode.equals(code)) {
            return R.error("验证码错误");
        }

        User user = new User();
        user.setUsername(req.get("username"));
        user.setEmail(email);
        user.setPassword(req.get("password"));
        user.setSignature(req.get("signature"));

        return R.success(userRepository.save(user));
    }

    // --- 3. 获取个人资料 ---
    @GetMapping("/{id}")
    public R<User> getProfile(@PathVariable Long id) {
        return userRepository.findById(id)
                .map(R::success)
                .orElse(R.error("用户不存在"));
    }

    // --- 4. 修改个人资料 ---
    @PutMapping("/{id}")
    public R<User> updateProfile(@PathVariable Long id, @RequestBody User newUser) {
        return userRepository.findById(id).map(user -> {
            user.setUsername(newUser.getUsername());
            user.setSignature(newUser.getSignature());
            user.setAvatar(newUser.getAvatar());
            return R.success(userRepository.save(user));
        }).orElse(R.error("用户不存在"));
    }

    // --- 5. 修改密码 ---
    @PostMapping("/updatePassword")
    public R<String> updatePassword(@RequestBody Map<String, Object> req) {
        Long userId = Long.valueOf(req.get("userId").toString());
        String oldPass = req.get("oldPass").toString();
        String newPass = req.get("newPass").toString();
        Optional<User> userOpt = userRepository.findById(userId);
        // 1. 判断用户是否存在
        if (userOpt.isEmpty()) {
            return R.error("用户不存在");
        }
        User user = userOpt.get();
        // 2. 校验原密码
        if (!user.getPassword().equals(oldPass)) {
            return R.error("原密码错误");
        }
        // 3. 执行修改
        user.setPassword(newPass);
        userRepository.save(user);
        return R.success("修改成功");
    }

    // --- 6. 登录 ---
    @PostMapping("/login")
    public R<User> login(@RequestBody Map<String, String> req) {
        String account = req.get("account");
        String password = req.get("password");

        Optional<User> userOpt = userRepository.findByUsernameOrEmail(account, account);

        if (userOpt.isEmpty()) {
            return R.error("账号不存在");
        }

        User user = userOpt.get();
        if (!user.getPassword().equals(password)) {
            return R.error("密码错误");
        }

        return R.success(user); // 💡 这样编译器明确知道返回的是 R<User>
    }

    // --- 7. 注销账号 ---
    @DeleteMapping("/{id}")
    public R<String> deleteUser(@PathVariable Long id) {
        userRepository.deleteById(id);
        return R.success("注销成功");
    }
//    @PostMapping("/upload-avatar-base64")
//    public R<String> uploadAvatarBase64(@RequestBody Map<String, String> params) {
//        String base64Image = params.get("image");
//        if (base64Image == null) return R.error("未接收到图片数据");
//
//        try {
//            // 1. 解码
//            byte[] imageBytes = Base64.getDecoder().decode(base64Image);
//
//            // 2. 存储 (同之前逻辑)
//            String fileName = UUID.randomUUID().toString() + ".jpg";
//            String folderPath = System.getProperty("user.dir") + "/static/uploads/";
//            Files.write(Paths.get(folderPath + fileName), imageBytes);
//
//            // 3. 返回可访问 URL
//            String fileUrl = "http://10.0.2.2:8080/uploads/" + fileName;
//            return R.success(fileUrl);
//        } catch (Exception e) {
//            return R.error("图片解析失败");
//        }
//    }
    @PostMapping("/upload-avatar-base64")
    public R<String> uploadAvatarBase64(@RequestBody Map<String, String> params) {
        System.out.println("======= 收到头像上传请求 (Base64模式) =======");

        String rawBase64 = params.get("image");
        if (rawBase64 == null || rawBase64.isEmpty()) {
            return R.error("未接收到图片数据");
        }

        try {
            // 1. 统一格式：确保我们存入数据库的是带前缀的标准 Base64 格式
            String base64ToStore;
            if (rawBase64.contains(",")) {
                base64ToStore = rawBase64; // 已经带前缀了 (data:image/jpeg;base64,xxx)
            } else {
                base64ToStore = "data:image/jpeg;base64," + rawBase64;
            }

            // 2. (可选) 你依然可以把文件存到硬盘备份，但返回给前端的是字符串
            // ... 之前的保存文件逻辑可以保留，也可以删掉只存数据库 ...

            // 3. 返回处理好的完整 Base64 字符串
            System.out.println("返回 Base64 字符串给前端，预览长度: " + base64ToStore.substring(0, 50) + "...");

            // 💡 这样返回后，前端 UserApi 会拿到这个长字符串，并存入数据库 avatar 字段
            return R.success(base64ToStore);

        } catch (Exception e) {
            e.printStackTrace();
            return R.error("头像处理失败");
        }
    }
}