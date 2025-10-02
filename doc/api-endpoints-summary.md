# AppFlowy Cloud API 端点总结文档

## 目录
- [认证与用户管理](#认证与用户管理)
- [工作区管理](#工作区管理)
- [协作文档](#协作文档)
- [文件存储](#文件存储)
- [AI 功能](#ai-功能)
- [聊天功能](#聊天功能)
- [搜索功能](#搜索功能)
- [发布功能](#发布功能)
- [模板中心](#模板中心)
- [计费订阅](#计费订阅)
- [成员与权限](#成员与权限)
- [视图管理](#视图管理)
- [其他功能](#其他功能)

---

## 认证与用户管理

### 1. 发送邮箱验证码 (Magic Link)
```bash
# 通过 GoTrue 发送邮箱验证码/魔法链接
# POST /gotrue/magiclink
curl -X POST "http://localhost:9999/magiclink" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "87103978@qq.com"
  }'
```

**说明**: 
- 此接口会向用户邮箱发送一个包含验证码(OTP)的邮件
- 用户可以使用收到的验证码通过下面的接口进行登录/注册
- 也可以发送魔法链接，用户点击链接后会重定向到应用

### 2. 使用邮箱验证码登录/注册
```bash
# 使用邮箱验证码登录或注册
# POST /gotrue/verify
curl -X POST "http://localhost:9999/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "magiclink",
    "email": "user@example.com",
    "token": "123456"
  }'
```

**说明**:
- `type`: 验证类型，使用 `magiclink` 表示邮箱验证码登录
- `email`: 用户邮箱地址
- `token`: 用户收到的验证码
- 返回包含 `access_token` 和 `refresh_token` 的响应
- 如果用户不存在，会自动创建新用户(注册)

**响应示例**:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "v1.MR5m...",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "role": "authenticated",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### 3. 密码登录验证
```bash
# POST /api/user/verify/{access_token}
curl -X GET "http://localhost:8000/api/user/verify/{access_token}"
```

### 4. 获取用户资料
```bash
# GET /api/user/profile
curl -X GET "http://localhost:8000/api/user/profile" \
  -H "Authorization: Bearer {access_token}" \
  -H "client-version: 0.6.7" \
  -H "device-id: {device_id}"
```

### 5. 更新用户信息
```bash
# POST /api/user/update
curl -X POST "http://localhost:8000/api/user/update" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "new@email.com",
    "password": "newpassword",
    "name": "New Name"
  }'
```

### 6. 删除用户
```bash
# DELETE /api/user
curl -X DELETE "http://localhost:8000/api/user" \
  -H "Authorization: Bearer {access_token}"
```

### 7. 获取用户工作区信息
```bash
# GET /api/user/workspace
curl -X GET "http://localhost:8000/api/user/workspace" \
  -H "Authorization: Bearer {access_token}"
```

---

## 工作区管理

### 8. 创建工作区
```bash
# POST /api/workspace
curl -X POST "http://localhost:8000/api/workspace" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_name": "My Workspace"
  }'
```

### 9. 获取工作区列表
```bash
# GET /api/workspace
curl -X GET "http://localhost:8000/api/workspace" \
  -H "Authorization: Bearer {access_token}"
```

### 10. 删除工作区
```bash
# DELETE /api/workspace/{workspace_id}
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 11. 更新工作区
```bash
# PATCH /api/workspace
curl -X PATCH "http://localhost:8000/api/workspace" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "workspace_name": "Updated Name"
  }'
```

### 12. 打开工作区
```bash
# PUT /api/workspace/{workspace_id}/open
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/open" \
  -H "Authorization: Bearer {access_token}"
```

### 13. 获取工作区文件夹
```bash
# GET /api/workspace/{workspace_id}/folder
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/folder?depth=2" \
  -H "Authorization: Bearer {access_token}"
```

### 14. 获取工作区收藏
```bash
# GET /api/workspace/{workspace_id}/favorite
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/favorite" \
  -H "Authorization: Bearer {access_token}"
```

### 15. 获取工作区最近访问
```bash
# GET /api/workspace/{workspace_id}/recent
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/recent" \
  -H "Authorization: Bearer {access_token}"
```

### 16. 获取工作区回收站
```bash
# GET /api/workspace/{workspace_id}/trash
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/trash" \
  -H "Authorization: Bearer {access_token}"
```

### 17. 获取工作区存储用量
```bash
# GET /api/file_storage/{workspace_id}/usage
curl -X GET "http://localhost:8000/api/file_storage/{workspace_id}/usage" \
  -H "Authorization: Bearer {access_token}"
```

### 18. 获取工作区使用量和限制
```bash
# GET /api/workspace/{workspace_id}/usage-and-limit
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/usage-and-limit" \
  -H "Authorization: Bearer {access_token}"
```

### 19. 获取工作区设置
```bash
# GET /api/workspace/{workspace_id}/settings
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/settings" \
  -H "Authorization: Bearer {access_token}"
```

### 20. 更新工作区设置
```bash
# POST /api/workspace/{workspace_id}/settings
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/settings" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "disable_search_indexing": false
  }'
```

---

## 协作文档

### 21. 创建协作文档
```bash
# POST /api/workspace/{workspace_id}/collab/{object_id}
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/octet-stream" \
  -d @collab_data.bin
```

### 22. 批量创建协作文档
```bash
# POST /api/workspace/{workspace_id}/batch/collab
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/batch/collab" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "object_id": "{object_id}",
      "collab_type": "Document"
    }
  ]'
```

### 23. 获取协作文档
```bash
# GET /api/workspace/{workspace_id}/collab/{object_id}
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}?collab_type=Document" \
  -H "Authorization: Bearer {access_token}"
```

### 24. 批量获取协作文档
```bash
# GET /api/workspace/{workspace_id}/batch/collab
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/batch/collab" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "object_id": "{object_id}",
      "collab_type": "Document"
    }
  ]'
```

### 25. 删除协作文档
```bash
# DELETE /api/workspace/{workspace_id}/collab/{object_id}
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 26. 协作文档完全同步
```bash
# POST /api/workspace/{workspace_id}/collab/{object_id}/full-sync
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}/full-sync" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "collab_type": "Document",
    "doc_state": "base64_encoded_state",
    "state_vector": "base64_encoded_vector"
  }'
```

---

## 文件存储

### 27. 上传文件 (Blob)
```bash
# PUT /api/file_storage/{workspace_id}/blob/{file_id}
curl -X PUT "http://localhost:8000/api/file_storage/{workspace_id}/blob/{file_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: image/png" \
  --data-binary @image.png
```

### 28. 上传文件 V1
```bash
# PUT /api/file_storage/{workspace_id}/v1/blob/{parent_dir}
curl -X PUT "http://localhost:8000/api/file_storage/{workspace_id}/v1/blob/{parent_dir}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: image/png" \
  --data-binary @image.png
```

### 29. 获取文件
```bash
# GET /api/file_storage/{workspace_id}/blob/{file_id}
curl -X GET "http://localhost:8000/api/file_storage/{workspace_id}/blob/{file_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 30. 获取文件 V1
```bash
# GET /api/file_storage/{workspace_id}/v1/blob/{parent_dir}/{file_id}
curl -X GET "http://localhost:8000/api/file_storage/{workspace_id}/v1/blob/{parent_dir}/{file_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 31. 删除文件
```bash
# DELETE /api/file_storage/{workspace_id}/v1/blob/{parent_dir}/{file_id}
curl -X DELETE "http://localhost:8000/api/file_storage/{workspace_id}/v1/blob/{parent_dir}/{file_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 32. 获取文件元数据
```bash
# GET /api/file_storage/{workspace_id}/v1/metadata/{parent_dir}/{file_id}
curl -X GET "http://localhost:8000/api/file_storage/{workspace_id}/v1/metadata/{parent_dir}/{file_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 33. 获取工作区所有文件元数据
```bash
# GET /api/file_storage/{workspace_id}/blobs
curl -X GET "http://localhost:8000/api/file_storage/{workspace_id}/blobs" \
  -H "Authorization: Bearer {access_token}"
```

### 34. 创建分片上传
```bash
# POST /api/file_storage/{workspace_id}/upload/start
curl -X POST "http://localhost:8000/api/file_storage/{workspace_id}/upload/start" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "parent_dir": "documents",
    "file_id": "{file_id}",
    "content_type": "application/pdf"
  }'
```

### 35. 上传分片
```bash
# PUT /api/file_storage/{workspace_id}/upload/{parent_dir}/{file_id}
curl -X PUT "http://localhost:8000/api/file_storage/{workspace_id}/upload/{parent_dir}/{file_id}?upload_id={upload_id}&part_number=1" \
  -H "Authorization: Bearer {access_token}" \
  --data-binary @part1.bin
```

### 36. 完成分片上传
```bash
# POST /api/file_storage/{workspace_id}/upload/complete
curl -X POST "http://localhost:8000/api/file_storage/{workspace_id}/upload/complete" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "parent_dir": "documents",
    "file_id": "{file_id}",
    "upload_id": "{upload_id}",
    "parts": [
      {"e_tag": "etag1", "part_number": 1}
    ]
  }'
```

---

## AI 功能

### 37. 流式文本补全
```bash
# POST /api/ai/{workspace_id}/complete/stream
curl -X POST "http://localhost:8000/api/ai/{workspace_id}/complete/stream" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -H "ai-model: gpt-4" \
  -d '{
    "text": "Complete this sentence:",
    "completion_type": "continue_writing"
  }'
```

### 38. 流式文本补全 V2
```bash
# POST /api/ai/{workspace_id}/v2/complete/stream
curl -X POST "http://localhost:8000/api/ai/{workspace_id}/v2/complete/stream" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -H "ai-model: Auto" \
  -d '{
    "text": "Complete this:",
    "completion_type": "continue_writing"
  }'
```

### 39. 总结行
```bash
# POST /api/ai/{workspace_id}/summarize_row
curl -X POST "http://localhost:8000/api/ai/{workspace_id}/summarize_row" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "data": {"content": "text to summarize"}
  }'
```

### 40. 翻译行
```bash
# POST /api/ai/{workspace_id}/translate_row
curl -X POST "http://localhost:8000/api/ai/{workspace_id}/translate_row" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "data": {"content": "text to translate"},
    "language": "Spanish"
  }'
```

### 41. 获取本地 AI 配置
```bash
# GET /api/ai/{workspace_id}/local/config
curl -X GET "http://localhost:8000/api/ai/{workspace_id}/local/config?platform=macos&app_version=0.6.7" \
  -H "Authorization: Bearer {access_token}"
```

### 42. 获取 AI 模型列表
```bash
# GET /api/ai/{workspace_id}/model/list
curl -X GET "http://localhost:8000/api/ai/{workspace_id}/model/list" \
  -H "Authorization: Bearer {access_token}"
```

---

## 聊天功能

### 43. 创建聊天
```bash
# POST /api/chat/{workspace_id}
curl -X POST "http://localhost:8000/api/chat/{workspace_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "{chat_id}",
    "name": "My Chat",
    "rag_ids": []
  }'
```

### 44. 删除聊天
```bash
# DELETE /api/chat/{workspace_id}/{chat_id}
curl -X DELETE "http://localhost:8000/api/chat/{workspace_id}/{chat_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 45. 更新聊天设置
```bash
# POST /api/chat/{workspace_id}/{chat_id}/settings
curl -X POST "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/settings" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Chat Name",
    "metadata": {}
  }'
```

### 46. 获取聊天设置
```bash
# GET /api/chat/{workspace_id}/{chat_id}/settings
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/settings" \
  -H "Authorization: Bearer {access_token}"
```

### 47. 创建问题
```bash
# POST /api/chat/{workspace_id}/{chat_id}/message
curl -X POST "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/message" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "What is AI?",
    "message_type": "user"
  }'
```

### 48. 保存答案
```bash
# POST /api/chat/{workspace_id}/{chat_id}/message/answer
curl -X POST "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/message/answer" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "AI stands for...",
    "question_id": 123
  }'
```

### 49. 流式答案 V2
```bash
# GET /api/chat/{workspace_id}/{chat_id}/{question_id}/answer/stream
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/{question_id}/answer/stream" \
  -H "Authorization: Bearer {access_token}"
```

### 50. 流式答案 V3
```bash
# GET /api/chat/{workspace_id}/v3/answer/stream
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/v3/answer/stream?chat_id={chat_id}&question_id={question_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "ai-model: Auto"
```

### 51. 获取答案
```bash
# GET /api/chat/{workspace_id}/{chat_id}/{question_id}/answer
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/{question_id}/answer" \
  -H "Authorization: Bearer {access_token}"
```

### 52. 获取聊天消息
```bash
# GET /api/chat/{workspace_id}/{chat_id}/messages
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/messages?offset=0&limit=20" \
  -H "Authorization: Bearer {access_token}"
```

### 53. 更新聊天消息
```bash
# PUT /api/chat/{workspace_id}/{chat_id}/message
curl -X PUT "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/message" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "message_id": 123,
    "content": "Updated content"
  }'
```

### 54. 获取相关问题
```bash
# GET /api/chat/{workspace_id}/{chat_id}/{message_id}/related_question
curl -X GET "http://localhost:8000/api/chat/{workspace_id}/{chat_id}/{message_id}/related_question" \
  -H "Authorization: Bearer {access_token}"
```

---

## 搜索功能

### 55. 搜索文档
```bash
# GET /api/workspace/{workspace_id}/search
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/search?query=hello&limit=10&preview_size=100&score=0.5" \
  -H "Authorization: Bearer {access_token}"
```

### 56. 生成搜索摘要
```bash
# POST /api/workspace/{workspace_id}/search/summary
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/search/summary" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "AI features",
    "search_results": []
  }'
```

---

## 发布功能

### 57. 列出已发布视图
```bash
# GET /api/workspace/{workspace_id}/published-info
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/published-info" \
  -H "Authorization: Bearer {access_token}"
```

### 58. 设置工作区发布命名空间
```bash
# PATCH /api/workspace/{workspace_id}/publish-namespace
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/publish-namespace" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "new_namespace": "my-workspace"
  }'
```

### 59. 获取工作区发布命名空间
```bash
# GET /api/workspace/{workspace_id}/publish-namespace
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/publish-namespace" \
  -H "Authorization: Bearer {access_token}"
```

### 60. 更新已发布协作文档
```bash
# PATCH /api/workspace/{workspace_id}/publish-collabs
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/publish-collabs" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "view_id": "{view_id}",
      "publish_name": "new-name"
    }
  ]'
```

### 61. 取消发布协作文档
```bash
# DELETE /api/workspace/{workspace_id}/publish-collabs
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/publish-collabs" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '["view_id_1", "view_id_2"]'
```

### 62. 获取已发布协作文档信息
```bash
# GET /api/publish/{view_id}/info
curl -X GET "http://localhost:8000/api/publish/{view_id}/info"
```

### 63. 获取已发布大纲
```bash
# GET /api/publish/{namespace}/outline
curl -X GET "http://localhost:8000/api/publish/{namespace}/outline"
```

### 64. 获取默认已发布协作文档
```bash
# GET /api/publish/{namespace}
curl -X GET "http://localhost:8000/api/publish/{namespace}"
```

### 65. 获取已发布协作文档
```bash
# GET /api/publish/{namespace}/{publish_name}
curl -X GET "http://localhost:8000/api/publish/{namespace}/{publish_name}"
```

### 66. 获取已发布协作文档 Blob
```bash
# GET /api/publish/{namespace}/{publish_name}/blob
curl -X GET "http://localhost:8000/api/publish/{namespace}/{publish_name}/blob"
```

### 67. 复制已发布页面到工作区
```bash
# POST /api/workspace/{workspace_id}/publish/duplicate
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/publish/duplicate" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "published_view_id": "{view_id}",
    "dest_view_id": "{dest_view_id}"
  }'
```

### 68. 设置默认发布视图
```bash
# PUT /api/workspace/{workspace_id}/publish-default
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/publish-default" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{"view_id": "{view_id}"}'
```

### 69. 删除默认发布视图
```bash
# DELETE /api/workspace/{workspace_id}/publish-default
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/publish-default" \
  -H "Authorization: Bearer {access_token}"
```

### 70. 获取默认发布视图信息
```bash
# GET /api/workspace/{workspace_id}/publish-default
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/publish-default" \
  -H "Authorization: Bearer {access_token}"
```

---

## 模板中心

### 71. 创建模板分类
```bash
# POST /api/template-center/category
curl -X POST "http://localhost:8000/api/template-center/category" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Category Name",
    "description": "Description",
    "category_type": "UseCase"
  }'
```

### 72. 获取模板分类列表
```bash
# GET /api/template-center/category
curl -X GET "http://localhost:8000/api/template-center/category?name_contains=project" \
  -H "Authorization: Bearer {access_token}"
```

### 73. 获取模板分类
```bash
# GET /api/template-center/category/{category_id}
curl -X GET "http://localhost:8000/api/template-center/category/{category_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 74. 删除模板分类
```bash
# DELETE /api/template-center/category/{category_id}
curl -X DELETE "http://localhost:8000/api/template-center/category/{category_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 75. 更新模板分类
```bash
# PATCH /api/template-center/category/{category_id}
curl -X PATCH "http://localhost:8000/api/template-center/category/{category_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "description": "Updated Description"
  }'
```

### 76. 创建模板创作者
```bash
# POST /api/template-center/creator
curl -X POST "http://localhost:8000/api/template-center/creator" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Creator Name",
    "avatar_url": "https://...",
    "account_links": []
  }'
```

### 77. 获取模板创作者列表
```bash
# GET /api/template-center/creator
curl -X GET "http://localhost:8000/api/template-center/creator" \
  -H "Authorization: Bearer {access_token}"
```

### 78. 获取模板创作者
```bash
# GET /api/template-center/creator/{creator_id}
curl -X GET "http://localhost:8000/api/template-center/creator/{creator_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 79. 删除模板创作者
```bash
# DELETE /api/template-center/creator/{creator_id}
curl -X DELETE "http://localhost:8000/api/template-center/creator/{creator_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 80. 更新模板创作者
```bash
# PATCH /api/template-center/creator/{creator_id}
curl -X PATCH "http://localhost:8000/api/template-center/creator/{creator_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "avatar_url": "https://...",
    "account_links": []
  }'
```

### 81. 创建模板
```bash
# POST /api/template-center/template
curl -X POST "http://localhost:8000/api/template-center/template" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "view_id": "{view_id}",
    "name": "Template Name",
    "description": "Description",
    "about": "About text",
    "view_url": "https://...",
    "category_ids": [],
    "creator_id": "{creator_id}"
  }'
```

### 82. 获取模板
```bash
# GET /api/template-center/template/{view_id}
curl -X GET "http://localhost:8000/api/template-center/template/{view_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 83. 获取模板列表
```bash
# GET /api/template-center/template
curl -X GET "http://localhost:8000/api/template-center/template?category_id={category_id}&is_featured=true" \
  -H "Authorization: Bearer {access_token}"
```

### 84. 更新模板
```bash
# PATCH /api/template-center/template/{view_id}
curl -X PATCH "http://localhost:8000/api/template-center/template/{view_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Template Name"
  }'
```

### 85. 删除模板
```bash
# DELETE /api/template-center/template/{view_id}
curl -X DELETE "http://localhost:8000/api/template-center/template/{view_id}" \
  -H "Authorization: Bearer {access_token}"
```

---

## 计费订阅

### 86. 获取客户 ID
```bash
# GET /billing/api/v1/customer-id
curl -X GET "http://localhost:8000/billing/api/v1/customer-id" \
  -H "Authorization: Bearer {access_token}"
```

### 87. 创建订阅
```bash
# GET /billing/api/v1/subscription-link
curl -X GET "http://localhost:8000/billing/api/v1/subscription-link?workspace_id={workspace_id}&recurring_interval=Month&workspace_subscription_plan=Pro&success_url=https://..." \
  -H "Authorization: Bearer {access_token}"
```

### 88. 取消订阅
```bash
# POST /billing/api/v1/cancel-subscription
curl -X POST "http://localhost:8000/billing/api/v1/cancel-subscription" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "reason": "Too expensive"
  }'
```

### 89. 列出订阅
```bash
# GET /billing/api/v1/subscription-status
curl -X GET "http://localhost:8000/billing/api/v1/subscription-status" \
  -H "Authorization: Bearer {access_token}"
```

### 90. 获取门户会话链接
```bash
# GET /billing/api/v1/portal-session-link
curl -X GET "http://localhost:8000/billing/api/v1/portal-session-link" \
  -H "Authorization: Bearer {access_token}"
```

### 91. 获取工作区订阅
```bash
# GET /billing/api/v1/subscription-status/{workspace_id}
curl -X GET "http://localhost:8000/billing/api/v1/subscription-status/{workspace_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 92. 获取活动订阅
```bash
# GET /billing/api/v1/active-subscription/{workspace_id}
curl -X GET "http://localhost:8000/billing/api/v1/active-subscription/{workspace_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 93. 设置订阅周期
```bash
# POST /billing/api/v1/subscription-recurring-interval
curl -X POST "http://localhost:8000/billing/api/v1/subscription-recurring-interval" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "recurring_interval": "Year"
  }'
```

### 94. 获取订阅计划详情
```bash
# GET /billing/api/v1/subscriptions
curl -X GET "http://localhost:8000/billing/api/v1/subscriptions" \
  -H "Authorization: Bearer {access_token}"
```

---

## 成员与权限

### 95. 离开工作区
```bash
# POST /api/workspace/{workspace_id}/leave
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/leave" \
  -H "Authorization: Bearer {access_token}"
```

### 96. 获取工作区成员
```bash
# GET /api/workspace/{workspace_id}/member
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/member" \
  -H "Authorization: Bearer {access_token}"
```

### 97. 邀请工作区成员
```bash
# POST /api/workspace/{workspace_id}/invite
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/invite" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "email": "user@example.com",
      "role": "Member"
    }
  ]'
```

### 98. 列出工作区邀请
```bash
# GET /api/workspace/invitation
curl -X GET "http://localhost:8000/api/workspace/invitation?status=Pending" \
  -H "Authorization: Bearer {access_token}"
```

### 99. 获取工作区邀请
```bash
# GET /api/workspace/invitation/{invite_id}
curl -X GET "http://localhost:8000/api/workspace/invitation/{invite_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 100. 接受工作区邀请
```bash
# POST /api/workspace/invitation/{invite_id}/accept
curl -X POST "http://localhost:8000/api/workspace/invitation/{invite_id}/accept" \
  -H "Authorization: Bearer {access_token}"
```

### 101. 添加工作区成员
```bash
# POST /api/workspace/{workspace_id}/member
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/member" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "email": "user@example.com",
      "role": "Member"
    }
  ]'
```

### 102. 更新工作区成员
```bash
# PUT /api/workspace/{workspace_id}/member
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/member" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "role": "Owner"
  }'
```

### 103. 移除工作区成员
```bash
# DELETE /api/workspace/{workspace_id}/member
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/member" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '["user1@example.com", "user2@example.com"]'
```

### 104. 获取工作区成员
```bash
# GET /api/workspace/{workspace_id}/member/{uid}
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/member/{uid}" \
  -H "Authorization: Bearer {access_token}"
```

### 105. 列出可提及的人员
```bash
# GET /api/workspace/{workspace_id}/mentionable-person
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/mentionable-person" \
  -H "Authorization: Bearer {access_token}"
```

### 106. 获取可提及的人员
```bash
# GET /api/workspace/{workspace_id}/mentionable-person/{person_id}
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/mentionable-person/{person_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 107. 更新工作区成员资料
```bash
# PUT /api/workspace/{workspace_id}/member-profile
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/member-profile" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Name",
    "email": "newemail@example.com"
  }'
```

### 108. 列出页面可提及的人员
```bash
# GET /api/workspace/{workspace_id}/page/{view_id}/mentionable-person
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/page/{view_id}/mentionable-person" \
  -H "Authorization: Bearer {access_token}"
```

### 109. 更新页面提及
```bash
# POST /api/workspace/{workspace_id}/page/{view_id}/mention
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/page/{view_id}/mention" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "mentioned_person_ids": ["{person_id}"]
  }'
```

### 110. 上传用户头像
```bash
# POST /api/user/image-upload
curl -X POST "http://localhost:8000/api/user/image-upload" \
  -H "Authorization: Bearer {access_token}" \
  -F "file=@avatar.png"
```

### 111. 获取用户头像
```bash
# GET /api/user/{person_id}/image/{file_id}
curl -X GET "http://localhost:8000/api/user/{person_id}/image/{file_id}" \
  -H "Authorization: Bearer {access_token}"
```

---

## 视图管理

### 112. 创建文件夹视图
```bash
# POST /api/workspace/{workspace_id}/view/folder
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/folder" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "parent_view_id": "{parent_id}",
    "name": "My Folder"
  }'
```

### 113. 创建工作区页面视图
```bash
# POST /api/workspace/{workspace_id}/view/page
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/page" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "parent_view_id": "{parent_id}",
    "layout": "Document",
    "name": "My Page"
  }'
```

### 114. 收藏页面视图
```bash
# POST /api/workspace/{workspace_id}/view/{view_id}/favorite
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/favorite" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "is_favorited": true
  }'
```

### 115. 移动工作区页面视图
```bash
# PATCH /api/workspace/{workspace_id}/view/{view_id}/move
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/move" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "new_parent_id": "{new_parent_id}",
    "prev_view_id": "{prev_view_id}"
  }'
```

### 116. 移动页面到回收站
```bash
# DELETE /api/workspace/{workspace_id}/view/{view_id}
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 117. 从回收站恢复页面
```bash
# PATCH /api/workspace/{workspace_id}/view/{view_id}/restore
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/restore" \
  -H "Authorization: Bearer {access_token}"
```

### 118. 从回收站恢复所有页面
```bash
# PATCH /api/workspace/{workspace_id}/view/restore-all
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/view/restore-all" \
  -H "Authorization: Bearer {access_token}"
```

### 119. 添加最近页面
```bash
# POST /api/workspace/{workspace_id}/view/recent
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/recent" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "view_ids": ["{view_id}"]
  }'
```

### 120. 从回收站删除页面
```bash
# DELETE /api/workspace/{workspace_id}/view/{view_id}/permanent
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/permanent" \
  -H "Authorization: Bearer {access_token}"
```

### 121. 从回收站删除所有页面
```bash
# DELETE /api/workspace/{workspace_id}/view/trash/all
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/view/trash/all" \
  -H "Authorization: Bearer {access_token}"
```

### 122. 更新工作区页面视图
```bash
# PATCH /api/workspace/{workspace_id}/view/{view_id}
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "icon": "📄"
  }'
```

### 123. 获取工作区页面视图
```bash
# GET /api/workspace/{workspace_id}/view/{view_id}
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 124. 发布页面
```bash
# POST /api/workspace/{workspace_id}/view/{view_id}/publish
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/publish" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "publish_name": "my-page"
  }'
```

### 125. 取消发布页面
```bash
# DELETE /api/workspace/{workspace_id}/view/{view_id}/publish
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/publish" \
  -H "Authorization: Bearer {access_token}"
```

### 126. 创建空间
```bash
# POST /api/workspace/{workspace_id}/space
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/space" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Space",
    "space_permission": "PublicToAll"
  }'
```

### 127. 更新空间
```bash
# PATCH /api/workspace/{workspace_id}/space/{view_id}
curl -X PATCH "http://localhost:8000/api/workspace/{workspace_id}/space/{view_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Space Name"
  }'
```

### 128. 更新页面名称
```bash
# PUT /api/workspace/{workspace_id}/view/{view_id}/name
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/name" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Page Name"
  }'
```

### 129. 更新页面图标
```bash
# PUT /api/workspace/{workspace_id}/view/{view_id}/icon
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/icon" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "icon": "📝"
  }'
```

### 130. 更新页面额外信息
```bash
# PUT /api/workspace/{workspace_id}/view/{view_id}/extra
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/extra" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "extra": {"key": "value"}
  }'
```

### 131. 移除页面图标
```bash
# DELETE /api/workspace/{workspace_id}/view/{view_id}/icon
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/icon" \
  -H "Authorization: Bearer {access_token}"
```

### 132. 附加块到页面
```bash
# POST /api/workspace/{workspace_id}/view/{view_id}/block
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/block" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "block_id": "{block_id}",
    "data": {}
  }'
```

### 133. 创建数据库视图
```bash
# POST /api/workspace/{workspace_id}/view/{view_id}/database-view
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/database-view" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "database_view_id": "{view_id}",
    "layout": "Grid"
  }'
```

### 134. 复制视图及其子项
```bash
# POST /api/workspace/{workspace_id}/view/{view_id}/duplicate
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/view/{view_id}/duplicate" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "include_children": true
  }'
```

---

## 其他功能

### 135. 数据库相关

#### 列出数据库
```bash
# GET /api/workspace/{workspace_id}/database
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/database" \
  -H "Authorization: Bearer {access_token}"
```

#### 列出数据库行 ID
```bash
# GET /api/workspace/{workspace_id}/database/{database_id}/row
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/row" \
  -H "Authorization: Bearer {access_token}"
```

#### 获取数据库字段
```bash
# GET /api/workspace/{workspace_id}/database/{database_id}/field
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/field" \
  -H "Authorization: Bearer {access_token}"
```

#### 添加数据库字段
```bash
# POST /api/workspace/{workspace_id}/database/{database_id}/field
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/field" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "field_type": "RichText",
    "name": "Description"
  }'
```

#### 列出更新的数据库行
```bash
# GET /api/workspace/{workspace_id}/database/{database_id}/row/updated
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/row/updated?after=2024-01-01T00:00:00Z" \
  -H "Authorization: Bearer {access_token}"
```

#### 列出数据库行详情
```bash
# POST /api/workspace/{workspace_id}/database/{database_id}/row/detail
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/row/detail" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "row_ids": ["row1", "row2"],
    "with_doc": true
  }'
```

#### 添加数据库项
```bash
# POST /api/workspace/{workspace_id}/database/{database_id}/row
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/database/{database_id}/row" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "cells_by_id": {"field_id": "value"},
    "row_doc_content": "content"
  }'
```

### 136. 快速笔记

#### 创建快速笔记
```bash
# POST /api/workspace/{workspace_id}/quick-note
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/quick-note" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {"content": "Quick note"}
  }'
```

#### 列出快速笔记
```bash
# GET /api/workspace/{workspace_id}/quick-note
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/quick-note?search_term=hello&offset=0&limit=10" \
  -H "Authorization: Bearer {access_token}"
```

#### 更新快速笔记
```bash
# PUT /api/workspace/{workspace_id}/quick-note/{quick_note_id}
curl -X PUT "http://localhost:8000/api/workspace/{workspace_id}/quick-note/{quick_note_id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {"content": "Updated content"}
  }'
```

#### 删除快速笔记
```bash
# DELETE /api/workspace/{workspace_id}/quick-note/{quick_note_id}
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/quick-note/{quick_note_id}" \
  -H "Authorization: Bearer {access_token}"
```

### 137. 访问请求

#### 获取访问请求
```bash
# GET /api/access-request/{access_request_id}
curl -X GET "http://localhost:8000/api/access-request/{access_request_id}" \
  -H "Authorization: Bearer {access_token}"
```

#### 创建访问请求
```bash
# POST /api/access-request
curl -X POST "http://localhost:8000/api/access-request" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "{workspace_id}",
    "view_id": "{view_id}"
  }'
```

#### 批准访问请求
```bash
# POST /api/access-request/{access_request_id}/approve
curl -X POST "http://localhost:8000/api/access-request/{access_request_id}/approve" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "is_approved": true
  }'
```

#### 拒绝访问请求
```bash
# POST /api/access-request/{access_request_id}/approve
curl -X POST "http://localhost:8000/api/access-request/{access_request_id}/approve" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "is_approved": false
  }'
```

### 138. 访客共享

#### 与访客共享视图
```bash
# POST /api/workspace/{workspace_id}/share-view
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/share-view" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "view_id": "{view_id}",
    "emails": ["guest@example.com"]
  }'
```

#### 撤销共享视图访问
```bash
# POST /api/workspace/{workspace_id}/share-view/{view_id}/revoke
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/share-view/{view_id}/revoke" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "emails": ["guest@example.com"]
  }'
```

#### 获取共享视图
```bash
# GET /api/workspace/{workspace_id}/share-view
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/share-view" \
  -H "Authorization: Bearer {access_token}"
```

#### 获取共享视图详情
```bash
# GET /api/workspace/{workspace_id}/share-view/{view_id}/details
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/share-view/{view_id}/details?ancestor_view_ids={id1},{id2}" \
  -H "Authorization: Bearer {access_token}"
```

### 139. 邀请码

#### 通过邀请码加入工作区
```bash
# POST /api/workspace/join-by-invite-code
curl -X POST "http://localhost:8000/api/workspace/join-by-invite-code" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "INVITE123"
  }'
```

#### 获取邀请码信息
```bash
# GET /api/invite-code-info?code=INVITE123
curl -X GET "http://localhost:8000/api/invite-code-info?code=INVITE123" \
  -H "Authorization: Bearer {access_token}"
```

#### 创建工作区邀请码
```bash
# POST /api/workspace/{workspace_id}/invite-code
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/invite-code" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "max_uses": 10,
    "expires_at": "2024-12-31T23:59:59Z"
  }'
```

#### 获取工作区邀请码
```bash
# GET /api/workspace/{workspace_id}/invite-code
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/invite-code" \
  -H "Authorization: Bearer {access_token}"
```

#### 删除工作区邀请码
```bash
# DELETE /api/workspace/{workspace_id}/invite-code
curl -X DELETE "http://localhost:8000/api/workspace/{workspace_id}/invite-code" \
  -H "Authorization: Bearer {access_token}"
```

### 140. 发布评论和反应

#### 在发布视图上创建评论
```bash
# POST /api/publish/{view_id}/comment
curl -X POST "http://localhost:8000/api/publish/{view_id}/comment" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Great article!",
    "reply_comment_id": null
  }'
```

#### 删除发布视图上的评论
```bash
# DELETE /api/publish/{view_id}/comment/{comment_id}
curl -X DELETE "http://localhost:8000/api/publish/{view_id}/comment/{comment_id}" \
  -H "Authorization: Bearer {access_token}"
```

#### 获取发布视图评论
```bash
# GET /api/publish/{view_id}/comment
curl -X GET "http://localhost:8000/api/publish/{view_id}/comment"
```

#### 在评论上创建反应
```bash
# POST /api/publish/{view_id}/comment/{comment_id}/reaction
curl -X POST "http://localhost:8000/api/publish/{view_id}/comment/{comment_id}/reaction" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "reaction_type": "👍"
  }'
```

#### 删除评论上的反应
```bash
# DELETE /api/publish/{view_id}/comment/{comment_id}/reaction
curl -X DELETE "http://localhost:8000/api/publish/{view_id}/comment/{comment_id}/reaction?reaction_type=👍" \
  -H "Authorization: Bearer {access_token}"
```

#### 获取发布视图反应
```bash
# GET /api/publish/{view_id}/reaction
curl -X GET "http://localhost:8000/api/publish/{view_id}/reaction?comment_id={comment_id}"
```

### 141. 服务器信息

#### 获取服务器信息
```bash
# GET /api/server
curl -X GET "http://localhost:8000/api/server" \
  -H "Authorization: Bearer {access_token}"
```

### 142. 嵌入信息

#### 获取协作嵌入信息
```bash
# GET /api/workspace/{workspace_id}/collab/{object_id}/embed
curl -X GET "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}/embed" \
  -H "Authorization: Bearer {access_token}"
```

#### 批量获取协作嵌入信息
```bash
# POST /api/workspace/{workspace_id}/collab/embed
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/collab/embed" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "object_id": "{object_id}",
      "collab_type": "Document"
    }
  ]'
```

#### 强制生成协作嵌入
```bash
# POST /api/workspace/{workspace_id}/collab/{object_id}/embed/generate
curl -X POST "http://localhost:8000/api/workspace/{workspace_id}/collab/{object_id}/embed/generate" \
  -H "Authorization: Bearer {access_token}"
```

---

## WebSocket 连接

### 143. WebSocket V1
```bash
# 连接到 WebSocket (需要使用 WebSocket 客户端)
wscat -c "wss://your-server.com/ws" \
  -H "Authorization: Bearer {access_token}" \
  -H "client-version: 0.6.7" \
  -H "device-id: {device_id}"
```

### 144. WebSocket V2
```bash
# 连接到 WebSocket V2
wscat -c "wss://your-server.com/ws/v2" \
  -H "Authorization: Bearer {access_token}" \
  -H "device-id: {device_id}"
```

---

## 认证相关 (GoTrue)

### 145. GoTrue OAuth 授权
```bash
# GET /authorize?provider=google
curl -X GET "https://your-gotrue-server.com/authorize?provider=google&redirect_to=appflowy-flutter://"
```

### 146. GoTrue 令牌刷新
```bash
# 使用 GoTrue 客户端刷新令牌
curl -X POST "https://your-gotrue-server.com/token?grant_type=refresh_token" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "{refresh_token}"
  }'
```

---

## 注意事项

### 通用请求头
所有需要认证的请求都应包含以下请求头：
- `Authorization: Bearer {access_token}` - 访问令牌
- `client-version: 0.6.7` - 客户端版本
- `device-id: {device_id}` - 设备 ID
- `client-timestamp: {unix_timestamp}` - 客户端时间戳

### AI 模型请求头
AI 相关请求可以包含：
- `ai-model: Auto` - 使用自动选择的 AI 模型
- `ai-model: gpt-4` - 使用指定的 AI 模型

### 压缩支持
支持 Brotli 压缩的请求可以包含：
- `X-Compression-Type: brotli`
- `X-Compression-Buffer-Size: {buffer_size}`

### 错误处理
所有 API 返回标准的错误格式：
```json
{
  "code": "ErrorCode",
  "message": "Error description"
}
```

### 分页
支持分页的端点通常使用：
- `offset` - 偏移量
- `limit` - 限制数量

### URL 编码
对于包含特殊字符的参数（如 `parent_dir`），需要进行 URL 编码。

### 邮箱验证码登录流程
使用邮箱验证码登录/注册的完整流程：

1. **发送验证码**: 调用 GoTrue 的 `/magiclink` 接口发送验证码到用户邮箱
2. **用户收到邮件**: 邮件中包含 6 位数字验证码
3. **验证登录**: 调用 GoTrue 的 `/verify` 接口，提交邮箱和验证码
4. **获取令牌**: 验证成功后返回 `access_token` 和 `refresh_token`
5. **访问 API**: 使用 `access_token` 访问 AppFlowy Cloud 的其他 API

**注意事项**:
- GoTrue 服务默认运行在 `http://localhost:9999`
- 验证码有效期通常为 5-10 分钟
- 如果用户首次使用验证码登录，系统会自动创建账户
- 验证码只能使用一次
- 需要先配置好邮件服务器（SMTP）才能发送验证码

---

## 版本信息
- Client API Version: 0.2.0
- Minimum Client Version: 0.6.7
- Maximum Client Version: 1.0.0

---

生成时间: 2024年

