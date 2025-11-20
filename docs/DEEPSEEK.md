# DeepSeek API 集成指南

## API 配置

### 1. 获取 API Key

```bash
# 访问 https://platform.deepseek.com
# 作业：
1. 注册/登录 DeepSeek 平台
2. 进入钥匙管理 → API Keys
3. 创建 API Key
4. 添加到 .env 文件
```

### 2. 环境配置

```bash
# .env
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxx
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_TIMEOUT=30000
DEEPSEEK_MAX_TOKENS=500
DEEPSEEK_TEMPERATURE=0.7
DEEPSEEK_TOP_P=1
```

---

## Prompt 模板库

### 模板 1：周易卦象解读

```javascript
const ZHOUYI_TEMPLATE = `你是一位专业的周易咨询师。
用户提了一个问题：「{question}」

请根据周易智慧（此为娱乐性质，仅作参考），提供以下内容：
1. 推荐卦象（1-3个）
2. 基于卦象的建议（三条）
3. 注意事项（1-2条）

回复长度：150-200字`;
```

### 模板 2：姓名学解读

```javascript
const NAMEOLOGY_TEMPLATE = `你是姓名学专家。
用户上传了一个姓名：「{name}」

请提供以下分析（仅供娱乐参考）：
1. 笔画数分析
2. 五行属性
3. 字义寓意
4. 运势建议

回复长度：100-150字`;
```

### 模板 3：趋势分析

```javascript
const TREND_TEMPLATE = `你是趋势分析师。
用户关注的事项：「{concern}」
时间范围：{timeframe}

请提供以下分析（仅供娱乐参考）：
1. 近期趋势判断
2. 可能的机遇与挑战
3. 行动建议
4. 重点关注点

回复长度：180-220字`;
```

---

## 内容安全过滤

### 关键词黑名单

```javascript
const SENSITIVE_KEYWORDS = [
  /时政敏感词/gi,
  /政治极端/gi,
  /骗局/gi,
  // 更多敏感词...
];
```

---

## API 调用实现

### 基础客户端

```javascript
class DeepSeekService {
  async callDeepSeek(promptType, params) {
    const template = PROMPT_TEMPLATES[promptType];
    let prompt = template;
    for (const [key, value] of Object.entries(params)) {
      prompt = prompt.replace(`{${key}}`, value);
    }
    
    const response = await axios.post('/chat/completions', {
      model: 'deepseek-chat',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 500
    });
    
    return response.data.choices[0].message.content;
  }
}
```

---

## 速率限制

```javascript
const RATE_LIMITS = {
  global: { rate: 100, window: 60 },      // 100 req/min
  divination: { rate: 5, window: 60 }     // 5 req/min
};
```

---

## 成本控制

```
平均每次起卦消费：
- 平均 token 数：200 tokens
- DeepSeek 价格：1M tokens ≈ ¥2
- 每次估算成本：200 * 2 / 1000000 ≈ ¥0.0004

100 日活估算：
- 每日起卦次数：3000 次
- 每日成本：¥1.2
- 每月成本：¥36
```
