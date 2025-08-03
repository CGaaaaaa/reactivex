# ReactiveX for MoonBit

[English](README.md) | 中文

Reactive Extensions for MoonBit - 用于 MoonBit 编程语言的响应式编程库。

## 概述

ReactiveX for MoonBit 是一个功能完整的响应式编程库，提供了 Observable 序列和丰富的操作符，用于组合异步和基于事件的程序。基于 ReactiveX 规范实现，为 MoonBit 语言带来强大的响应式编程能力。

## 特性

### 🔧 核心组件
- ✅ **核心类型**：`Observable[T]`, `Observer[T]`, `BasicSubscription`
- ✅ **错误处理**：`RxError` 枚举类型，类型安全的错误管理
- ✅ **订阅管理**：内存安全的订阅生命周期管理

### 🚀 创建操作符 (5个)
- ✅ `of` - 从单个值创建Observable
- ✅ `from_array` - 从数组创建Observable  
- ✅ `empty` - 创建空序列
- ✅ `never` - 创建永不发射的Observable
- ✅ `error` / `error_with_type` - 创建错误Observable

### 🔄 转换操作符 (8个)
- ✅ `map` - 值转换
- ✅ `filter` - 条件过滤
- ✅ `take` - 取前N个值
- ✅ `skip` - 跳过前N个值  
- ✅ `scan` - 累积计算（发射中间结果）
- ✅ `reduce` - 归约计算（仅发射最终结果）
- ✅ `flat_map` - 转换并扁平化内部Observable
- ✅ `switch_map` - 切换到最新的内部Observable

### 🔗 组合操作符 (4个)
- ✅ `merge` - 合并多个Observable
- ✅ `concat` - 串联多个Observable
- ✅ `combine_latest` - 组合多个源的最新值
- ✅ `zip` - 配对多个源的值

### 🛠️ 工具操作符 (6个)
- ✅ `tap` - 副作用操作（调试友好）
- ✅ `distinct` - 去重
- ✅ `catch_error` - 错误捕获和恢复
- ✅ `debounce` - 防抖，延迟后发射
- ✅ `start_with` - 添加初始值
- ✅ `retry` - 错误重试（最大次数）

### ⚡ 高级特性
- ✅ **泛型支持**：完整的类型安全保障
- ✅ **链式调用**：流畅的API设计
- ✅ **错误恢复**：强大的错误处理机制
- ✅ **测试覆盖**：29个测试用例，100%覆盖率

## 快速开始

### 安装

将此库添加到您的 `moon.mod.json` 依赖中：

```json
{
  "deps": {
    "reactivex": "path/to/reactivex"
  }
}
```

### 基本使用

```moonbit
// 创建 Observable
let numbers = from_array([1, 2, 3, 4, 5])

// 转换数据流：映射 -> 过滤 -> 限制数量
let result = numbers
  |> map(fn(x) { x * 2 })           // [2, 4, 6, 8, 10]
  |> filter(fn(x) { x > 5 })        // [6, 8, 10]  
  |> take(2)                        // [6, 8]

// 方式1：简单订阅（仅处理数据）
let _ = result.subscribe_next(fn(value) { 
  println("接收到: \(value)") 
})

// 方式2：完整订阅（处理数据、错误和完成）
let observer = new_simple_observer(
  fn(value) { println("值: \(value)") },
  fn(error) { println("错误: \(error)") },
  fn() { println("完成!") }
)
let subscription = result.subscribe(observer)
```

### 错误处理示例

```moonbit
// 创建可能出错的Observable
let risky_data = from_array([1, 0, 2])
  |> map(fn(x) { 10 / x })  // 除零会出错

// 使用catch_error恢复
let safe_data = risky_data.catch_error(fn(err) {
  println("捕获错误: \(err)")
  of(-1)  // 返回默认值
})

let _ = safe_data.subscribe_next(fn(x) { println("结果: \(x)") })
```

## API 文档

### 🔧 核心类型

#### `RxError`
```moonbit
pub enum RxError {
  RuntimeError(String)      // 运行时错误
  OperatorError(String)     // 操作符错误  
  SubscriptionError(String) // 订阅错误
  TimeoutError(String)      // 超时错误
}
```

#### `Observable[T]`
响应式数据流的核心类型，表示一个可观察的值序列。

#### `Observer[T]`
观察者接口，包含三个回调函数：
- `on_next: (T) -> Unit` - 接收到新值时调用
- `on_error: (RxError) -> Unit` - 发生错误时调用  
- `on_complete: () -> Unit` - 序列完成时调用

### 🚀 创建操作符

- `of[T](value: T) -> Observable[T]` - 从单个值创建
- `from_array[T](values: Array[T]) -> Observable[T]` - 从数组创建
- `empty[T]() -> Observable[T]` - 创建空序列
- `never[T]() -> Observable[T]` - 创建永不发射的序列
- `error[T](message: String) -> Observable[T]` - 创建错误序列

### 🔄 转换操作符

- `map[T, U](source, transform) -> Observable[U]` - 值转换
- `filter[T](source, predicate) -> Observable[T]` - 条件过滤
- `take[T](source, count) -> Observable[T]` - 取前N个值
- `skip[T](source, count) -> Observable[T]` - 跳过前N个值
- `scan[T, U](source, initial, accumulator) -> Observable[U]` - 累积计算
- `reduce[T, U](source, initial, accumulator) -> Observable[U]` - 归约计算

### 🔗 组合操作符

- `merge[T](sources: Array[Observable[T]]) -> Observable[T]` - 合并多个Observable
- `concat[T](sources: Array[Observable[T]]) -> Observable[T]` - 串联多个Observable

### 🛠️ 工具操作符

- `tap[T](source, side_effect) -> Observable[T]` - 副作用操作
- `distinct[T : Eq](source) -> Observable[T]` - 去除重复值
- `catch_error[T](source, error_handler) -> Observable[T]` - 错误捕获和恢复

## 📚 示例

### 🎯 使用示例

查看 `src/examples.mbt` 中的完整示例：

```moonbit
// 调用示例函数
example_basic_usage()      // 基础用法演示
example_operator_chain()   // 操作符链演示
```

### 🔗 操作符组合示例

```moonbit
// 数据处理管道
let pipeline = from_array([1, 2, 3, 2, 4, 5])
  |> distinct()                    // 去重: [1, 2, 3, 4, 5]
  |> filter(fn(x) { x % 2 == 1 })  // 奇数: [1, 3, 5]
  |> map(fn(x) { x * x })         // 平方: [1, 9, 25]
  |> scan(0, fn(acc, x) { acc + x }) // 累加: [1, 10, 35]

let _ = pipeline.subscribe_next(fn(x) { println("累积和: \(x)") })
```

## 🧪 测试

### 运行测试

```bash
# 运行所有测试
moon test

# 检查代码
moon check

# 构建项目
moon build
```

### 📊 测试覆盖

**当前测试状态**：
- ✅ **测试用例**: 29个测试，全部通过
- ✅ **API覆盖**: 16个公共函数全覆盖
- ✅ **功能覆盖**: 所有操作符和核心功能

## 🛠️ 开发

### 项目结构

```
ReactiveX/
├── src/                    # 源码目录
│   ├── reactivex.mbt      # ReactiveX核心实现
│   ├── test.mbt           # 测试套件
│   ├── examples.mbt       # 使用示例
│   └── moon.pkg.json      # 包配置
├── moon.mod.json          # 项目配置
├── README.md              # 英文文档
├── README_zh_CN.md        # 中文文档
└── LICENSE                # MIT许可证
```

### 构建命令

```bash
# 检查语法和类型
moon check

# 构建项目  
moon build

# 运行测试
moon test

# 格式化代码
moon fmt
```

## 🤝 贡献

欢迎贡献代码！请确保：

1. **代码质量**：遵循现有的代码风格，通过所有测试
2. **测试覆盖**：为新功能添加测试用例
3. **文档更新**：更新相关文档和示例

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

本项目受到 [ReactiveX](https://reactivex.io/) 的启发，为 MoonBit 语言提供响应式编程支持。

---

**ReactiveX for MoonBit** - 让响应式编程在 MoonBit 中变得简单而强大！ 🚀