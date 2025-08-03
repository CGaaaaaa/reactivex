/// ReactiveX for MoonBit - 使用示例
/// 展示基本的Observable创建和订阅功能

/// 基础使用示例
pub fn example_basic_usage() -> Unit {
  println("=== 基础使用示例 ===")
  
  // 1. 创建一个简单的Observable
  let simple_obs = of(42)
  let _ = simple_obs.subscribe_next(fn(value) {
    println("接收到值: {value}")
  })
  
  // 2. 创建数组Observable
  let array_obs = from_array([1, 2, 3])
  let _ = array_obs.subscribe_next(fn(value) {
    println("数组元素: {value}")
  })
  
  println("=== 示例完成 ===")
}

/// 操作符链示例
pub fn example_operator_chain() -> Unit {
  println("=== 操作符链示例 ===")
  
  // 简单的操作符链
  let processed = from_array([1, 2, 3, 4, 5])
    |> filter(fn(x) { x % 2 == 1 })  // 只保留奇数
    |> map(fn(x) { x * x })          // 平方
    |> take(3)                       // 取前3个
  
  let _ = processed.subscribe_next(fn(value) {
    println("处理后的值: {value}")
  })
  
  println("=== 示例完成 ===")
}