#!/usr/bin/ruby

# ビッグステップ意味論によるSIMPLEの実装

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

# p.42 NumberおよびBooleanの実装
class Number
  def evaluate(environment)
    self
  end
end

class Boolean
  def evaluate(environment)
    self
  end
end


# p.42 Variableの実装
class Variable
  def evaluate(environment)
    environment[name]
  end
end


# pp.42-43 Add、Multiply、LessThanの実装
class Add
  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

class Multiply
  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end

class LessThan
  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end


# p.43 テストコード
puts(Number.new(23).evaluate({}).inspect)

puts(Variable.new(:x).evaluate({x: Number.new(23)}).inspect)

puts(
  LessThan.new(
    Add.new(Variable.new(:x), Number.new(2)),
    Variable.new(:y)
  ).evaluate({x: Number.new(2), y: Number.new(5)}).inspect
)

# p.43 Assignの実装
class Assign

  def evaluate(environment)
    environment.merge({ name => expression.evaluate(environment) })
  end
end


# p.44 DoNothingおよびIfの実装
class DoNothing
  def evaluate(environment)
    environment
  end
end


class If
  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
    end
  end
end



# p.44 Sequenceの実装
class Sequence
  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end
end



# p.44 テストコード
statement =
  Sequence.new(
    Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
    Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))))
puts(statement.inspect)
puts(statement.evaluate({}).inspect)

# p.45 Whileの実装
class While
  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      evaluate(body.evaluate(environment))
    when Boolean.new(false)
      environment
    end
  end
end

# p.45 テストコード
statement =
  While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3))))
puts(statement.inspect)
puts(statement.evaluate({x: Number.new(1)}))
