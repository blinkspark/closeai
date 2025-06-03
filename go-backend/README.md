# closeai-backend

## 启动方式

1. 安装依赖：
   ```bash
   go mod tidy
   ```
2. 运行服务：
   ```bash
   go run main.go
   ```

- 默认监听 8080 端口
- 支持 POSTGRE_URL 环境变量自动切换 PostgreSQL/SQLite

## 主要接口

- POST /api/register 注册
- POST /api/login 登录
- GET /api/user 获取用户信息（需登录）
- POST /api/change_password 修改密码（需登录）
