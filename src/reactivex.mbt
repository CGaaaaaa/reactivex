/// ReactiveX for MoonBit
///
/// A small reactive programming library implemented for MoonBit.

///|
/// RxError - error variants used across the library
///
/// Description:
///   Represents the possible error variants that Observables may emit.
///
/// Example:
///
/// ```moonbit
///   let e = RxError::RuntimeError("network")
///   match e {
///     RuntimeError(msg) => assert_eq(msg, "network")
///     _ => ()
///   }
/// ```
pub enum RxError {
  RuntimeError(String)
  OperatorError(String)
  SubscriptionError(String)
  TimeoutError(String)
}

///|
///   let obs = map(from_array([1,2]), fn(x) { x * 2 })
///   obs.subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [2,4])
/// Observer - core observer type
///
/// Description:
///   An Observer receives notifications from an Observable: next values,
///   errors and completion signals.
///
/// Fields:
///   - on_next: (T) -> Unit
///   - on_error: (RxError) -> Unit
///   - on_complete: () -> Unit
///
/// Example:
///
/// ```moonbit
///   let values = []
///   let o = new_observer(
///     fn(v){ values.push(v) },
///     fn(e){ values.push("err") },
///     fn(){}
///   )
///   (o.on_next)(42)
///   assert_eq(values, [42])
/// ```
pub struct Observer[T] {
  on_next : (T) -> Unit
  on_error : (RxError) -> Unit
  on_complete : () -> Unit
}

///|
/// BasicSubscription - subscription handle
///
/// Description:
///   Represents an active subscription returned when subscribing to an Observable.
///
/// Fields:
///   - subscribed: Bool (mutable) - whether the subscription is still active
///
/// Example:
///
/// ```moonbit
///   let s = new_subscription()
///   assert_eq(s.is_subscribed(), true)
///   // unsubscribe (consumes the subscription)
///   s.unsubscribe()
/// ```
pub struct BasicSubscription {
  mut subscribed : Bool
}

///|
/// Observable - core reactive type
///
/// Description:
///   Observable represents a stream of values which observers can subscribe to.
///
/// Fields:
///   - subscribe_fn: (Observer[T]) -> BasicSubscription
///
/// Example:
///
/// ```moonbit
///   let collected = []
///   of(1).subscribe_next(fn(v){ collected.push(v) })
///   assert_eq(collected, [1])
/// ```
pub struct Observable[T] {
  subscribe_fn : (Observer[T]) -> BasicSubscription
}

///|
/// Creates a new Observer with explicit callbacks.
///
/// Parameters:
///
/// * `on_next` : (T) -> Unit - called for each emitted value
/// * `on_error` : (RxError) -> Unit - called when an error occurs
/// * `on_complete` : () -> Unit - called when the stream completes
///
/// Returns:
///
/// A configured `Observer[T]` that can be passed to `subscribe`.
///
/// Example:
///
/// ```moonbit
///   // collect values to assert behavior in examples/tests
///   let values = []
///   let o = new_observer(
///     fn(v){ values.push(v) },
///     fn(e){ values.push("err") },
///     fn(){}
///   )
///   // simulate a next notification
///   (o.on_next)(1)
///   assert_eq(values, [1])
/// ```
pub fn[T] new_observer(
  on_next : (T) -> Unit,
  on_error : (RxError) -> Unit,
  on_complete : () -> Unit,
) -> Observer[T] {
  { on_next, on_error, on_complete }
}

///|
/// Creates a convenience Observer that accepts string errors.
///
/// Parameters:
///
/// * `on_next` : (T) -> Unit
/// * `on_error` : (String) -> Unit  (receives the error message)
/// * `on_complete` : () -> Unit
///
/// Returns:
///
/// An `Observer[T]` that converts internal `RxError` variants to `String`
/// and forwards them to the provided `on_error` callback.
///
/// Example:
///
/// ```moonbit
///   let values = []
///   let o = new_simple_observer(
///     fn(v){ values.push(v) },
///     fn(e){ values.push(e) },
///     fn(){}
///   )
///   (o.on_next)("hello")
///   assert_eq(values, ["hello"])    
/// ```
pub fn[T] new_simple_observer(
  on_next : (T) -> Unit,
  on_error : (String) -> Unit,
  on_complete : () -> Unit,
) -> Observer[T] {
  {
    on_next,
    on_error: fn(err) {
      match err {
        RuntimeError(msg)
        | OperatorError(msg)
        | SubscriptionError(msg)
        | TimeoutError(msg) => on_error(msg)
      }
    },
    on_complete,
  }
}

///|
/// Creates a new BasicSubscription in subscribed state.
///
/// Returns:
///
/// * `BasicSubscription` - with `subscribed` initialized to `true`.
///
/// Example:
///
/// ```moonbit
///   let s = new_subscription()
///   assert_eq(s.is_subscribed(), true)
/// ```
pub fn new_subscription() -> BasicSubscription {
  { subscribed: true }
}

///|
/// Checks whether the subscription is still active.
///
/// Parameters:
///
/// * `self` : BasicSubscription
///
/// Returns:
///
/// * `Bool` - `true` if subscribed, otherwise `false`.
pub fn is_subscribed(self : BasicSubscription) -> Bool {
  self.subscribed
}

///|
/// Cancels the subscription.
///
/// Parameters:
///
/// * `self` : BasicSubscription
///
/// Example:
///
/// ```moonbit
///   let s = new_subscription(); s.unsubscribe()
/// ```
pub fn unsubscribe(self : BasicSubscription) -> Unit {
  self.subscribed = false
}

///|
/// Construct an Observable from a subscribe function.
///
/// Parameters:
///
/// * `subscribe_fn` : (Observer[T]) -> BasicSubscription - function called when an observer subscribes
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   let o = new_observable(fn(obs){ (obs.on_next)(1); (obs.on_complete)(); new_subscription() })
///   o.subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1])
/// ```
pub fn[T] new_observable(
  subscribe_fn : (Observer[T]) -> BasicSubscription,
) -> Observable[T] {
  { subscribe_fn, }
}

///|
/// Subscribes an observer to the Observable.
///
/// Parameters:
///
/// * `self` : Observable[T]
/// * `observer` : Observer[T]
///
/// Returns:
///
/// * `BasicSubscription`
pub fn[T] subscribe(
  self : Observable[T],
  observer : Observer[T],
) -> BasicSubscription {
  (self.subscribe_fn)(observer)
}

///|
/// Convenience: subscribe with only an `on_next` handler.
///
/// Parameters:
///
/// * `self` : Observable[T]
/// * `on_next` : (T) -> Unit
///
/// Returns:
///
/// * `BasicSubscription`
///
/// Example:
///
/// ```moonbit
///   // of emits a single value
///   let emitted = []
///   of(1).subscribe_next(fn(v){ emitted.push(v) })
///   assert_eq(emitted, [1])
/// ```
pub fn[T] subscribe_next(
  self : Observable[T],
  on_next : (T) -> Unit,
) -> BasicSubscription {
  let observer = new_simple_observer(
    on_next,
    fn(error) { println("Error: " + error) },
    fn() { println("Completed") },
  )
  self.subscribe(observer)
}

// ===== Creation operators =====

///|
/// Creates an Observable that emits a single value then completes.
///
/// Parameters:
///
/// * `value` : T - the single value to emit
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   of(42).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [42])
/// ```
pub fn[T] of(value : T) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_next)(value)
      (observer.on_complete)()
    }
    subscription
  })
}

///|
/// Creates an Observable from an array of values.
///
/// Parameters:
///
/// * `values` : Array[T] - values to emit sequentially
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   from_array([1,2,3]).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2,3])
/// ```
pub fn[T] from_array(values : Array[T]) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    for i = 0; i < values.length() && subscription.is_subscribed(); i = i + 1 {
      (observer.on_next)(values[i])
    }
    if subscription.is_subscribed() {
      (observer.on_complete)()
    }
    subscription
  })
}

///|
/// Creates an Observable that immediately completes without emitting values.
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   empty().subscribe_next(fn(v){ values.push(v) })
///   // empty emits nothing
///   assert_eq(values, [])
/// ```
pub fn[T] empty() -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_complete)()
    }
    subscription
  })
}

///|
/// Creates an Observable that never emits and never completes.
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   never().subscribe_next(fn(v){ values.push(v) })
///   // never emits nothing (and never completes)
///   assert_eq(values, [])
/// ```
pub fn[T] never() -> Observable[T] {
  new_observable(fn(_observer) { new_subscription() })
}

///|
/// Creates an Observable that immediately emits an error.
///
/// Parameters:
///
/// * `error_message` : String - description of the error
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   error("test error").subscribe(new_observer(fn(_){}, fn(_){ values.push("err") }, fn(){}))
///   assert_eq(values, ["err"]) 
/// ```
pub fn[T] error(error_message : String) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_error)(RuntimeError(error_message))
    }
    subscription
  })
}

///|
/// Creates an Observable that immediately emits a specific `RxError` variant.
///
/// Parameters:
///
/// * `rx_error` : RxError
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   error_with_type(OperatorError("op failed")).subscribe(new_observer(fn(_){}, fn(_){ values.push("err") }, fn(){}))
///   assert_eq(values, ["err"]) 
/// ```
pub fn[T] error_with_type(rx_error : RxError) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_error)(rx_error)
    }
    subscription
  })
}

// ===== Transformation operators =====

///|
/// map - transform each emitted value using `transform`.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `transform` : (T) -> U
///
/// Returns:
///
/// * `Observable[U]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   let obs = map(from_array([1,2]), fn(x) { x * 2 })
///   obs.subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [2,4])
/// ```
pub fn[T, U] map(source : Observable[T], transform : (T) -> U) -> Observable[U] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) { (observer.on_next)(transform(value)) },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// filter - emit only values matching `predicate`.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `predicate` : (T) -> Bool
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   filter(from_array([1,2,3]), fn(x){ x % 2 == 1 }).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,3])
/// ```
pub fn[T] filter(
  source : Observable[T],
  predicate : (T) -> Bool,
) -> Observable[T] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) { if predicate(value) { (observer.on_next)(value) } },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// take - take the first `count` values then complete.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `count` : Int
///
/// Returns:
///
/// * `Observable[T]`
/// 
/// Example:
/// ```moonbit
///   let values = []
///   take(from_array([1,2,3]), 2).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2])
/// ```
pub fn[T] take(source : Observable[T], count : Int) -> Observable[T] {
  new_observable(fn(observer) {
    if count <= 0 {
      // 如果count <= 0，立即完成
      (observer.on_complete)()
      return new_subscription()
    }
    let mut taken = 0
    let original_observer = new_observer(
      fn(value) {
        if taken < count {
          (observer.on_next)(value)
          taken += 1
          if taken == count {
            (observer.on_complete)()
          }
        }
      },
      observer.on_error,
      fn() { if taken < count { (observer.on_complete)() } },
    )
    source.subscribe(original_observer)
  })
}

///|
/// skip - skip the first `count` values from the source.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `count` : Int
///
/// Returns:
///
/// * `Observable[T]`
/// 
/// Example:
/// ```moonbit
///   let values = []
///   skip(from_array([1,2,3]), 1).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [2,3])
/// ```
pub fn[T] skip(source : Observable[T], count : Int) -> Observable[T] {
  new_observable(fn(observer) {
    let mut skipped = 0
    let original_observer = new_observer(
      fn(value) {
        if skipped >= count {
          (observer.on_next)(value)
        } else {
          skipped += 1
        }
      },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// scan - accumulate values and emit each intermediate result.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `initial` : U
/// * `accumulator` : (U, T) -> U
///
/// Returns:
///
/// * `Observable[U]`
/// 
/// Example:
/// ```moonbit
///   let values = []
///   scan(from_array([1,2]), 0, fn(acc, x){ acc + x }).subscribe_next(fn(v){ values.push(v) })
///   // emits initial then intermediate: [0,1,3]
///   assert_eq(values, [0,1,3])
/// ```
pub fn[T, U] scan(
  source : Observable[T],
  initial : U,
  accumulator : (U, T) -> U,
) -> Observable[U] {
  new_observable(fn(observer) {
    let mut accumulated = initial
    (observer.on_next)(accumulated) // 发射初始值
    let original_observer = new_observer(
      fn(value) {
        accumulated = accumulator(accumulated, value)
        (observer.on_next)(accumulated)
      },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// reduce - accumulate values and emit the final result when source completes.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `initial` : U
/// * `accumulator` : (U, T) -> U
///
/// Returns:
///
/// * `Observable[U]`
///
/// Example:
/// ```moonbit
///   let results = []
///   reduce(from_array([1,2,3]), 0, fn(acc, x){ acc + x }).subscribe_next(fn(v){ results.push(v) })
///   // reduce emits final accumulated value on completion
///   assert_eq(results, [6])
/// ```
pub fn[T, U] reduce(
  source : Observable[T],
  initial : U,
  accumulator : (U, T) -> U,
) -> Observable[U] {
  new_observable(fn(observer) {
    let mut accumulated = initial
    let original_observer = new_observer(
      fn(value) { accumulated = accumulator(accumulated, value) },
      observer.on_error,
      fn() {
        (observer.on_next)(accumulated)
        (observer.on_complete)()
      },
    )
    source.subscribe(original_observer)
  })
}

// ===== Advanced operators =====

///|
/// merge - merge multiple Observables into a single Observable.
///
/// Parameters:
///
/// * `sources` : Array[Observable[T]] - array of Observables to merge
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   merge([from_array([1]), from_array([2])]).subscribe_next(fn(v){ values.push(v) })
///   // merged values may interleave; as a simple deterministic example with these sources:
///   assert_eq(values, [1,2])
/// ```
pub fn[T] merge(sources : Array[Observable[T]]) -> Observable[T] {
  new_observable(fn(observer) {
    let subscriptions : Array[BasicSubscription] = []
    let mut completed_count = 0
    for i = 0; i < sources.length(); i = i + 1 {
      let source = sources[i]
      let subscription = source.subscribe(new_observer(
        observer.on_next,
        observer.on_error,
        fn() {
          completed_count += 1
          if completed_count == sources.length() {
            (observer.on_complete)()
          }
        }),
      )
      subscriptions.push(subscription)
    }

    // 返回第一个订阅作为代表
    if sources.length() > 0 {
      subscriptions[0]
    } else {
      new_subscription()
    }
  })
}

///|
/// concat - concatenate multiple Observables sequentially.
///
/// Parameters:
///
/// * `sources` : Array[Observable[T]] - Observables to concatenate in order
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   concat([from_array([1]), from_array([2])]).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2])
/// ```
pub fn[T] concat(sources : Array[Observable[T]]) -> Observable[T] {
  new_observable(fn(observer) {
    let mut current_index = 0
    let mut current_subscription = new_subscription()
    fn subscribe_next() -> Unit {
      if current_index < sources.length() {
        let source = sources[current_index]
        current_subscription = source.subscribe(new_observer(
          observer.on_next,
          observer.on_error,
          fn() {
            current_index += 1
            subscribe_next()
          }),
        )
      } else {
        (observer.on_complete)()
      }
    }

    subscribe_next()
    current_subscription
  })
}

///|
/// tap - perform a side effect for each value without modifying the stream.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `side_effect` : (T) -> Unit
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   let side = []
///   tap(from_array([1,2]), fn(v){ side.push(v) }).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2])
///   assert_eq(side, [1,2])
/// ```
pub fn[T] tap(
  source : Observable[T],
  side_effect : (T) -> Unit,
) -> Observable[T] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) {
        side_effect(value)
        (observer.on_next)(value)
      },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// distinct - emit only the first occurrence of each distinct value.
///
/// Parameters:
///
/// * `source` : Observable[T]
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   distinct(from_array([1,1,2])).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2])
/// ```
pub fn[T : Eq] distinct(source : Observable[T]) -> Observable[T] {
  new_observable(fn(observer) {
    let seen_values : Array[T] = []
    let original_observer = new_observer(
      fn(value) {
        let mut already_seen = false
        for i = 0; i < seen_values.length(); i = i + 1 {
          if seen_values[i] == value {
            already_seen = true
            break
          }
        }
        if !already_seen {
          seen_values.push(value)
          (observer.on_next)(value)
        }
      },
      observer.on_error,
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

///|
/// catch_error - recover from errors by switching to a recovery Observable.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `error_handler` : (RxError) -> Observable[T] - produces a recovery Observable
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let results = []
///   catch_error(error("e"), fn(_){ from_array([9]) }).subscribe_next(fn(v){ results.push(v) })
///   assert_eq(results, [9])
/// ```
pub fn[T] catch_error(
  source : Observable[T],
  error_handler : (RxError) -> Observable[T],
) -> Observable[T] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      observer.on_next,
      fn(error) {
        let recovery_source = error_handler(error)
        let _ = recovery_source.subscribe(observer)

      },
      observer.on_complete,
    )
    source.subscribe(original_observer)
  })
}

// ===== Advanced transformation operators =====

///|
/// flat_map - map each outer value to an inner Observable and flatten the results.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `transform` : (T) -> Observable[U]
///
/// Returns:
///
/// * `Observable[U]`
///
/// Example:
///
/// ```moonbit
///   let results = []
///   let f = flat_map(from_array([1,2]), fn(x){ from_array([x, x*2]) })
///   f.subscribe_next(fn(v){ results.push(v) })
///   // flat_map flattens inner sequences; expected order: 1,2,2,4
///   assert_eq(results, [1,2,2,4])
/// ```
pub fn[T, U] flat_map(
  source : Observable[T],
  transform : (T) -> Observable[U],
) -> Observable[U] {
  new_observable(fn(observer) {
    let mut active_subscriptions = 0
    let mut source_completed = false
    fn check_completion() -> Unit {
      if source_completed && active_subscriptions == 0 {
        (observer.on_complete)()
      }
    }

    let original_observer = new_observer(
      fn(value) {
        active_subscriptions += 1
        let inner_observable = transform(value)
        let _ = inner_observable.subscribe(new_observer(
          observer.on_next,
          observer.on_error,
          fn() {
            active_subscriptions -= 1
            check_completion()
          }),
        )

      },
      observer.on_error,
      fn() {
        source_completed = true
        check_completion()
      },
    )
    source.subscribe(original_observer)
  })
}

///|
/// switch_map - switch to the latest inner Observable produced by the transform.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `transform` : (T) -> Observable[U]
///
/// Returns:
///
/// * `Observable[U]`
///
/// Example:
/// ```moonbit
///   let results = []
///   let f = switch_map(from_array([1,2]), fn(x){ from_array([x, x*2]) })
///   f.subscribe_next(fn(v){ results.push(v) })
///   // switch_map only emits values from the latest inner Observable
///   assert_eq(results, [1,2,2,4])
/// ```
pub fn[T, U] switch_map(
  source : Observable[T],
  transform : (T) -> Observable[U],
) -> Observable[U] {
  new_observable(fn(observer) {
    let mut current_subscription : BasicSubscription = new_subscription()
    let mut source_completed = false
    let mut inner_completed = false
    fn check_completion() -> Unit {
      if source_completed && inner_completed {
        (observer.on_complete)()
      }
    }

    let original_observer = new_observer(
      fn(value) {
        // 取消之前的内部订阅
        current_subscription.unsubscribe()
        inner_completed = false
        let inner_observable = transform(value)
        current_subscription = inner_observable.subscribe(
          new_observer(observer.on_next, observer.on_error, fn() {
            inner_completed = true
            check_completion()
          }),
        )
      },
      observer.on_error,
      fn() {
        source_completed = true
        check_completion()
      },
    )
    source.subscribe(original_observer)
  })
}

///|
/// combine_latest - combine latest values from two Observables using a combiner.
///
/// Parameters:
///
/// * `obs1` : Observable[T]
/// * `obs2` : Observable[U]
/// * `combiner` : (T, U) -> V
///
/// Returns:
///
/// * `Observable[V]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   combine_latest(from_array([1,2]), from_array([10,20]), fn(a,b){ a + b }).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [11,22])
/// ```
pub fn[T, U, V] combine_latest(
  obs1 : Observable[T],
  obs2 : Observable[U],
  combiner : (T, U) -> V,
) -> Observable[V] {
  new_observable(fn(observer) {
    let mut value1 : T? = None
    let mut value2 : U? = None
    let mut completed_count = 0
    fn try_emit() -> Unit {
      match (value1, value2) {
        (Some(v1), Some(v2)) => (observer.on_next)(combiner(v1, v2))
        _ => ()
      }
    }

    fn on_complete() -> Unit {
      completed_count += 1
      if completed_count == 2 {
        (observer.on_complete)()
      }
    }

    let sub1 = obs1.subscribe(
      new_observer(
        fn(v) {
          value1 = Some(v)
          try_emit()
        },
        observer.on_error,
        on_complete,
      ),
    )
    let _ = obs2.subscribe(
      new_observer(
        fn(v) {
          value2 = Some(v)
          try_emit()
        },
        observer.on_error,
        on_complete,
      ),
    )
    sub1 // 返回其中一个订阅作为代表
  })
}

///|
/// zip - pair values from two Observables in order and combine them.
///
/// Parameters:
///
/// * `obs1` : Observable[T]
/// * `obs2` : Observable[U]
/// * `combiner` : (T, U) -> V
///
/// Returns:
///
/// * `Observable[V]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   zip(from_array([1,2]), from_array([10,20]), fn(a,b){ a + b }).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [11,22])
/// ```
pub fn[T, U, V] zip(
  obs1 : Observable[T],
  obs2 : Observable[U],
  combiner : (T, U) -> V,
) -> Observable[V] {
  new_observable(fn(observer) {
    let queue1 : Array[T] = []
    let queue2 : Array[U] = []
    let mut completed1 = false
    let mut completed2 = false
    fn try_emit() -> Unit {
      while queue1.length() > 0 && queue2.length() > 0 {
        let v1 = queue1[0]
        let v2 = queue2[0]
        let _ = queue1.remove(0)
        let _ = queue2.remove(0)
        (observer.on_next)(combiner(v1, v2))
      }

      // 检查是否应该完成
      if (completed1 && queue1.length() == 0) ||
        (completed2 && queue2.length() == 0) {
        (observer.on_complete)()
      }
    }

    let sub1 = obs1.subscribe(
      new_observer(
        fn(v) {
          queue1.push(v)
          try_emit()
        },
        observer.on_error,
        fn() {
          completed1 = true
          try_emit()
        },
      ),
    )
    let _ = obs2.subscribe(
      new_observer(
        fn(v) {
          queue2.push(v)
          try_emit()
        },
        observer.on_error,
        fn() {
          completed2 = true
          try_emit()
        },
      ),
    )
    sub1
  })
}

///|
/// debounce - debounce values using a counter-based simplification (demo).
///
/// Note: This implementation uses a counter to simulate time for tests.
/// A real, time-based debounce should use timers.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `delay_count` : Int - emit every `delay_count` events
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   debounce(from_array([1,2,3]), 2).subscribe_next(fn(v){ values.push(v) })
///   // emits every 2nd event and final last value on complete: [2,3]
///   assert_eq(values, [2,3])
/// ```
pub fn[T] debounce(source : Observable[T], delay_count : Int) -> Observable[T] {
  new_observable(fn(observer) {
    let mut counter = 0
    let mut last_value : T? = None
    let original_observer = new_observer(
      fn(value) {
        counter += 1
        last_value = Some(value)

        // 简化的防抖逻辑（计数器模拟时间延迟）
        // 在实际实现中，这里应该使用定时器
        // 这里用计数器简化演示
        if counter % delay_count == 0 {
          match last_value {
            Some(v) => (observer.on_next)(v)
            None => ()
          }
        }
      },
      observer.on_error,
      fn() {
        // 发射最后一个值
        match last_value {
          Some(v) => {
            (observer.on_next)(v)
            (observer.on_complete)()
          }
          None => (observer.on_complete)()
        }
      },
    )
    source.subscribe(original_observer)
  })
}

///|
/// start_with - prepend `initial_value` before the source Observable emits.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `initial_value` : T
///
/// Returns:
///
/// * `Observable[T]`
///
/// Example:
///
/// ```moonbit
///   let values = []
///   start_with(from_array([2,3]), 1).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2,3])
/// ```
pub fn[T] start_with(
  source : Observable[T],
  initial_value : T,
) -> Observable[T] {
  new_observable(fn(observer) {
    // 先发射初始值
    (observer.on_next)(initial_value)

    // 然后订阅源Observable
    source.subscribe(observer)
  })
}

///|
/// retry - retry subscription on errors up to `max_retries` times.
///
/// Parameters:
///
/// * `source` : Observable[T]
/// * `max_retries` : Int
///
/// Returns:
///
/// * `Observable[T]`
/// 
/// Example:
/// ```moonbit
///   let values = []
///   retry(from_array([1,2,3]), 2).subscribe_next(fn(v){ values.push(v) })
///   assert_eq(values, [1,2,3])
/// ```
pub fn[T] retry(source : Observable[T], max_retries : Int) -> Observable[T] {
  new_observable(fn(observer) {
    let mut retry_count = 0
    fn attempt_subscribe() -> BasicSubscription {
      source.subscribe(new_observer(
        observer.on_next,
        fn(error) {
          if retry_count < max_retries {
            retry_count += 1
            let _ = attempt_subscribe()
          } else {
            (observer.on_error)(error)
          }
        },
        observer.on_complete
      ))
    }

    attempt_subscribe()
  })
}
