---
layout: post
permalink: /blogs/agent/rag/index.html
title: RAG
---

# Langchain RAG

RAG（Retrieval-Augmented Generation，检索增强生成）是一种结合"信息检索"和"文本生成"的技术架构，主要用于提升大语言模型回答问题的准确性和时效性。

它的基本工作流程是这样的：

1. **检索（Retrieval）**：当用户提出问题后，系统先从外部知识库（比如文档库、数据库、网页等）中检索出与问题相关的内容片段。
2. **增强（Augmented）**：将检索到的相关内容作为额外上下文，拼接到原始问题中，一起输入给语言模型。
3. **生成（Generation）**：语言模型基于问题本身加上检索到的参考资料，生成最终的回答。

RAG 主要解决了大语言模型的几个痛点：模型的知识来自训练数据，存在时效性限制，无法获取最新信息;模型可能产生"幻觉"，编造不存在的事实;模型无法直接访问企业内部的私有数据或专业领域的特定文档。

通过 RAG，可以让模型在回答时"有据可依"，引用真实存在的资料，从而减少幻觉、提高准确性，同时也能让模型回答关于私有数据或最新事件的问题，而不需要重新训练整个模型。

典型应用场景包括：企业知识库问答助手、客服系统、法律/医疗等专业领域咨询工具，以及需要引用最新资讯的应用。


## 文档载入

| Loader                     | 来源          | 安装包                               |
| :------------------------- | :------------ | :----------------------------------- |
| TextLoader                 | .txt 文件     | langchain（内置）                    |
| PyPDFLoader                | PDF 文件      | langchain-community + pypdf          |
| WebBaseLoader              | 网页 URL      | langchain-community + beautifulsoup4 |
| CSVLoader                  | CSV 文件      | langchain-community                  |
| UnstructuredMarkdownLoader | Markdown 文件 | langchain-community + unstructured   |

### CSVLoader

```python
from langchain_community.document_loaders import CSVLoader

loader = CSVLoader(
    file_path="./data/stu.csv",
    csv_args={
        "delimiter": ",",       # 指定分隔符
        "quotechar": '"',       # 指定带有分隔符文本的引号包围是单引号还是双引号
        # 如果数据原本有表头，就不要下面的代码，如果没有可以使用
        # "fieldnames": ['name', 'age', 'gender', '爱好']
    },
    encoding="utf-8"            # 指定编码为UTF-8
)

# 批量加载 .load()   ->  [Document, Document, ...]
# documents = loader.load()
#
# for document in documents:
#     print(type(document), document)

# 懒加载  .lazy_load()  迭代器[Document]
for document in loader.lazy_load():
    print(document)
    print("********************************")

```

输出：

> page_content='name: 王梓涵
> age: 25
> gender: 男
> hobby: 吃饭,rap' metadata={'source': './data/stu.csv', 'row': 0}
>
> ********************************
> page_content='name: 刘若曦
> age: 22
> gender: 女
> hobby: 睡觉,rap' metadata={'source': './data/stu.csv', 'row': 1}

### JSONLoader

```python
from langchain_community.document_loaders import JSONLoader

loader = JSONLoader(
    file_path="./data/stu_json_lines.json",
    jq_schema=".name",      # 从 JSON 中提取想加载的字段
    text_content=False,     # 告知JSONLoader 我抽取的内容不是字符串
    json_lines=True         # 告知JSONLoader 这是一个JSONLines文件（每一行都是一个独立的标准JSON）
)

document = loader.load()
print(document)
```

输出：

> [Document(metadata={'source': 'D:\\File\\LangChain_learning\\data\\stu_json_lines.json', 'seq_num': 1}, page_content='周杰轮'), .......]

| 常见写法         | JSON                                             | jq_schema                          | 结果                       |
| ---------------- | ------------------------------------------------ | ---------------------------------- | -------------------------- |
| 单个字段         | `{"name":"张三","age":18}`                       | jq_schema=".name"                  | "张三"                     |
| 取嵌套字段       | `{"student":{"name":"张三","age":18}}`           | jq_schema=".student.age"           | "18"                       |
| 数组中的所有元素 | `{"students":[{"name":"张三"},{"name":"李四"}]}` | jq_schema=".students[].name"       | 张三<br/>李四              |
| 整个对象         | `{"name":"张三","age":18}`                       | jq_schema="."                      | { "name":"张三", "age":18} |
| 多字段拼接       | `{"name":"张三","age":18}`                       | jq_schema="{name:.name, age:.age}" | { "name":"张三", "age":18} |

### PyPDFLoader

```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader(
    file_path="./data/pdf2.pdf",
    mode="single",        # 默认是page模式，每个页面形成一个Document文档对象，
                          # single模式，不管有多少页，只返回1个Document对象
    password="pwd"
)

i = 0
for doc in loader.lazy_load():
    i += 1
    print(doc)
    print("="*20, i)
```





## 文档切分





## Embeddings





## 向量化存储



