# 模型和供应商配置功能实现

## 概述

已成功在设置页面中添加了模型和供应商的配置功能，用户现在可以：

1. 配置不同的AI供应商（如OpenAI、OpenRouter等）
2. 为每个供应商配置API Key和Base URL
3. 添加和管理不同的AI模型
4. 选择当前使用的模型
5. 动态切换模型和供应商配置

## 新增文件

### 1. 控制器
- `lib/controllers/model_controller.dart` - 模型管理控制器
- `lib/services/openai_service.dart` - 动态OpenAI服务

### 2. 设置页面
- `lib/pages/setting_page/provider_setting_page.dart` - 供应商设置页面
- `lib/pages/setting_page/model_setting_page.dart` - 模型设置页面

## 修改的文件

### 1. 主要文件
- `lib/main.dart` - 注册新的控制器和服务
- `lib/pages/setting_page.dart` - 添加AI配置选项
- `lib/controllers/session_controller.dart` - 使用动态OpenAI服务
- `lib/controllers/provider_controller.dart` - 添加配置刷新功能

## 功能特性

### 供应商管理
- ✅ 添加新的AI供应商
- ✅ 编辑供应商信息（名称、Base URL、API Key）
- ✅ 删除供应商配置
- ✅ API Key安全显示（部分隐藏）

### 模型管理
- ✅ 添加新的AI模型
- ✅ 关联模型到特定供应商
- ✅ 选择当前使用的模型
- ✅ 编辑和删除模型配置

### 动态配置
- ✅ 根据选中的模型自动使用对应的供应商配置
- ✅ 实时刷新OpenAI客户端配置
- ✅ 配置验证和错误提示

## 使用方法

### 1. 配置供应商
1. 进入设置页面
2. 点击"供应商管理"
3. 点击"+"按钮添加新供应商
4. 填写供应商名称、Base URL和API Key
5. 保存配置

### 2. 配置模型
1. 在设置页面点击"模型管理"
2. 点击"+"按钮添加新模型
3. 输入模型ID（如：gpt-3.5-turbo）
4. 选择对应的供应商
5. 保存配置

### 3. 选择当前模型
1. 在模型管理页面
2. 点击要使用的模型前的单选按钮
3. 系统会自动切换到该模型和对应的供应商配置

## 技术实现

### 数据存储
- 使用Isar数据库存储供应商和模型配置
- Provider和Model之间建立关联关系

### 服务架构
- `OpenAIService` 提供统一的AI服务接口
- 根据当前选中的模型动态创建OpenAI客户端
- 支持配置变更时的实时刷新

### 状态管理
- 使用GetX进行状态管理
- 响应式UI更新
- 配置变更时自动刷新相关服务

## 配置示例

### 供应商配置示例
```
名称: OpenAI
Base URL: https://api.openai.com/v1
API Key: sk-xxxxxxxxxxxxxxxx

名称: OpenRouter
Base URL: https://openrouter.ai/api/v1
API Key: sk-or-xxxxxxxxxxxxxxxx
```

### 模型配置示例
```
模型ID: gpt-3.5-turbo
供应商: OpenAI

模型ID: meta-llama/llama-3.3-8b-instruct:free
供应商: OpenRouter
```

## 注意事项

1. 首次使用需要先配置供应商，再配置模型
2. API Key会被安全存储，界面上只显示部分字符
3. 更改配置后会自动刷新AI服务，无需重启应用
4. 删除供应商前请确保没有模型在使用该供应商

## 错误处理

- 配置不完整时会显示相应提示
- API调用失败时会显示错误信息
- 支持配置验证和用户友好的错误提示