---
title: langChain 链式调用
date: 2021-01-31 11:31:50
tags: AI
---


<font style="color:rgb(25, 27, 31);">链式调用位于LangChain三层核心架构中的中间层——工作流API抽象层。链就是负责将这些组件按照某一种逻辑，顺序组合成一个流水线的方式。比如我们要构建一个简单的问答链，就需要把大模型组件和标准输出组件用链串联起来。</font>
<!-- more -->
<!-- 这是一张图片，ocr 内容为： -->
![](/images/langchain1.png)

<font style="color:rgb(25, 27, 31);">以下代码是一个示例，其中</font>`<font style="color:rgb(25, 27, 31);">model</font>`<font style="color:rgb(25, 27, 31);">和</font>`<font style="color:rgb(25, 27, 31);">StrOutputParser</font>`<font style="color:rgb(25, 27, 31);">组成了一个链，</font>`<font style="color:rgb(25, 27, 31);">StrOutputParser</font>`<font style="color:rgb(25, 27, 31);">负责将大模型的输出转化为字符串。</font>

```plain
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import ChatOpenAI

if __name__ == '__main__':
    model = ChatOpenAI(api_key="xx", base_url="https://api.deepseek.com/v1", model="deepseek-chat")

    # 搭建链条，把model和字符串输出解析器组件连接在一起
    basic_qa_chain = model | StrOutputParser()

    # 查看输出结果
    question = "周杰伦的青花瓷第一句歌词是什么"
    result = basic_qa_chain.invoke(question)
    print(result)
```

加入提示词模板创建链

```plain
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

if __name__ == '__main__':
    model = ChatOpenAI(api_key="xx", base_url="https://api.deepseek.com/v1", model="deepseek-chat")

    # 搭建链条，把model和字符串输出解析器组件连接在一起
    basic_qa_chain = model | StrOutputParser()

    # 查看输出结果
    question = "周杰伦的青花瓷第一句歌词是什么"
    result = basic_qa_chain.invoke(question)
    print(result)

    prompt_template = ChatPromptTemplate([
        ("system", "你是一位人工智能助手，你的名字是{name}"),
        ("user", "这是用户的问题： {question}")
    ])

    # 直接使用模型 + 输出解析器
    bool_qa_chain = prompt_template | model | StrOutputParser()
    # 测试
    question = "你叫什么名字"
    result = bool_qa_chain.invoke({'question':question,"name":"机器人"})
    print(result)
```

<font style="color:rgb(25, 27, 31);">复合链</font>

```plain
from langchain.chat_models import init_chat_model
from langchain_core.prompts import PromptTemplate
from langchain.output_parsers import ResponseSchema, StructuredOutputParser
from langchain_core.runnables import RunnableLambda
from langchain_openai import ChatOpenAI
def debug_print(x):
    print('中间结果：', x)
    return x

if __name__ == '__main__':
    # 第一步：根据标题生成新闻正文
    cook_prompt = PromptTemplate.from_template(
        "请根据菜品名给出做菜的步骤：\n\n菜品名：{title}"
    )
    model = ChatOpenAI(api_key="sk-e3cb8a78bd54403eb488390565ece237", base_url="https://api.deepseek.com/v1",
                       model="deepseek-chat")
    # 第一个子链：做菜步骤
    cook_chain = cook_prompt | model

    # 第二步：从正文中提取结构化字段
    schemas = [
        ResponseSchema(name="material", description="食材"),
        ResponseSchema(name="flavoring", description="调味料"),
    ]
    parser = StructuredOutputParser.from_response_schemas(schemas)

    summary_prompt = PromptTemplate.from_template(
        "请从下面这段内容中提取关键信息，并返回结构化JSON格式：\n\n{msg}\n\n{format_instructions}"
    )
    print(parser.get_format_instructions())
    # 输出中间结果
    debug_node = RunnableLambda(debug_print)
    # 第二个子链：生成新闻摘要
    summary_chain = (
            summary_prompt.partial(format_instructions=parser.get_format_instructions())
            | model
            | parser
    )

    # 组合成一个复合 Chain
    full_chain = cook_chain | debug_node | summary_chain

    # 调用复合链
    result = full_chain.invoke({"title": "蛋炒饭"})
    print(result)

```

