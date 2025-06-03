# Go 后台服务器开发计划

## 1. 技术选型

- 语言：Go 1.20+
- Web 框架：Gin
- 数据库：PostgreSQL + SQLite (设置了POSTGRE_URL环境变量时使用 PostgreSQL，否则使用 SQLite)
- 密码加密：bcrypt
- Token 认证：JWT
- 配置管理：Viper（可选）
- 遵循SOLID原则和RESTful API设计规范
- 日志管理：zap

## 2. 功能模块

### 2.1 用户注册

- 接口：`POST /api/register`
- 输入：用户名、邮箱、密码
- 验证：用户名/邮箱唯一，密码强度
- 处理：密码加密存储，写入数据库
- 输出：注册成功/失败信息

### 2.2 用户登录

- 接口：`POST /api/login`
- 输入：用户名/邮箱、密码
- 验证：校验用户存在、密码正确
- 处理：生成 JWT Token
- 输出：登录成功（返回 Token）/失败信息

### 2.3 获取用户信息

- 接口：`GET /api/user`
- 输入：JWT Token（Header）
- 验证：Token 有效性
- 处理：查询用户信息
- 输出：用户基本信息（不含密码）

### 2.4 修改密码

- 接口：`POST /api/change_password`
- 输入：旧密码、新密码
- 验证：Token 有效性、旧密码正确、新密码强度
- 处理：更新数据库密码
- 输出：修改成功/失败信息

### 2.5 用户登出

- 前端只需删除本地 Token，后端可选实现 Token 黑名单（如 Redis）

## 3. 目录结构建议

```
go-backend/
├── main.go
├── config/
├── controllers/
├── models/
├── routes/
├── middleware/
├── utils/
└── go.mod
```

## 4. 关键第三方依赖

- github.com/gin-gonic/gin
- github.com/go-sql-driver/mysql 或 github.com/jackc/pgx
- github.com/dgrijalva/jwt-go
- golang.org/x/crypto/bcrypt

## 5. 开发步骤

1. 初始化 Go 项目，配置依赖
2. 设计数据库表结构，完成模型定义
3. 实现注册、登录、用户信息、修改密码等接口
4. 实现 JWT 认证中间件
5. 编写接口文档和简单测试
6. 部署与上线

如需详细接口设计或代码实现，可继续告知！
