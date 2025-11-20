# AI 算卦小程序 - 快速上线方案

**目标：** 实现月活100日活的AI算卦小程序，4周内完成从0到1上线。

---

## 📋 目录

1. [快速上线路线图](#快速上线路线图)
2. [后端架构](#后端架构)
3. [前端实现](#前端实现)
4. [DeepSeek 集成](#deepseek-集成)
5. [数据库设计](#数据库设计)
6. [部署与上线](#部署与上线)
7. [成本估算](#成本估算)

---

## 快速上线路线图

### 第1-2周：MVP开发
- **Week 1**
  - Day 1-2: 后端项目搭建 + 数据库初始化
  - Day 3-4: 用户认证 + 起卦记录表设计
  - Day 5: DeepSeek API 集成 + 内容过滤
  - 交付物：后端基础服务 + API 文档

- **Week 2**
  - Day 1-2: 微信小程序前端框架搭建
  - Day 3-4: 首页 + 起卦页 + 结果页实现
  - Day 5: 前后端联调 + 基础测试
  - 交付物：完整前后端链路可用

### 第2-3周：部署与灰度
- **Week 2-3**
  - Day 1-2: 后端生产环境部署 + HTTPS配置
  - Day 3: 微信小程序审核提交准备
  - Day 4-5: 灰度测试 + Bug修复
  - Day 6-7: 全量上线
  - 交付物：小程序上架 + 监控告警就绪

### 第3-4周：快速迭代
- **Week 3-4**
  - 每日日活数据收集分析
  - 基于用户反馈的功能优化
  - 性能瓶颈优化
  - 内容审核规则调整
  - 目标：达成100日活

---

## 后端架构

### 技术栈推荐

**选择：Node.js + Express** （理由：快速开发、易部署、单人维护成本低）

```
ai-fortune-backend/
├── src/
│   ├── app.js              # Express 主程序
│   ├── config/             # 配置文件
│   ├── routes/             # 路由
│   ├── controllers/        # 控制器
│   ├── services/           # 业务逻辑
│   ├── middleware/         # 中间件
│   ├── utils/              # 工具函数
│   └── models/             # 数据模型
├── migrations/             # 数据库迁移
├── .env.example
├── package.json
└── docker-compose.yml
```

### 核心 API 端点

```
POST   /api/auth/register           # 用户注册
POST   /api/auth/login              # 用户登录
POST   /api/divination/create       # 发起起卦
GET    /api/divination/result/:id   # 获取结果
GET    /api/divination/history      # 查询历史记录
GET    /api/divination/stats        # 用户统计
```

---

## 前端实现

### 页面流程
```
首页（免责声明）
  ↓
选择卦象类型
  ↓
输入提问内容
  ↓
加载中（显示算卦动画）
  ↓
结果展示页
├→ AI 解读
├→ 分享按钮
└→ 查看历史
```

### 页面结构

- `pages/index/` - 首页（免责声明+开始按钮）
- `pages/divination/` - 起卦页（表单输入）
- `pages/result/` - 结果页（AI回复展示）
- `pages/history/` - 历史记录页
- `components/` - 可复用组件

---

## DeepSeek 集成

### Prompt 模板库

详见 `docs/DEEPSEEK.md`

---

## 数据库设计

### 核心表结构
- `users` - 用户表
- `divinations` - 起卦记录表
- `operation_logs` - 操作日志表

详见 `schema.sql`

---

## 部署与上线

### 前置条件
- 域名 + HTTPS 证书
- 服务器 + PostgreSQL
- 微信小程序已注册

### 上线检查清单
- [ ] 后端 API 完全测试
- [ ] 内容过滤规则配置完整
- [ ] 监控告警部署
- [ ] HTTPS 验证
- [ ] 微信小程序域名配置
- [ ] 审核材料准备

详见 `docs/DEPLOYMENT.md`

---

## 成本估算

### 月均成本（基于100日活）
- **DeepSeek API**: ¥10-30/月
- **服务器**: ¥50-100/月（自有服务器）
- **带宽**: ¥10-20/月
- **CDN**: ¥0（暂不需要）

**总计**: ¥70-150/月

详见 `docs/COST_ANALYSIS.md`

---

## 快速开始

```bash
# 1. 克隆项目
git clone <repo>
cd backend

# 2. 安装依赖
npm install

# 3. 配置环境
cp .env.example .env
# 编辑 .env，填入 DeepSeek API Key 等

# 4. 初始化数据库
npm run migrate

# 5. 启动开发服务
npm run dev
```

---

## 文档索引

- `docs/ROADMAP.md` - 详细周计划
- `docs/ARCHITECTURE.md` - 架构设计文档
- `docs/API.md` - API 完整文档
- `docs/DEPLOYMENT.md` - 部署指南
- `docs/COST_ANALYSIS.md` - 成本分析
- `docs/MINIAPP.md` - 小程序前端指南
- `docs/DEEPSEEK.md` - DeepSeek 集成指南

---

## 联系与支持

项目负责人：独自开发
技术栈：Node.js + Express + PostgreSQL + DeepSeek
维护周期：快速迭代（日活100+后切换月度迭代）