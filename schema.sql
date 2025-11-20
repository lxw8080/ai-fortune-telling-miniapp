# PostgreSQL 数据库设计

## 核心表结构

### users 表（用户表）

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  wechat_openid VARCHAR(128) UNIQUE NOT NULL,
  phone VARCHAR(20),
  nickname VARCHAR(50),
  avatar_url TEXT,
  
  divination_count INT DEFAULT 0,
  last_divination_at TIMESTAMP,
  
  password_hash VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_users_wechat_openid ON users(wechat_openid);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

### divinations 表（起卦记录）

```sql
CREATE TABLE divinations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  question VARCHAR(200) NOT NULL,
  type VARCHAR(20) DEFAULT 'zhouyi',
  result TEXT,
  
  status VARCHAR(20) DEFAULT 'PENDING',
  attempts INT DEFAULT 0,
  last_error VARCHAR(500),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE INDEX idx_divinations_user_id ON divinations(user_id);
CREATE INDEX idx_divinations_created_at ON divinations(created_at DESC);
CREATE INDEX idx_divinations_status ON divinations(status);
```

### operation_logs 表（操作日志）

```sql
CREATE TABLE operation_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  operation VARCHAR(50) NOT NULL,
  resource_type VARCHAR(50),
  resource_id BIGINT,
  
  ip_address VARCHAR(45),
  user_agent TEXT,
  request_params JSON,
  response_status INT,
  
  error_message VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_logs_user_id ON operation_logs(user_id);
CREATE INDEX idx_logs_created_at ON operation_logs(created_at DESC);
```

---

## 索引优化

```sql
-- 复合索引：最常用的查询组合
CREATE INDEX idx_divinations_user_created ON divinations(user_id, created_at DESC) 
WHERE status = 'COMPLETED';

-- 操作日志复合索引
CREATE INDEX idx_logs_user_operation_created ON operation_logs(user_id, operation, created_at DESC);
```

---

## 定期维护

```bash
#!/bin/bash
# cron_maintenance.sh - 每天凌晨2点执行

0 2 * * * psql -U postgres -d fortune -c "VACUUM ANALYZE divinations, users, operation_logs;"

# 每周一重建索引
0 3 * * 1 psql -U postgres -d fortune -c "REINDEX TABLE divinations, users, operation_logs;"
```
