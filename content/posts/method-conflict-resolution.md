---
date: '2025-02-23T18:15:04+09:00'
draft: false
title: 'Rubyの継承チェーンでメソッド名が競合したときの対処法'
tags:
  - Ruby
  - プログラミング
categories:
  - プログラミング
cover:
---

Rubyでモジュールを使っていると、メソッド名が競合することがあります。今回は実際にそういう状況を作ってみて、どうやって解決できるのか試してみました。

## まずは競合を起こしてみる

まず、同じメソッド名を持つ2つのモジュールを用意してみましょう：

```ruby
module Logging
  def log
    puts "Logging: #{Time.now}"
  end
end

module Debugging
  def log
    puts "Debug info: #{caller}"
  end
end
```
\*[Kernel#caller](https://docs.ruby-lang.org/ja/latest/method/Kernel/m/caller.html)

これらを両方includeしてみます。

```ruby
class MyApp
  include Logging
  include Debugging
end

app = MyApp.new
app.log
# 出力: "Debug info: [...]"
```

`Debugging`モジュールの`log`メソッドが呼ばれました。これはなぜかというと、Rubyのメソッド探索の順序に関係があります。試しに`ancestors`メソッドで確認してみましょう：

```ruby
MyApp.ancestors
# => [MyApp, Debugging, Logging, Object, Kernel, BasicObject]
```

後からincludeしたモジュールが先に探索されるようになっています。これを踏まえて、任意の処理を適切に呼び出すための方針は3つあります。
- 継承チェーンの順序を変える（include, prepend）
- 親クラスの処理を継承する（super）
- メソッド名を変更する
- メソッドにエイリアスをつける（alias_method）
- それぞれ別のメソッドとして定義し直す（define_method）

## 方法1: includeの順序を変える

```ruby
class MyApp
  include Debugging
  include Logging
end

app = MyApp.new
app.log
# 出力: "Logging: 2025-02-23 18:32:00 +0900"
```

今度は`Logging`モジュールの`log`メソッドが呼ばれました。
シンプルですが、より複雑なケースに対応できません。競合するメソッドが複数あり、それぞれ呼び出したいメソッドを持つモジュールの優先順位が異なる場合、解決できません。

```ruby
module M1
  def method1; end
  def method2; end
end

module M2
  def method1; end
  def method2; end
end

class C
  include M1
  include M2
end
```

上記の場合に、M1#method1とM2#method2をメソッド探索時にヒットさせたい場合、includeの順序変更だけでは解決できません。

## 方法2: prependを使ってみる

次は`prepend`を試してみます。。これを使うと、モジュールを継承チェーン上で自クラスの前に配置できます。

```ruby
class MyApp
  include Logging
  prepend Debugging

  def process
    log
  end
end

# 試しにancesstorsで確認してみると...
MyApp.ancestors
# => [Debugging, MyApp, Logging, Object, Kernel, BasicObject]

app = MyApp.new
app.log
# 出力: "Debug info: [...]"
```

`Debugging`モジュールがMyAppよりも前に配置されているのが確認できます。
ただし、方法1と同じ問題は残ります。

### includeではなく、prependを使いたいケース
上記で示した例では、そもそもincludeの順番を変えるだけで済む話なので、prependの旨みがありません。
prependが活きるのは、モジュールを既存メソッドのラッパーとして使用するときです。
例えば...
```ruby
module Logging
  def execute
    puts "Start logging..."
    super # 元の execute メソッドを呼ぶ
    puts "End logging..."
  end
end

class Task
  def execute
    puts "Executing task"
  end
end

Task.prepend(Logging)
Task.new.execute

# 出力:
# Start logging...
# Executing task
# End logging...
```

## 方法3: superで親のメソッドも呼んでみる

競合する各メソッドの処理を、どちらも適用したい場合は、superを使います。

```ruby
module EnhancedLogging
  def log
    puts "Enhanced logging start"
    super  # Logging#logが呼び出される
    puts "Enhanced logging end"
  end
end

class MyApp
  include Logging
  include EnhancedLogging

  def process
    log
  end
end

app = MyApp.new
app.log
# 出力:
# Enhanced logging start
# Logging: 2025-02-23 18:32:00 +0900
# Enhanced logging end
```

両方のメソッドの機能を組み合わせることができます。

## 方法4: alias_methodで別名を付けてみる

両方のメソッドを使い分けられるようにできます。
意図せずメソッド名が競合した場合のほとんどは、この方法で解決するのがスマートだと思います。

```ruby
class MyApp
  include Logging
  alias_method :logging_log, :log # Debuggingをincludeする前なので、Logging#logが参照される

  include Debugging
  alias_method :debugging_log, :log
end

app = MyApp.new
app.logging_log
# 出力: "Logging: 2025-02-23 18:32:00 +0900"

app.debugging_log
# 出力: "Debug info: [...]"

app.log
# 出力: "Debug info: [...]"
```

## 方法5: define_methodで定義し直す
```ruby
class MyApp
  # include Logging
  # include Debugging

  # Logging の log メソッドを別名 logging_log にする
  define_method(:logging_log, Logging.instance_method(:log))

  # Debugging の log メソッドを別名 debugging_log にする
  define_method(:debugging_log, Debugging.instance_method(:log))
end
```

この方法で定義する場合は、もはやincludeする必要すらないですね。
`private_instance_method`を使えばプライベートメソッドでも行けそう
この場合、メソッドの定義場所がLoggingやDebuggingではなく、MyApp内になるので、その点は注意しとく必要がありそう。
他に何か問題がないか...不安

## 試してみた感想

いろいろな方法を試してみましたが、それぞれ使い所が違います

- `include`の順序変更は手軽だけど、柔軟性はない
- `prepend`はモジュールをラッパーとして使いたい時
- `super`は機能を拡張したいとき
- `alias_method`は使い分けたいとき
- `define_method`は可能性無限大

個人的には`alias_method`が一番お気に入りです。メソッド名で意図が明確になるので、コードを読む人にとってもストレスが少ないと思います。
rubyは自由度が高いおかげで、他にもまだまだ解決方法あるかと思いますが、一旦思いついたものだけまとめてみました。
新しい発見があれば追記します。
