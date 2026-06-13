# LangChain 入门到实战：构建你的第一个 LLM 应用

> LangChain 是一个专为大语言模型（LLM）应用开发设计的框架，帮助开发者将模型、数据、工具和逻辑链接在一起，构建真正有用的 AI 应用。

------

## 为什么需要 LangChain？

直接调用 OpenAI 或其他大模型的 API 很简单，但现实中的 AI 应用往往需要：

- 多轮对话记忆管理
- 从外部文档或数据库检索知识（RAG）
- 调用工具或执行代码
- 将多个步骤串联成复杂工作流

LangChain 把这些能力封装成标准化的组件，让开发者专注于业务逻辑，而不是重复造轮子。

------

## 核心概念一览

```
LangChain 核心组件
├── Model I/O        # 与 LLM 交互：提示词、模型调用、输出解析
├── Memory           # 对话历史管理
├── Chains           # 将多个步骤串联
├── Agents           # 让 LLM 自主决策调用工具
├── Tools            # 赋予 LLM 搜索、计算等外部能力
└── Retrievers       # 从向量数据库等检索相关内容（RAG）
```

------

## 安装

```bash
pip install langchain langchain-openai langchain-community
```

配置 API Key（以 OpenAI 为例）：

```bash
export OPENAI_API_KEY="your-api-key"
```

或在代码中：

```python
import os
os.environ["OPENAI_API_KEY"] = "your-api-key"
```

------

## 第一步：调用大模型

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o", temperature=0.7)

response = llm.invoke("用一句话解释什么是机器学习")
print(response.content)
# 机器学习是让计算机通过数据自动学习规律，无需显式编程即可完成预测或决策的技术。
```

------

## Prompt 模板

使用 `PromptTemplate` 构建可复用的提示词：

```python
from langchain_core.prompts import ChatPromptTemplate

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一位专业的{role}，请用简洁易懂的语言回答问题。"),
    ("user", "{question}")
])

chain = prompt | llm

response = chain.invoke({
    "role": "Python 工程师",
    "question": "什么是装饰器？"
})
print(response.content)
```

`|` 运算符是 LangChain 的 LCEL（LangChain Expression Language）语法，用于优雅地串联组件。

------

## 输出解析器

让模型返回结构化数据，而不是纯文本：

```python
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

class MovieReview(BaseModel):
    title: str = Field(description="电影名称")
    rating: float = Field(description="评分，满分10分")
    summary: str = Field(description="一句话简评")

parser = JsonOutputParser(pydantic_object=MovieReview)

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一位影评人，请以JSON格式回答。\n{format_instructions}"),
    ("user", "评价电影：{movie}")
]).partial(format_instructions=parser.get_format_instructions())

chain = prompt | llm | parser

result = chain.invoke({"movie": "星际穿越"})
print(result)
# {'title': '星际穿越', 'rating': 9.2, 'summary': '震撼的视觉与深刻的父女情感交织，科幻类标杆之作'}
```

------

## Memory：让对话有记忆

```python
from langchain_openai import ChatOpenAI
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

llm = ChatOpenAI(model="gpt-4o")

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一个友好的助手。"),
    MessagesPlaceholder(variable_name="history"),
    ("user", "{input}")
])

chain = prompt | llm

store = {}

def get_session_history(session_id: str):
    if session_id not in store:
        store[session_id] = InMemoryChatMessageHistory()
    return store[session_id]

chain_with_memory = RunnableWithMessageHistory(
    chain,
    get_session_history,
    input_messages_key="input",
    history_messages_key="history"
)

config = {"configurable": {"session_id": "user_001"}}

r1 = chain_with_memory.invoke({"input": "我叫小明"}, config=config)
print(r1.content)  # 你好，小明！

r2 = chain_with_memory.invoke({"input": "我叫什么名字？"}, config=config)
print(r2.content)  # 你叫小明！
```

------

## RAG：检索增强生成

RAG 是目前最实用的 LLM 应用模式之一——让模型基于你的私有文档回答问题。

### 完整 RAG 流程

```
用户问题
   │
   ▼
向量化查询 ──► 向量数据库检索相关文档
                        │
                        ▼
             拼入提示词 + LLM 生成答案
```

### 代码实现

```python
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough

# 1. 加载文档
loader = TextLoader("company_faq.txt", encoding="utf-8")
docs = loader.load()

# 2. 文本分割
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_documents(docs)

# 3. 向量化并存储
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_documents(chunks, embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

# 4. 构建 RAG Chain
prompt = ChatPromptTemplate.from_template("""
基于以下上下文回答问题，如果上下文中没有相关信息，请说"我不知道"。

上下文：
{context}

问题：{question}
""")

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

llm = ChatOpenAI(model="gpt-4o")

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
)

response = rag_chain.invoke("公司的退款政策是什么？")
print(response.content)
```

------

## Agents：让 LLM 自主使用工具

Agent 是 LangChain 最强大的特性之一——模型可以自主决定调用哪些工具、何时停止。

```python
from langchain_openai import ChatOpenAI
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.tools import tool
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
import math

@tool
def calculator(expression: str) -> str:
    """计算数学表达式，支持加减乘除和常用函数。输入如：'2 ** 10' 或 'math.sqrt(144)'"""
    try:
        result = eval(expression, {"__builtins__": {}, "math": math})
        return str(result)
    except Exception as e:
        return f"计算错误：{e}"

@tool
def get_weather(city: str) -> str:
    """获取指定城市的当前天气。"""
    # 实际使用时接入真实 API
    return f"{city}今天晴，气温 25°C，适合出行。"

tools = [calculator, get_weather]

llm = ChatOpenAI(model="gpt-4o", temperature=0)

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一个智能助手，可以使用工具来帮助用户。"),
    ("user", "{input}"),
    MessagesPlaceholder(variable_name="agent_scratchpad")
])

agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

result = executor.invoke({"input": "北京今天天气怎么样？顺便算一下 2的10次方是多少？"})
print(result["output"])
```

运行时，Agent 会自动决策调用 `get_weather` 和 `calculator` 两个工具，再综合结果回答。

------

## Streaming：流式输出

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o", streaming=True)

for chunk in llm.stream("写一首关于秋天的五言绝句"):
    print(chunk.content, end="", flush=True)
```

------

## 常用文档加载器

```python
from langchain_community.document_loaders import (
    PyPDFLoader,        # PDF 文件
    WebBaseLoader,      # 网页内容
    CSVLoader,          # CSV 数据
    UnstructuredWordDocumentLoader,  # Word 文档
    YoutubeLoader,      # YouTube 字幕
)

# 加载 PDF
loader = PyPDFLoader("report.pdf")
pages = loader.load()

# 加载网页
loader = WebBaseLoader("https://example.com/article")
docs = loader.load()
```

------

## 最佳实践

### 1. 使用 LCEL 构建链

优先使用 `|` 管道语法，代码更清晰，支持流式输出和批处理：

```python
chain = prompt | llm | output_parser
```

### 2. 控制 Token 消耗

```python
# 限制上下文长度
splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=100
)
```

### 3. 使用缓存减少 API 调用

```python
from langchain_community.cache import SQLiteCache
from langchain_core.globals import set_llm_cache

set_llm_cache(SQLiteCache(database_path=".langchain.db"))
```

### 4. 异步支持

```python
response = await chain.ainvoke({"question": "..."})

async for chunk in chain.astream({"question": "..."}):
    print(chunk.content, end="")
```

------

## 生态与常用集成

| 类别       | 工具                                                 |
| ---------- | ---------------------------------------------------- |
| LLM 模型   | OpenAI、Anthropic Claude、Google Gemini、本地 Ollama |
| 向量数据库 | FAISS、Chroma、Pinecone、Weaviate、Milvus            |
| 文档加载   | PDF、Word、网页、Notion、Confluence                  |
| 工具/搜索  | Tavily、SerpAPI、Wikipedia、ArXiv                    |
| 监控追踪   | LangSmith（官方）、LangFuse                          |

------

## 项目结构推荐

```
my_langchain_app/
├── main.py                  # 应用入口
├── config.py                # 配置（API Key、模型参数）
├── chains/
│   ├── rag_chain.py         # RAG 链
│   └── chat_chain.py        # 对话链
├── agents/
│   └── assistant_agent.py   # Agent 定义
├── tools/
│   └── custom_tools.py      # 自定义工具
├── loaders/
│   └── document_loader.py   # 文档加载逻辑
└── vectorstore/
    └── store.py             # 向量库管理
```

------

## 总结

LangChain 极大降低了构建 LLM 应用的门槛：

- **Model I/O** 让你轻松切换不同模型
- **LCEL** 让链路组合变得优雅直观
- **Memory** 解决多轮对话状态管理
- **RAG** 让模型具备私有知识问答能力
- **Agents** 赋予模型自主决策和工具调用能力

无论是内部知识库问答、AI 客服、自动化工作流还是复杂的多步骤推理任务，LangChain 都是目前 Python 生态中最成熟的解决方案。

------

*参考资料：[LangChain 官方文档](https://python.langchain.com/docs/introduction/)*