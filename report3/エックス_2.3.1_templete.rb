#!/usr/bin/ruby

# SIMPLEの構築

# 課題: SIMPLE言語の抽象構文木における簡約関係を定義した、推論規則（inference rule）の集合をRubyで書いて下さい
# （ここでは、Rubyがメタ言語をしての役割を果たします）。

# p.22 2.3.1.1 式の実装 new
class Number < Struct.new(:value)
end
class Add < Struct.new(:left, :right)
end
class Multiply < Struct.new(:left, :right)
end

## p.22 テストコード1-1
puts Add.new(
  Multiply.new(Number.new(1), Number.new(2)),
  Multiply.new(Number.new(3), Number.new(4))
).inspect

## p.23 #inspectのオーバーライド new

class Number 
     def to_s
        value.to_s
     end

     def inspect
        "<<#{self}>>"
     end
end

class Add 
      def to_s
          "(#{left} + #{right})"
      end
  
      def inspect
          "<<#{self}>>"
      end
  end
  
  class Multiply 
      def to_s
          "(#{left} * #{right})"
      end
  
      def inspect
          "<<#{self}>>"
      end
  end
  
  ## p.23 テストコード1-1
  puts Add.new(
    Multiply.new(Number.new(1), Number.new(2)),
    Multiply.new(Number.new(3), Number.new(4))
  ).inspect

## pp.23-24 テストコード1-2
puts Add.new(
  Multiply.new(Number.new(1), Number.new(2)),
  Multiply.new(Number.new(3), Number.new(4))
).inspect

puts Number.new(5).inspect

## p.25 #reducible? メソッドの実装 new
class Number 
  def reducible?
    false 
  end
end

class Add 
  def reducible?
    true
  end
end
class Multiply 
  def reducible?
     true
  end
end


## p.25 テストコード1-3
puts Number.new(1).reducible?.inspect
puts Add.new(Number.new(1), Number.new(2)).reducible?.inspect

## p.26 #reduce メソッドの実装
class Add
  def reduce
    if left.reducible?
      Add.new(left.reduce, right)
    elsif right.reducible?
      Add.new(left, right.reduce)
    else
      Number.new(left.value + right.value)
    end
  end
end

class Multiply
  def reduce
    if left.reducible?
      Multiply.new(left.reduce, right)
    elsif right.reducible?
      Multiply.new(left, right.reduce)
    else
      Number.new(left.value * right.value)
    end
  end
end


## p.27 テストコード1-4
expression = Add.new(
  Multiply.new(Number.new(1), Number.new(2)),
  Multiply.new(Number.new(3), Number.new(4))
)

puts expression.inspect
puts expression.reducible?.inspect
expression = expression.reduce
puts expression.reducible?.inspect
expression = expression.reduce
puts expression.reducible?.inspect
expression = expression.reduce
puts expression.reducible?.inspect

## p.27 仮想機械の実装 new
class Machine < Struct.new(:expression)
  def step
    self.expression = expression.reduce
  end

  def run
    while expression.reducible?
      puts expression
      step
    end
    puts expression
  end
end


## p.28 テストコード1-5
Machine.new(
  Add.new(
    Multiply.new(Number.new(1), Number.new(2)),
    Multiply.new(Number.new(3), Number.new(4))
  )
).run

## p.28 ブール値および小なり演算子（<）の実装 new
class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    false
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce
    if left.reducible?
      LessThan.new(left.reduce, right)
    elsif right.reducible?
      LessThan.new(left, right.reduce)
    else
      Boolean.new(left.value < right.value)
    end
  end
end
## p.29 テストコード1-6
Machine.new(
  LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))
).run

## p.29 変数の実装1
class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end
end


## p.30 変数の実装2
class Variable
  def reduce(environment)
     environment[name]
  end
end


## p.30 各クラスの#reduceメソッドを引数environmentに対応するように変更
class Add
  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)
    elsif right.reducible?
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end
end

  class Multiply
     def reduce(environment)
       if left.reducible?
         Multiply.new(left.reduce(environment), right)
      elsif right.reducible?
        Multiply.new(left, right.reduce(environment))
      else
        Number.new(left.value * right.value)
      end
  end
end

 class LessThan
    def reduce (environment)
       if left.reducible?
         LessThan.new(left.reduce(environment), right)
       elsif right.reducible?
         LessThan.new(left, right.reduce(environment))
       else
         Boolean.new(left.value < right.value)
       end
    end
  end


## p.31 仮想機械の再定義1
Object.send(:remove_const, :Machine) #古いMachine クラスのことを忘れるため

class Machine < Struct.new(:expression, :environment)
  def step
    self.expression = expression.reduce(environment)
  end

  def run
    while expression.reducible?
      puts expression
      step
    end

    puts expression
  end
end

## p.31 テストコード1-7
Machine.new(
  Add.new(Variable.new(:x), Variable.new(:y)),
  { x:Number.new(3), y: Number.new(4) }
).run

# p.31 2.3.1.2 文

## pp.31-32 「何もしない」文の実装
class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    "<<#{self}>>"
  end

  def == (other_statement)
    other_statement.instance_of?(DoNothing)
  end

  def reducible?
    false
  end
end

## p.33 代入文の実装
class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true  
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge({ name => expression })]
    end
  end
end


## p.34 テストコード2-1
statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
puts statement.inspect

environment = { x: Number.new(2) }
puts environment.inspect

puts statement.reducible?

statement, environment = statement.reduce(environment)

puts "[" + statement.inspect + "," + environment.inspect + "]"

statement, environment = statement.reduce(environment)

puts "[" + statement.inspect + "," + environment.inspect + "]"

statement, environment = statement.reduce(environment)

puts "[" + statement.inspect + "," + environment.inspect + "]"

puts statement.reducible?

## p.34 仮想機械の再定義2（文を使えるように）
Object.send(:remove_const, :Machine)

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end

    puts "#{statement}, #{environment}"
  end
end


## pp.34-35 テストコード2-2
Machine.new(
  Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
  { x: Number.new(2) }
).run

## pp.35-36 条件式（Ifクラス）の実装
class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if #{condition} then #{consequence} else #{alternative}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
     end
   end
  end
end

## p.36 テストコード2-3

### 条件式が真の場合
Machine.new(
  If.new(
    Variable.new(:x),
    Assign.new(:y, Number.new(1)),
    Assign.new(:y, Number.new(2))
  ),
  { x: Boolean.new(true) }
).run

### 条件式が偽の場合
Machine.new(
  If.new(
    Variable.new(:x),
    Assign.new(:y, Number.new(1)),
    DoNothing.new
  ),
  { x: Boolean.new(false) }
).run

## p.37 シーケンス文（2つ以上の分をつなげて1つの文にする仕組み）の実装
class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
       reduced_first, reduced_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), reduced_environment]
    end
  end
end



## p.37 テストコード2-4
Machine.new(
  Sequence.new(
    Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
    Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
  ),
  {}
).run

## p.38 ループ構造（Whileクラス）の実装
class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
  end
end

## pp.38-39 テストコード2-5
Machine.new(
  While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
  ),
  { x: Number.new(1) }
).run
