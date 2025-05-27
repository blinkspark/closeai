# closeai

一个支持MCP（Model Context Protocol）的AI聊天应用。

## 功能特性

- 🤖 多AI供应商支持（OpenAI、Claude等）
- 🔧 MCP工具集成，让AI能够访问外部资源和工具
- 💬 流式聊天体验
- 🎨 现代化UI设计
- 📱 跨平台支持（Windows、macOS、Linux）

## MCP支持

本应用已集成MCP（Model Context Protocol）支持，允许AI访问各种外部工具和资源：

### 支持的传输方式
- **Stdio**: 通过标准输入输出与本地MCP服务器通信（推荐）
- **WebSocket**: 通过WebSocket与远程MCP服务器通信
- **Server-Sent Events**: 通过SSE与远程MCP服务器通信（实验性支持）

### 如何使用MCP工具

1. **配置MCP服务器**
   - 进入设置 → AI配置 → MCP服务器
   - 点击添加按钮配置新的MCP服务器

2. **在聊天中使用工具**
   - 使用 `@工具名(参数=值)` 格式调用工具
   - 例如: `@search(query="Flutter开发", limit=5)`
   - 点击聊天界面的工具选择器查看可用工具

3. **识别MCP工具调用**
   - 🔍 应用会自动检测消息中的工具调用语法
   - 🔧 显示"正在调用MCP工具"的状态提示
   - ✅ 工具执行成功会显示绿色勾号和结果
   - ❌ 工具执行失败会显示红色错误信息
   - 💡 聊天界面顶部显示MCP状态指示器

### 示例MCP服务器配置

#### 文件系统工具
```
名称: 文件系统
描述: 读写本地文件
传输类型: stdio
命令: npx
参数: @modelcontextprotocol/server-filesystem /path/to/directory
```

#### Web搜索工具
```
名称: Web搜索
描述: 搜索互联网内容
传输类型: stdio
命令: npx
参数: @modelcontextprotocol/server-brave-search
环境变量: BRAVE_API_KEY=your_api_key
```

### 使用示例

#### 完整的MCP工具调用流程

1. **用户输入**:
   ```
   @search(query="Flutter MCP集成教程", limit=3)
   ```

2. **应用响应**:
   ```
   🔍 检测到 1 个MCP工具调用，开始执行...
   🔧 正在调用MCP工具: search
   参数: {"query":"Flutter MCP集成教程","limit":3}
   ✅ 工具执行成功:
   
   [搜索结果内容...]
   
   ✨ MCP工具调用完成！您可以继续对话或调用其他工具。
   ```

3. **状态指示器显示**:
   ```
   MCP: 1服务器 | 5工具 🟢
   ```

#### 多工具调用示例
```
用户: @search(query="Flutter") 然后 @read_file(path="config.json")
```

应用会依次执行两个工具调用，每个都有清晰的状态提示。

#### 获取帮助
```
用户: 有什么工具可以用？
```

应用会自动显示所有可用的MCP工具列表和使用方法。

### 故障排除

#### 常见问题

1. **连接失败**
   - 确保MCP服务器正在运行
   - 检查URL或命令路径是否正确
   - 对于Stdio服务器，确保命令可执行

2. **406错误（SSE）**
   - 服务器可能不支持MCP协议
   - 尝试使用Stdio或WebSocket传输方式
   - 检查服务器是否正确实现了MCP规范

3. **工具调用失败**
   - 检查工具参数格式是否正确
   - 确保所有必需参数都已提供
   - 查看工具帮助了解正确的参数类型

#### 推荐配置

- **本地开发**: 使用Stdio传输方式，稳定性最好
- **远程服务**: 优先选择WebSocket，其次是SSE
- **生产环境**: 建议使用经过测试的MCP服务器

## TODO
- [ ] 添加默认Provider
- [ ] 添加默认模型
- [x] 集成MCP支持
- [x] 添加MCP工具选择器
- [x] 支持工具调用语法