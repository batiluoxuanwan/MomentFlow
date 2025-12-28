# 🌊 MomentFlow (时间流)

**MomentFlow** 是一款集成了 AI 深度分析的治愈系情绪日记应用。它不仅帮助你记录每个当下的瞬间（Moments），更通过数据流（Flow）的形式，让你洞察自己内心世界的起伏与成长。

------

## 📱 主要功能

### 1. 基础日记管理 (Core)

- **快捷记录**：支持标题、正文及特定情绪标签的录入，快速捕捉当下心情。
- **心情标签**：预设 12 种情绪维度（如：`充满动力`、`平淡放空`、`压力内耗`等），简化记录流程。
- **日记流展示**：以时间倒序排列日记内容，方便回溯过往记录。

### 2. AI 情绪分析（特色功能）

- **“小流”咨询师**：基于大模型调优的 AI 模块，能根据本周日记生成纯文本的复盘报告。
- **知性对话系统**：回复风格更偏向知性对话，自动过滤生硬表达，提升阅读舒适感。
- **生活小建议**：根据分析结果，在报告末尾提供一条针对性、可执行的行动指引。

### 3. 可视化数据统计

- **情绪底色条**：通过绿（积极）、蓝（平稳）、灰（压力）三色比例，利用 ArkUI 属性动画直观呈现近 7 天的情绪构成。

### 4. 账号与安全机制

- **邮箱快捷登录**：采用 SMTP 邮件验证码机制，结合 **Redis** 存储，保障账号唯一性与响应速度。
- **隐私保护**：日记内容端云同步，确保数据在不同设备间的私密性与安全性。

------

## 🛠️ 全栈技术架构

本项目采用前后端分离架构，通过 **RESTful** 协议进行数据交互。

```
MomentFlow-Frontend/src/main/ets/
├── api/                            # 【网络请求层】封装后端 RESTful 接口
│   ├── AIApi.ets                   # AI 情绪分析交互（调用后端 DeepSeek 中转服务）
│   ├── DiaryApi.ets                # 日记业务逻辑（增删改查、分页、导出请求）
│   └── UserApi.ets                 # 用户账户服务（验证码获取、登录、注册）
├── entryability/                   # 【应用入口】生命周期管理
│   └── EntryAbility.ets            # UIAbility 启动与窗口初始化
├── entrybackupability/             # 【备份模块】
│   └── EntryBackupAbility.ets      # 负责应用数据的备份与恢复逻辑
├── model/                          # 【数据模型层】强类型定义与 DTO
│   ├── Diary.ets                   # 日记实体模型（对应后端 Entity）
│   ├── DiaryDto.ets                # 日记传输对象（请求入参封装）
│   ├── R.ets                       # 全局响应体泛型包装（code, msg, data）
│   ├── User.ets                    # 用户信息模型
│   └── UserDto.ets                 # 登录注册交互模型
├── pages/                          # 【视图层】全量交互界面
│   ├── MainPage.ets                # APP 底部 Tabs 导航主框架
│   ├── DiaryPage.ets               # 日记瀑布流主展示页
│   ├── AnalysisPage.ets            # AI 情绪空间（图表渲染与 AI 逻辑）
│   ├── DiaryAdd.ets                # 日记创作页面
│   ├── DiaryDetail.ets             # 日记阅读详页
│   ├── DiaryEdit.ets               # 旧日记内容修改页
│   ├── LoginPage.ets               # 邮箱验证码登录页
│   ├── RegisterPage.ets            # 新用户注册页
│   ├── MinePage.ets                # “我的”个人中心中心页
│   ├── EditProfilePage.ets         # 个人资料设置
│   ├── SecurityPage.ets            # 账号安全管理
│   └── WebPage.ets                 # 内置 H5 容器（用于展示外部内容）
├── store/                          # 【存储层】
│   └── DiaryStore.ets              # 全局状态管理（如本地日记缓存逻辑）
└── utils/                          # 【工具层】通用能力封装
    ├── HttpUtil.ets                # 基于 http.createHttp 的网络拦截器
    └── ExportUtil.ets              # 核心工具：PDF 沙箱写入与系统级分享

MomentFlow-Backend/src/main/java/com/momentflow/
├── DiaryApplication.java           # 【启动类】项目入口与 Spring 容器配置
├── common/                         # 【通用包】
│   └── R.java                      # 后端统一响应结果封装（与前端 R.ets 对应）
├── controller/                     # 【控制层】RESTful 接口暴露
│   ├── AIController.java           # AI 分析中转接口（接入 DeepSeek）
│   ├── DiaryController.java        # 日记业务接口（增删改查逻辑分发）
│   └── UserController.java         # 用户账户接口（邮件发送、鉴权控制）
├── entity/                         # 【实体层】MySQL 表结构 ORM 映射
│   ├── Diary.java                  # 日记实体类（对应数据库表 diary）
│   └── User.java                   # 用户实体类（对应数据库表 user）
├── repository/                     # 【持久化层】Spring Data JPA 接口
│   ├── DiaryRepository.java        # 日记数据访问（含自定义分页查询）
│   └── UserRepository.java         # 用户数据访问（含邮箱唯一性校验）
└── service/                        # 【业务层】核心逻辑处理
    ├── AIService.java              # AI 业务接口定义
    ├── DiaryService.java           # 日记业务接口定义
    └── impl/                       # 【业务实现】
        └── DiaryServiceImpl.java   # 核心实现：处理保存逻辑与时间轴排序
```

### 1. 前端 (Client) - HarmonyOS

- **开发框架**：ArkUI (ArkTS)
- **状态管理**：使用 `@State`、`@Prop`、`@Link` 以及 `@Watch` 构建响应式数据流。
- **网络请求**：基于 `HttpUtil` 模块封装的异步请求工具。

### 2. 后端 (Backend) - Java

- **核心框架**：Java 17 / Spring Boot 3.2.1
- **持久层**：Spring Data JPA (实现对象关系映射 ORM)。
- **能力集成**：
  - **Mail Starter**：集成 SMTP 协议发送登录验证码。
  - **OkHttp3**：作为客户端对接 **DeepSeek API** 获取 AI 情绪分析报告。
  - **Redis**：实现 5 分钟内有效的临时验证码高速校验。
  - **iText7**：支持生成 PDF 格式的报告导出。

### 3. 数据存储 (Storage)

- **MySQL**：用于存储用户信息、日记文本、情绪标签及时间戳。
- **Redis**：作为高速缓存，减轻数据库压力，提升并发性能。

------

## 🚀 快速启动

### 1. 环境准备

- **前端**：安装 DevEco Studio (5.0.3+) 和 HarmonyOS SDK (API 12+)。准备真机或 DevEco 虚拟机。
- **后端**：配置 JDK 17 和 Maven 3.6+。
- **中间件**：
  - 启动 **Redis** 服务（默认端口 6379）。
  - 启动 **MySQL** 服务，创建数据库 `momentflow` 并执行初始化脚本。

### 2. 配置与运行

- **邮件配置**：在 `application.properties` 中填写 SMTP 授权码。
- **AI 配置**：在后端配置文件中填入你的 **DeepSeek API Key**。
- **启动流程**：
  1. 先启动后端 Spring Boot 项目（确保 Redis 已开启）。
  2. 在前端项目中将 API `BaseURL` 修改为后端服务 IP。
  3. 点击 DevEco Studio 的运行按钮，部署 MomentFlow。

------

## 🌿 关于 MomentFlow

生活不是静止的，它是不断流动的瞬间。**MomentFlow** 希望通过科技的力量，让你在每一个流动的瞬间里，都能找到属于自己的平衡与力量。