---
layout: post
permalink: /blogs/agent/fastapi/index.html
title: FastAPI
---

* awsl  //星号后可能需要空一格，后面需要加上一段文本（用途不明，但是非加不可） 
{:toc}




# FastAPI 入门到实战：构建高性能 Python Web API

> FastAPI 是一个现代、快速（高性能）的 Web 框架，用于构建基于 Python 的 API，基于标准的 Python 类型提示。

------

## 为什么选择 FastAPI？

在 Python 的 Web 框架生态中，Django 和 Flask 长期占据主流。但随着 API 驱动开发的兴起，FastAPI 凭借以下几点迅速赢得开发者青睐：

- **极致性能**：基于 Starlette 和 Pydantic，性能与 NodeJS、Go 比肩
- **自动文档**：无需额外配置，自动生成 Swagger UI 和 ReDoc 交互文档
- **类型安全**：利用 Python 类型提示，在编码阶段即可发现错误
- **开发效率高**：代码量减少约 40%，Bug 减少约 40%
- **异步原生支持**：天然支持 `async/await`，轻松处理高并发

------

## 环境安装

```bash
pip install fastapi uvicorn[standard]
```

- `fastapi`：核心框架
- `uvicorn`：ASGI 服务器，用于运行 FastAPI 应用

------

## 快速上手：Hello World

创建 `main.py`：

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI!"}
```

启动服务：

```bash
uvicorn main:app --reload
```

访问 `http://127.0.0.1:8000`，即可看到响应。访问 `http://127.0.0.1:8000/docs` 打开自动生成的 Swagger 文档。

------

## 路径参数与查询参数

```python
from fastapi import FastAPI

app = FastAPI()

# 路径参数
@app.get("/items/{item_id}")
def read_item(item_id: int):
    return {"item_id": item_id}

# 查询参数
@app.get("/search")
def search_items(keyword: str, page: int = 1, size: int = 10):
    return {"keyword": keyword, "page": page, "size": size}
```

FastAPI 会自动完成：

- 路径参数类型校验（`item_id` 必须是整数）
- 查询参数的默认值处理
- 请求参数的文档生成

------

## 请求体：使用 Pydantic 模型

Pydantic 是 FastAPI 的数据校验引擎，用于定义请求和响应的数据结构。

```python
from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Optional

app = FastAPI()

class Item(BaseModel):
    name: str = Field(..., description="商品名称", min_length=1, max_length=50)
    price: float = Field(..., gt=0, description="价格，必须大于0")
    description: Optional[str] = None
    is_available: bool = True

@app.post("/items/", response_model=Item)
def create_item(item: Item):
    # 此处可以写入数据库
    return item
```

Pydantic 会自动校验传入的 JSON 数据，字段不合法时返回清晰的错误信息。

------

## 依赖注入（Dependency Injection）

FastAPI 内置依赖注入系统，非常适合处理认证、数据库会话、公共参数等逻辑复用场景。

```python
from fastapi import FastAPI, Depends, HTTPException, Header

app = FastAPI()

# 模拟 Token 验证依赖
def verify_token(x_token: str = Header(...)):
    if x_token != "secret-token":
        raise HTTPException(status_code=403, detail="Token 无效")
    return x_token

@app.get("/protected")
def protected_route(token: str = Depends(verify_token)):
    return {"message": "访问成功", "token": token}
```

------

## 异步支持：async/await

FastAPI 原生支持异步处理，适合 I/O 密集型任务（如数据库查询、外部 API 调用）：

```python
import asyncio
from fastapi import FastAPI

app = FastAPI()

async def fetch_data_from_db(item_id: int):
    await asyncio.sleep(0.1)  # 模拟异步数据库查询
    return {"id": item_id, "name": "示例商品"}

@app.get("/async-items/{item_id}")
async def read_item_async(item_id: int):
    data = await fetch_data_from_db(item_id)
    return data
```

------

## 错误处理

```python
from fastapi import FastAPI, HTTPException

app = FastAPI()

fake_db = {1: "Apple", 2: "Banana"}

@app.get("/fruits/{fruit_id}")
def get_fruit(fruit_id: int):
    if fruit_id not in fake_db:
        raise HTTPException(
            status_code=404,
            detail=f"ID 为 {fruit_id} 的水果不存在"
        )
    return {"fruit": fake_db[fruit_id]}
```

FastAPI 会将 `HTTPException` 自动转换为标准的 JSON 错误响应：

```json
{
  "detail": "ID 为 3 的水果不存在"
}
```

------

## 路由拆分：使用 APIRouter

随着项目增大，推荐将路由按模块拆分：

```python
# routers/users.py
from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["用户"])

@router.get("/")
def list_users():
    return [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]

@router.get("/{user_id}")
def get_user(user_id: int):
    return {"id": user_id, "name": "Alice"}
# main.py
from fastapi import FastAPI
from routers import users

app = FastAPI()
app.include_router(users.router)
```

------

## 与数据库集成：SQLAlchemy + FastAPI

```python
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker, Session

DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)

Base.metadata.create_all(bind=engine)

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/users/{user_id}")
def read_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return user
```

------

## 中间件

中间件可以拦截每一个请求和响应，适合做日志记录、跨域处理、耗时统计等：

```python
import time
from fastapi import FastAPI, Request

app = FastAPI()

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = f"{process_time:.4f}s"
    return response
```

------

## 项目结构推荐

```
my_project/
├── main.py             # 应用入口
├── config.py           # 配置管理
├── database.py         # 数据库连接
├── models/             # SQLAlchemy 模型
│   └── user.py
├── schemas/            # Pydantic 模式
│   └── user.py
├── routers/            # 路由模块
│   └── users.py
├── services/           # 业务逻辑层
│   └── user_service.py
└── dependencies.py     # 公共依赖
```

------

## 总结

FastAPI 将现代 Python 的最佳特性融为一体——类型提示、异步支持、自动文档——让构建生产级 API 变得既高效又愉快。

| 特性     | FastAPI | Flask    | Django REST |
| -------- | ------- | -------- | ----------- |
| 性能     | ⭐⭐⭐⭐⭐   | ⭐⭐⭐      | ⭐⭐⭐         |
| 自动文档 | ✅ 内置  | ❌ 需插件 | ❌ 需插件    |
| 类型校验 | ✅ 原生  | ❌        | ⚠️ 部分      |
| 异步支持 | ✅ 原生  | ⚠️ 有限   | ⚠️ 有限      |
| 学习曲线 | 低      | 极低     | 高          |

如果你正在构建新的 API 项目，FastAPI 是目前 Python 生态中最值得推荐的选择之一。

------

*参考资料：[FastAPI 官方文档](https://fastapi.tiangolo.com/zh/)*