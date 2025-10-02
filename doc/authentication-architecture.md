# AppFlowy 用户认证架构详解

## 📋 目录
- [架构概览](#架构概览)
- [部署模式](#部署模式)
- [认证流程详解](#认证流程详解)
- [JWT Token 验证机制](#jwt-token-验证机制)
- [代码实现分析](#代码实现分析)
- [总结](#总结)

---

## 架构概览

### 核心结论：**客户端直连 GoTrue**

AppFlowy 客户端**直接连接 GoTrue 服务**进行身份认证，而不是通过 AppFlowy Cloud 作为中间代理。

```
┌─────────────────┐
│  AppFlowy 客户端  │
│   (Flutter)     │
└────────┬────────┘
         │
         │ 直接连接（关键点！）
         ↓
    ┌─────────────────────────────────────┐
    │                                     │
    │   ┌──────────┐      ┌───────────┐  │
    │   │  GoTrue  │      │ AppFlowy  │  │
    │   │  :9999   │      │  Cloud    │  │
    │   │          │      │  :8000    │  │
    │   └────┬─────┘      └─────┬─────┘  │
    │        │                  │        │
    │        └──────┬───────────┘        │
    │               ↓                    │
    │         ┌───────────┐              │
    │         │ PostgreSQL│              │
    │         │  数据库    │              │
    │         └───────────┘              │
    │                                     │
    │        AppFlowy Cloud 服务端         │
    └─────────────────────────────────────┘
```

---

## 部署模式

### 1. 生产模式 (使用 Nginx)

在生产环境中，Nginx 作为反向代理统一入口：

```
                     ┌─────────────────────────────┐
                     │    Nginx 反向代理 (:80/443)   │
                     └───────────┬─────────────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ↓                ↓                ↓
        /gotrue/*           /api/*            /ws
     (转发到 GoTrue)    (转发到 AppFlowy)   (WebSocket)
                │                │                │
                ↓                ↓                ↓
         ┌──────────┐      ┌──────────┐    ┌──────────┐
         │ GoTrue   │      │ AppFlowy │    │ AppFlowy │
         │  :9999   │      │  Cloud   │    │  Cloud   │
         └──────────┘      │  :8000   │    │  :8000   │
                           └──────────┘    └──────────┘
```

**客户端配置（生产）：**
```dart
// lib/env/cloud_env.dart (268-277行)
return AppFlowyCloudConfiguration(
  base_url: baseUrl,                              // http://example.com
  ws_base_url: await _getAppFlowyCloudWSUrl(),    // ws://example.com/ws/v1
  gotrue_url: await _getAppFlowyCloudGotrueUrl(), // http://example.com/gotrue
  // ...
);

// 347-349行
Future<String> _getAppFlowyCloudGotrueUrl(String baseURL) async {
  return "$baseURL/gotrue";  // 拼接 /gotrue 路径
}
```

**Nginx 配置：**
```nginx
# nginx/nginx.conf (53-63行)
location /gotrue/ {
    proxy_pass $gotrue_backend;  # http://gotrue:9999
    rewrite ^/gotrue(/.*)$ $1 break;  # 去掉 /gotrue 前缀
    
    proxy_set_header Host $http_host;
    proxy_pass_request_headers on;
}
```

### 2. 开发模式 (直连)

开发环境直接连接服务，不经过 Nginx：

```
┌─────────────────┐
│  AppFlowy 客户端  │
└────────┬────────┘
         │
    ┌────┴────────────────┐
    │                     │
    ↓                     ↓
http://localhost:9999  http://localhost:8000
    │                     │
    ↓                     ↓
┌──────────┐         ┌──────────┐
│ GoTrue   │         │ AppFlowy │
│  :9999   │         │  Cloud   │
└──────────┘         └──────────┘
```

**客户端配置（开发）：**
```dart
// lib/env/cloud_env.dart (260-267行)
if (authenticatorType == AuthenticatorType.appflowyCloudDevelop) {
  return AppFlowyCloudConfiguration(
    base_url: "$baseUrl:8000",        // http://localhost:8000
    ws_base_url: "ws://${baseUri.host}:8000/ws/v1",
    gotrue_url: "$baseUrl:9999",      // http://localhost:9999 (直连！)
    // ...
  );
}
```

---

## 认证流程详解

### 流程 1: 用户注册/登录

```
┌─────────┐                    ┌─────────┐                 ┌──────────────┐
│ 客户端   │                    │ GoTrue  │                 │ AppFlowy Cloud│
└────┬────┘                    └────┬────┘                 └──────┬───────┘
     │                              │                             │
     │ 1. POST /token (密码登录)     │                             │
     │ grant_type=password          │                             │
     │ email, password              │                             │
     ├─────────────────────────────>│                             │
     │                              │                             │
     │                              │ 2. 验证用户凭据                │
     │                              │    查询 auth.users 表         │
     │                              │                             │
     │ 3. 返回 JWT Token            │                             │
     │ {                            │                             │
     │   access_token: "eyJhbG...", │                             │
     │   refresh_token: "v1.MR...", │                             │
     │   user: {...}                │                             │
     │ }                            │                             │
     │<─────────────────────────────┤                             │
     │                              │                             │
     │ 4. 验证 Token 并初始化用户      │                             │
     │ GET /api/user/verify/{token} │                             │
     ├──────────────────────────────┼────────────────────────────>│
     │                              │                             │
     │                              │ 5. AppFlowy Cloud 调用       │
     │                              │    gotrue_client.user_info() │
     │                              │<────────────────────────────┤
     │                              │                             │
     │                              │ 6. GET /user (带 Token)      │
     │                              │    Authorization: Bearer ... │
     │                              │                             │
     │                              │ 7. 返回用户信息               │
     │                              │    验证 JWT 签名               │
     │                              │    返回 User 数据             │
     │                              ├────────────────────────────>│
     │                              │                             │
     │                              │                             │ 8. 创建用户
     │                              │                             │    (如果是新用户)
     │                              │                             │    初始化工作区
     │                              │                             │
     │ 9. 返回 { is_new: true/false }                             │
     │<─────────────────────────────┼─────────────────────────────┤
     │                              │                             │
     │ 10. 保存 Token 到本地         │                             │
     │     后续请求携带 Token         │                             │
     │                              │                             │
```

**关键代码：**

#### 客户端登录 (Rust)
```rust
// AppFlowy-Cloud/libs/client-api/src/http.rs (268-286行)
pub async fn sign_in_password(
  &self,
  email: &str,
  password: &str,
) -> Result<SignInPasswordResponse, AppResponseError> {
  // 直接调用 gotrue_client
  let response = self
    .gotrue_client
    .token(&Grant::Password(PasswordGrant {
      email: email.to_owned(),
      password: password.to_owned(),
    }))
    .await?;
  
  // 然后调用 AppFlowy Cloud 验证 Token
  let is_new = self.verify_token_cloud(&response.access_token).await?;
  self.token.write().set(response.clone());
  
  Ok(SignInPasswordResponse {
    gotrue_response: response,
    is_new,
  })
}
```

#### GoTrue Token 生成
```rust
// AppFlowy-Cloud/libs/gotrue/src/api.rs (80-92行)
pub async fn token(&self, grant: &Grant) -> Result<GotrueTokenResponse, GoTrueError> {
  let url = format!("{}/token?grant_type={}", self.base_url, grant.type_as_str());
  let payload = grant.json_value();
  let resp = self.client.post(url).json(&payload).send().await?;
  
  if resp.status().is_success() {
    let token: GotrueTokenResponse = from_body(resp).await?;
    Ok(token)
  } else {
    // 错误处理...
  }
}
```

#### AppFlowy Cloud 验证 Token
```rust
// AppFlowy-Cloud/src/biz/user/user_verify.rs (16-34行)
pub async fn verify_token(access_token: &str, state: &AppState) -> Result<bool, AppError> {
  // 调用 GoTrue 获取用户信息，验证 Token
  let user = state.gotrue_client.user_info(access_token).await?;
  let user_uuid = uuid::Uuid::parse_str(&user.id)?;
  
  // 检查用户是否存在于 AppFlowy 数据库
  let is_new = !is_user_exist(txn.deref_mut(), &user_uuid).await?;
  
  if is_new {
    // 创建新用户并初始化工作区
    // ...
  }
  
  Ok(is_new)
}
```

### 流程 2: 后续 API 请求认证

```
┌─────────┐                              ┌──────────────┐
│ 客户端   │                              │ AppFlowy Cloud│
└────┬────┘                              └──────┬───────┘
     │                                          │
     │ 1. API 请求 (携带 JWT Token)              │
     │ GET /api/workspace/{id}                  │
     │ Authorization: Bearer eyJhbGc...         │
     ├─────────────────────────────────────────>│
     │                                          │
     │                                          │ 2. JWT 中间件验证
     │                                          │    - 提取 Bearer Token
     │                                          │    - 使用 JWT_SECRET 解码
     │                                          │    - 验证签名和过期时间
     │                                          │    - 提取 user_uuid
     │                                          │
     │ 3. 返回数据                               │
     │<─────────────────────────────────────────┤
     │                                          │
```

**关键代码：**

#### AppFlowy Cloud JWT 中间件
```rust
// AppFlowy-Cloud/src/biz/authentication/jwt.rs (126-151行)
fn get_auth_from_request(req: &HttpRequest) -> Result<Authorization, actix_web::Error> {
  let jwt_secret_data = req
    .app_data::<Data<Secret<String>>>()
    .ok_or(actix_web::error::ErrorInternalServerError("jwt secret not found"))?;
  
  let bearer = req
    .headers()
    .get("Authorization")
    .ok_or(actix_web::error::ErrorUnauthorized("No Authorization header"))?;

  let bearer_str = bearer.to_str()
    .map_err(actix_web::error::ErrorUnauthorized)?;

  let (_, token) = bearer_str
    .split_once("Bearer ")
    .ok_or(actix_web::error::ErrorUnauthorized("Invalid Authorization header"))?;

  authorization_from_token(token, jwt_secret_data)
}

// 165-175行
fn gotrue_jwt_claims_from_token(
  token: &str,
  jwt_secret: &Data<Secret<String>>,
) -> Result<GoTrueJWTClaims, actix_web::Error> {
  let claims = GoTrueJWTClaims::decode(token, jwt_secret.expose_secret().as_bytes())
    .map_err(|err| {
      actix_web::error::ErrorUnauthorized(format!("fail to decode token, error:{}", err))
    })?;
  Ok(claims)
}
```

---

## JWT Token 验证机制

### Token 结构

GoTrue 生成的 JWT Token 包含以下信息：

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user-uuid",           // 用户 UUID
    "email": "user@example.com",
    "role": "authenticated",
    "session_id": "session-uuid",
    "iat": 1234567890,            // 签发时间
    "exp": 1234574890             // 过期时间
  },
  "signature": "..."              // 使用 JWT_SECRET 签名
}
```

### 验证流程

#### 1. GoTrue 验证 (当客户端调用 GoTrue API 时)

```go
// PonyNotes-gotrue/internal/api/auth.go (18-34行)
func (a *API) requireAuthentication(w http.ResponseWriter, r *http.Request) (context.Context, error) {
  // 1. 提取 Bearer Token
  token, err := a.extractBearerToken(r)
  if err != nil {
    return nil, err
  }

  // 2. 解析 JWT Claims
  ctx, err := a.parseJWTClaims(token, r)
  if err != nil {
    return ctx, err
  }

  // 3. 加载用户或会话
  ctx, err = a.maybeLoadUserOrSession(ctx)
  if err != nil {
    return ctx, err
  }
  return ctx, err
}

// 72-105行
func (a *API) parseJWTClaims(bearer string, r *http.Request) (context.Context, error) {
  ctx := r.Context()
  config := a.config

  p := jwt.NewParser(jwt.WithValidMethods(config.JWT.ValidMethods))
  token, err := p.ParseWithClaims(bearer, &AccessTokenClaims{}, func(token *jwt.Token) (interface{}, error) {
    // 使用 JWT_SECRET 验证签名
    if alg, ok := token.Header["alg"]; ok {
      if alg == jwt.SigningMethodHS256.Name {
        return []byte(config.JWT.Secret), nil
      }
    }
    return nil, fmt.Errorf("unrecognized JWT kid %v for algorithm %v", token.Header["kid"], token.Header["alg"])
  })
  
  if err != nil {
    return nil, apierrors.NewForbiddenError(apierrors.ErrorCodeBadJWT, "invalid JWT: unable to parse or verify signature, %v", err)
  }

  return withToken(ctx, token), nil
}
```

#### 2. AppFlowy Cloud 验证 (当客户端调用 AppFlowy API 时)

AppFlowy Cloud **使用相同的 JWT_SECRET** 验证 Token：

```rust
// AppFlowy-Cloud/src/biz/authentication/jwt.rs (165-175行)
fn gotrue_jwt_claims_from_token(
  token: &str,
  jwt_secret: &Data<Secret<String>>,
) -> Result<GoTrueJWTClaims, actix_web::Error> {
  let claims = GoTrueJWTClaims::decode(
    token,
    jwt_secret.expose_secret().as_bytes()  // 使用相同的 JWT_SECRET
  ).map_err(|err| {
    actix_web::error::ErrorUnauthorized(format!("fail to decode token, error:{}", err))
  })?;
  Ok(claims)
}
```

### 配置一致性（关键！）

**GoTrue 配置：**
```bash
# docker-compose.yml
GOTRUE_JWT_SECRET=hello456
GOTRUE_JWT_EXP=7200
```

**AppFlowy Cloud 配置：**
```bash
# docker-compose.yml
APPFLOWY_GOTRUE_JWT_SECRET=hello456  # 必须与 GoTrue 相同！
APPFLOWY_GOTRUE_JWT_EXP=7200
```

这确保了：
1. GoTrue 使用 `hello456` 签名 JWT
2. AppFlowy Cloud 使用相同的 `hello456` 验证 JWT
3. 两个服务都能正确验证对方生成的 Token

---

## 代码实现分析

### 客户端架构

#### Client 结构
```rust
// AppFlowy-Cloud/libs/client-api/src/http.rs (106-118行)
#[derive(Clone)]
pub struct Client {
  pub cloud_client: reqwest::Client,        // 用于调用 AppFlowy Cloud API
  pub(crate) gotrue_client: gotrue::api::Client,  // 用于调用 GoTrue API
  pub base_url: String,                     // AppFlowy Cloud URL
  pub ws_addr: String,                      // WebSocket URL
  pub device_id: String,
  pub client_version: Version,
  pub(crate) token: Arc<RwLock<ClientToken>>,
  // ...
}

// 126-196行 构造函数
impl Client {
  pub fn new(
    base_url: &str,
    ws_addr: &str,
    gotrue_url: &str,  // GoTrue URL 单独传入
    device_id: &str,
    config: ClientConfiguration,
    client_version: &str,
  ) -> Self {
    let reqwest_client = create_client(&config);
    
    Self {
      base_url: base_url.to_string(),
      ws_addr: ws_addr.to_string(),
      cloud_client: reqwest_client.clone(),
      // 创建独立的 GoTrue 客户端
      gotrue_client: gotrue::api::Client::new(reqwest_client, gotrue_url),
      // ...
    }
  }
}
```

#### GoTrue Client
```rust
// AppFlowy-Cloud/libs/gotrue/src/api.rs (19-31行)
#[derive(Clone, Debug)]
pub struct Client {
  client: reqwest::Client,
  pub base_url: String,  // GoTrue 的 base URL
}

impl Client {
  pub fn new(client: reqwest::Client, base_url: &str) -> Self {
    Self {
      client,
      base_url: base_url.to_owned(),
    }
  }
}
```

### 关键 API 端点

#### GoTrue API (由客户端直接调用)

```
POST   /token              # 登录获取 Token
POST   /signup             # 注册
POST   /verify             # 验证邮箱/手机
POST   /magiclink          # 发送魔法链接
POST   /recover            # 密码重置
GET    /user               # 获取用户信息 (需要 Token)
PUT    /user               # 更新用户信息 (需要 Token)
POST   /logout             # 登出 (需要 Token)
GET    /settings           # 获取 GoTrue 设置
GET    /health             # 健康检查
```

#### AppFlowy Cloud API (需要 GoTrue Token)

```
GET    /api/user/verify/{token}     # 验证 Token 并初始化用户
GET    /api/user/profile            # 获取用户资料
GET    /api/user/workspace_info     # 获取工作区信息
POST   /api/workspace               # 创建工作区
GET    /api/workspace/{id}          # 获取工作区详情
POST   /api/collab                  # 协作文档操作
```

---

## 总结

### 认证架构特点

1. **直接连接模式**
   - 客户端直接连接 GoTrue 进行认证
   - 不经过 AppFlowy Cloud 代理
   - 提高认证性能，减少中间层

2. **Token 共享机制**
   - GoTrue 生成 JWT Token
   - AppFlowy Cloud 使用相同的 JWT_SECRET 验证 Token
   - 实现单点登录 (SSO)

3. **职责分离**
   - **GoTrue**: 用户认证、Token 管理、用户凭据验证
   - **AppFlowy Cloud**: 业务逻辑、工作区管理、协作文档

4. **部署灵活性**
   - 生产环境：通过 Nginx 统一入口
   - 开发环境：直连各服务端口
   - 配置简单，易于切换

### 安全性考虑

1. **JWT Secret 保护**
   - 必须确保 `GOTRUE_JWT_SECRET` 与 `APPFLOWY_GOTRUE_JWT_SECRET` 完全一致
   - 使用强密码，定期轮换

2. **HTTPS 加密**
   - 生产环境必须使用 HTTPS
   - 防止 Token 被中间人拦截

3. **Token 过期机制**
   - Access Token 短期有效 (如 2 小时)
   - Refresh Token 长期有效，用于刷新 Access Token

4. **跨域安全**
   - Nginx 正确配置 CORS
   - 验证 Origin 头部

### 架构优势

✅ **性能优化**: 认证请求直连 GoTrue，减少延迟  
✅ **可扩展性**: GoTrue 和 AppFlowy Cloud 可独立扩展  
✅ **解耦设计**: 认证服务与业务逻辑分离  
✅ **标准化**: 使用标准 JWT 协议，易于集成第三方服务  
✅ **灵活部署**: 支持多种部署模式（直连/反向代理）  

---

## 附录：相关配置文件

### Docker Compose 配置
```yaml
services:
  gotrue:
    environment:
      - GOTRUE_JWT_SECRET=hello456
      - PORT=9999
      
  appflowy_cloud:
    environment:
      - APPFLOWY_GOTRUE_BASE_URL=http://gotrue:9999
      - APPFLOWY_GOTRUE_JWT_SECRET=hello456
```

### Nginx 配置
```nginx
# 生产环境反向代理
location /gotrue/ {
    proxy_pass http://gotrue:9999;
    rewrite ^/gotrue(/.*)$ $1 break;
}

location /api {
    proxy_pass http://appflowy_cloud:8000;
}
```

### 客户端配置 (Flutter)
```dart
// 生产环境
gotrue_url: "$baseURL/gotrue"  // 通过 Nginx

// 开发环境
gotrue_url: "$baseUrl:9999"    // 直连 GoTrue
```

---

**文档版本**: 1.0  
**最后更新**: 2025-10-02  
**作者**: AppFlowy Team

