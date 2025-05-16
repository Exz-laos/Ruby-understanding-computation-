#!/usr/bin/ruby

# SIMPLEをRubyに変換するための表示的意味論の実装

# 準備

class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end
end

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "«#{self}»"
  end
end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "«#{self}»"
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect
    "«#{self}»"
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    "«#{self}»"
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "«#{self}»"
  end
end

class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    "«#{self}»"
  end
end


# p.48 NumberおよびBooleanの実装
class Number 
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Boolean
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end


# p.48 テストコード
puts(Number.new(5).to_ruby.inspect)
puts(Boolean.new(false).to_ruby.inspect)

# p.49 テストコード
proc = eval(Number.new(5).to_ruby)
puts(proc.inspect)
puts(proc.call({}).inspect)

proc = eval(Boolean.new(false).to_ruby)
puts(proc.inspect)
puts(proc.call({}).inspect)

# p.49 Variableの実装
class Variable 
  def to_ruby
    "-> e { e[#{name.inspect}]}"
  end
end


# pp.49-50 テストコード
expression = Variable.new(:x)
puts(expression.inspect)
puts(expression.to_ruby.inspect)

proc = eval(expression.to_ruby)
puts(proc.inspect)
puts(proc.call({ x: 7 }).inspect)

# p.50 Add、Multiply、LessThanの実装
class Add
  def to_ruby
    "-> e{ (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end
end

class Multiply
  def to_ruby
    "-> e{ (#{left.to_ruby}).call(e)*(#{right.to_ruby}).call(e) }"
  end
end

class LessThan
  def to_ruby
    "-> e{ (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end
end

# p.50 テストコード1
puts(Add.new(Variable.new(:x), Number.new(1)).to_ruby.inspect)
puts(LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby.inspect)

# p.50 テストコード2
environment = { x: 3 }
puts(environment.inspect)

proc = eval(Add.new(Variable.new(:x), Number.new(1)).to_ruby)
puts(proc.inspect)
puts(proc.call(environment).inspect)

proc = eval(LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby)
puts(proc.inspect)
puts(proc.call(environment).inspect)

# p.51 Assignの実装
class Assign
  def to_ruby
    "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
  end
end

# p.51 テストコード
statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
puts(statement.inspect)
puts(statement.to_ruby.inspect)

proc = eval(statement.to_ruby)
puts(proc.inspect)
puts(proc.call({ x: 3 }).inspect)

# p.51 DoNothingの実装
class DoNothing
  def to_ruby
    "-> e { e }"
  end
end

# p.51 Ifの実装
class If
  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e)}" + 
    "then (#{consequence.to_ruby}).call(e)" +
    "else (#{alternative.to_ruby}).call(e) end"
  end
end

# pp.51-52 Sequenceの実装
class Sequence
  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end
end

# p.52 Whileの実装
class While
  def to_ruby
    "-> e {" + 
    "while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" +
    " e" + 
    "}"
  end
end

# p.52 テストコード
statement =
  While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
  )
puts(statement.inspect)
puts(statement.to_ruby.inspect)

proc = eval(statement.to_ruby)
puts(proc.inspect)
puts(proc.call({ x: 1 }).inspect)
