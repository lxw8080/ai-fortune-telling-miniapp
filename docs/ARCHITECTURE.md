# 后端架构设计文档

## 系统架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    微信小程序客户端                           │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                     Nginx 反向代理                           │
│              (HTTPS + 负载均衡 + 静态缓存)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ↓                             ↓
   ┌─────────────┐            ┌─────────────┐
   │  Express    │            │  Express    │
   │  Server 1   │            │  Server 2   │
   │  (Port 3000)│            │  (Port 3001)│
   └──────┬──────┘            └──────┬──────┘
          │                          │
          └──────────────┬───────────┘
                         ↓
      ┌──────────────────┴──────────────────┐
      │                                     │
      ↓                                     ↓
 ┌─────────────┐                    ┌─────────────┐
 │ PostgreSQL  │                    │ Redis Cache │
 │  (主库)     │                    │  (会话/热数据)│
 └─────────────┘                    └─────────────┘
      │
      ↓
 ┌─────────────┐
 │  S3/OSS     │  (可选：存储用户头像等)
 └─────────────┘
      |
      ↓
 ┌──────────────────────────────┐
 │   DeepSeek API               │
 │   (外部 AI 服务)             │
 └──────────────────────────────┘
```

---

## 项目文件结构

```
ai-fortune-backend/
├── src/
│   ├── app.js                           # Express 主程序
│   ├── server.js                        # 启动文件
│   │
│   ├── config/
│   │   ├── database.js                  # PostgreSQL 连接配置
│   │   ├── redis.js                     # Redis 客户端配置
│   │   ├── deepseek.js                  # DeepSeek API 配置
│   │   └── logger.js                    # 日志配置
│   │
│   ├── middleware/
│   │   ├── auth.js                      # JWT 认证中间件
│   │   ├── errorHandler.js              # 全局错误处理
│   │   ├── validator.js                 # 请求参数验证
│   │   ├── contentFilter.js             # 内容审核中间件
│   │   └── requestLogger.js             # 请求日志记录
│   │
│   ├── routes/
│   │   ├── auth.js                      # 认证相关路由
│   │   ├── divination.js                # 起卦相关路由
│   │   └── health.js                    # 健康检查路由
│   │
│   ├── controllers/
│   │   ├── authController.js            # 认证控制器
│   │   └── divinationController.js      # 起卦控制器
│   │
│   ├── services/
│   │   ├── userService.js               # 用户业务逻辑
│   │   ├── divinationService.js         # 起卦业务逻辑
│   │   ├── deepseekService.js           # DeepSeek 集成
│   │   └── cacheService.js              # 缓存操作
│   │
│   ├── utils/
│   │   ├── jwt.js                       # JWT 工具
│   │   ├── contentFilter.js             # 内容过滤工具
│   │   ├── crypto.js                    # 加密工具
│   │   └── validators.js                # 验证工具
│   │
│   ├── models/
│   │   ├── User.js                      # 用户模型
│   │   ├── Divination.js                # 起卦记录模型
│   │   └── OperationLog.js              # 操作日志模型
│   │
│   ├── queues/
│   │   ├── taskQueue.js                 # Bull 任务队列
│   │   └── divinationWorker.js          # 异步处理 Worker
│   │
│   └── prompts/
│       ├── templates.js                 # Prompt 模板库
│       └── promptSelector.js            # Prompt 选择逻辑
│
├── migrations/
│   ├── 001_init_schema.sql              # 初始化 Schema
│   ├── 002_add_indexes.sql              # 添加索引
│   └── migrate.js                       # 迁移脚本
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── .env.example                         # 环境配置模板
├── .env.production                      # 生产环境配置
├── package.json
├── docker-compose.yml                   # Docker 编排（开发）
├── docker-compose.prod.yml              # Docker 编排（生产）
├── Dockerfile
├── nginx.conf                           # Nginx 配置
├── pm2.config.js                        # PM2 进程配置
└── README.md
```

---

## 核心服务设计

### 1. 认证服务 (authService)

```javascript
// 流程
User Input (Phone/WeChat) 
    ↓
Validate Input
    ↓
Generate JWT Token (有效期: 7天)
    ↓
Store Token in Redis (快速撤销)
    ↓
Return Token + User Info
```

**关键决策**: 使用 JWT + Redis 黑名单机制
- JWT 用于无状态验证
- Redis 存储 Token 黑名单（登出、修改密码等）
- 性能优势：不需要每次都查数据库

---

### 2. 起卦服务 (divinationService)

```javascript
// 核心流程
1. 接收用户输入
   ├─ 问题文本
   ├─ 卦象类型（可选）
   └─ 其他参数

2. 内容审核
   ├─ 关键词过滤
   ├─ 敏感词处理
   └─ 长度/格式验证

3. 创建起卦记录 (状态: PENDING)
   ├─ 存入 PostgreSQL
   └─ 返回 divination_id

4. 推入异步队列
   └─ Bull Queue: divinationQueue

5. Worker 处理
   ├─ 选择 Prompt 模板
   ├─ 调用 DeepSeek API
   ├─ 获取 AI 回复
   └─ 存入结果

6. 客户端轮询
   ├─ 每 2s 查询一次结果
   └─ 获取到结果后停止轮询
```

**异步设计理由**:
- DeepSeek API 响应时间不确定（通常 5-15s）
- 避免 HTTP 超时
- 提升用户体验（显示加载中动画）

---

### 3. DeepSeek 集成服务

```javascript
// DeepSeek API 调用流程
Prompt Template (选择合适的)
    ↓
Format User Input
    ↓
HTTP POST to DeepSeek API
    ├─ Timeout: 30s
    ├─ Retry: 3次 (指数退避)
    └─ Rate Limit: 根据 API 配额动态调整
    ↓
Parse Response
    ↓
Content Filter (再次过滤)
    ↓
Store in Database
    ↓
Cache in Redis (可选)
```

---

### 4. 内容审核服务

```javascript
// 两层防护
第1层：前置过滤（输入侧）
├─ 关键词黑名单
├─ 敏感词替换
├─ 长度限制
└─ 格式检查

第2层：后置过滤（输出侧）
├─ AI 回复敏感词检查
├─ 不允许的内容识别
└─ 日志记录（用于持续改进）
```

---

## 数据流与交互

### 用户认证流程

```
小程序端                          服务器端
   │                                │
   ├─────── POST /auth/login ───────→
   │                                │
   │                           验证 Token
   │                           查询数据库
   │                           生成 JWT
   │                                │
   ←────── JWT Token + User ────────┤
   │                                │
   │ (存储 JWT 到 localStorage)      │
   │                                │
   ├─────── 后续请求 ───────────────→
   │ (Header: Authorization: Bearer JWT)
   │                                │
   │                           验证 JWT
   │                           处理请求
   │                                │
   ←─────── Response ────────────────┤
```

### 起卦请求流程

```
小程序端                     后端服务                    异步 Worker
   │                            │                             │
   ├─ POST /divination/create ─→│                             │
   │                            │                             │
   │                       验证用户身份                         │
   │                       内容审核                           │
   │                       保存记录                           │
   │                       推入队列                           │
   │                            ├─────── Async Job ─────────→
   │                       返回 ID                           │
   │←── {status: PENDING} ──────│                             │
   │                            │                       调用 DeepSeek
   │                            │                       处理响应
   │                            │                       保存结果
   │                            │←──── Job Complete ─────┤
   │                            │                             │
   ├─ GET /divination/:id ─────→│                             │
   │  (轮询，每 2s 一次)         │                             │
   │                       查询数据库                         │
   │←── {status: COMPLETED, data} │                           │
   │                            │                             │
   └                            └                             ┘
```

---

## 缓存策略

### Redis 缓存设计

| 数据 | TTL | 用途 |
|-----|------|------|
| User Session | 7 天 | 快速验证用户登录状态 |
| JWT BlackList | 30 分钟 | 记录已登出的 Token |
| Divination Result | 24 小时 | 避免重复查询数据库 |
| Hot Prompts | 1 小时 | 缓存热点 Prompt 模板 |
| Rate Limit Bucket | 1 分钟 | 限流计数器 |

---

## 性能优化

### 数据库优化

**关键索引**:
```sql
-- users 表
CREATE INDEX idx_users_wechat_openid ON users(wechat_openid);
CREATE INDEX idx_users_phone ON users(phone);

-- divinations 表
CREATE INDEX idx_divinations_user_id ON divinations(user_id);
CREATE INDEX idx_divinations_created_at ON divinations(created_at DESC);
CREATE INDEX idx_divinations_status ON divinations(status);

-- operation_logs 表
CREATE INDEX idx_logs_user_id_created ON operation_logs(user_id, created_at DESC);
```

**查询优化**:
- 使用连接池（最大 20 连接）
- 启用查询缓存
- 避免 N+1 查询
- 定期 VACUUM 和 ANALYZE

### API 性能

- 响应压缩 (gzip)
- HTTP 缓存头配置
- JSON 序列化优化
- 异步处理耗时操作

---

## 安全设计

### 认证与授权
- JWT Token + 黑名单机制
- 每个请求验证 Token 有效性
- 操作敏感接口需要额外验证

### 数据保护
- 密码加密存储 (bcryptjs)
- 敏感数据不记录日志
- HTTPS 全程加密

### 内容安全
- 多层内容过滤
- 关键词黑名单
- AI 输出审核
- 异常日志告警

### 速率限制
- 全局速率限制：100 req/min
- 用户级限制：50 req/min
- 起卦接口限制：5 req/min (防止滥用)

---

## 监控与日志

### 关键指标

```javascript
// Prometheus 指标
http_request_duration_seconds      // API 响应时间
http_requests_total                 // 请求总数
db_query_duration_seconds           // 数据库查询时间
deepeek_api_latency_seconds         // 第三方 API 延迟
user_registration_total             // 用户注册数
divination_requests_total           // 起卦请求数
errors_total                        // 错误总数
```

### 日志级别

```
DEBUG   → 开发环境，所有详细信息
INFO    → 重要业务事件（用户登录、起卦请求）
WARN    → 警告（缓存失败、重试次数多）
ERROR   → 错误（数据库连接失败、API 调用失败）
FATAL   → 致命错误（需要立即告警）
```

---

## 可扩展性设计

### 水平扩展

```
当 DAU > 1000 时的架构升级：

┌────────────────────────────────────┐
│      Kubernetes Cluster             │
│  ┌──────────┐   ┌──────────┐      │
│  │  Pod 1   │   │  Pod 2   │      │
│  │ Express  │   │ Express  │      │
│  └────┬─────┘   └────┬─────┘      │
│       │              │             │
└───────┼──────────────┼─────────────┘
        │              │
   ┌────▼──────────────▼────┐
   │  RDS for PostgreSQL     │
   │  (Multi-AZ)            │
   └────────┬────────────────┘
            │
   ┌────────▼──────────┐
   │  ElastiCache Redis │
   │  (主从复制)       │
   └───────────────────┘
```

---

## 故障恢复

### RTO/RPO 目标
- **RTO** (恢复时间目标): 15 分钟
- **RPO** (恢复点目标): 5 分钟

### 备份策略
- PostgreSQL 每小时备份到 S3
- Redis 持久化 (RDB 每小时 + AOF)
- 应用代码 Git 仓库备份

---

## 技术栈总结

| 层 | 技术 | 版本 |
|---|------|------|
| 运行时 | Node.js | 18+ |
| 框架 | Express.js | 4.18+ |
| 数据库 | PostgreSQL | 13+ |
| 缓存 | Redis | 6+ |
| 队列 | Bull + Redis | 4.x |
| 认证 | JWT | - |
| 日志 | Winston | 3.x |
| 文件存储 | 本地/S3 | - |
| 监控 | Prometheus | - |
| 容器 | Docker | - |
