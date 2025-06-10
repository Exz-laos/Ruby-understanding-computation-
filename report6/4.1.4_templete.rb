#!/usr/bin/ruby

# p.112 Stackの実装
class Stack < Struct.new(:contents)
  def push(character)
    Stack.new([character] + contents)
  end

  def pop
    Stack.new(contents.drop(1))
  end

  def top 
    contents.first
  end

  def inspect
    "#<Stack (#{top}) #{contents.drop(1).join}>"
  end
end


# p.112 Stackのテスト
puts "1 : ----------"

stack = Stack.new(['a', 'b', 'c', 'd', 'e'])

puts stack.inspect

puts stack.top.inspect

puts stack.pop.pop.top.inspect

puts stack.push('x').push('y').top.inspect

puts stack.push('x').push('y').pop.top.inspect


# p.113 「PDAの構成」の実装1
class PDAConfiguration < Struct.new(:state, :stack)
end
# p.113 「PDAの規則」の実装1
class PDARule < Struct.new(:state, :character, :next_state, :pop_character,:push_characters)
  def applies_to?(configuration, character)
    self.state == configuration.state && 
      self.pop_character == configuration.stack.top &&
      self.character == character
  end
end
# p.113 「PDAの構成」のテスト
puts "\n2 : ----------"
rule = PDARule.new(1, '(', 2, '$', ['b', '$'])

puts rule.inspect

configuration = PDAConfiguration.new(1, Stack.new(['$']))

puts configuration.inspect

puts rule.applies_to?(configuration, '(')


# p.114 「PDAの規則」の実装2
class PDARule
  def follow(configuration)
     PDAConfiguration.new(next_state, next_stack(configuration))
  end

  def next_stack(configuration)
    popped_stack = configuration.stack.pop

    push_characters.reverse.inject(popped_stack){
      |stack, character| stack.push(character) }
  end
end
# p.114 「PDAの規則」のテスト
puts "\n3 : ----------"

puts rule.follow(configuration).inspect

# p.114 「DPDAの規則集」の実装
class DPDARulebook < Struct.new(:rules)
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end
  
  def rule_for(configuration, character)
    rules.detect { |rule| rule.applies_to?(configuration, character) }  
  end
end
# p.115 「DPDAの規則集」のテスト
puts "\n4 : ----------"

rulebook = DPDARulebook.new([
PDARule.new(1, '(', 2, '$', ['b', '$']),
PDARule.new(2, '(', 2, 'b', ['b', 'b']),
PDARule.new(2, ')', 2, 'b', []),
PDARule.new(2, nil, 1, '$', ['$'])
])

puts rulebook.inspect

configuration = rulebook.next_configuration(configuration, '(')

puts configuration.inspect

configuration = rulebook.next_configuration(configuration, '(')

puts configuration.inspect

configuration = rulebook.next_configuration(configuration, ')')

puts configuration.inspect


# p.115 「DPDA」の実装
class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_configuration.state) 
  end
  
  def read_character(character)
    self.current_configuration = rulebook.next_configuration(current_configuration, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end  

# p.115 「DPDA」のテスト
puts "\n5 : ----------"

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)

puts dpda.inspect

puts dpda.accepting?

dpda.read_string('(()')
puts dpda.accepting?

puts dpda.current_configuration


# p.116 「DPDAの規則集」の実装2
class DPDARulebook
  def applies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end

  def follow_free_moves(configuration)
    if applies_to?(configuration, nil)
      follow_free_moves(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

# p.116 「DPDAの規則集」のテスト2
puts "\n6 : ----------"

configuration = PDAConfiguration.new(2, Stack.new(['$']))

puts configuration.inspect

puts rulebook.follow_free_moves(configuration)


# p.116 DPDAの実装2
class DPDA
  def current_configuration
    rulebook.follow_free_moves(super)
  end
end


# pp.116-117 DPDAのテスト2
puts "\n7 : ----------"

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)

puts dpda.inspect

dpda.read_string('(()(')
puts dpda.accepting?

puts dpda.current_configuration.inspect

dpda.read_string('))()')
puts dpda.accepting?

puts dpda.current_configuration.inspect


# p.117 「DPDA設計」の実装
class DPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def accepts?(string)
    to_dpda.tap { |dpda| dpda.read_string(string)}.accepting?
  end

  def to_dpda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    DPDA.new(start_configuration, accept_states, rulebook)
  end
end

# p.117 「DPDA設計」のテスト1
puts "\n8 : ----------"

dpda_design = DPDADesign.new(1, '$', [1], rulebook)

puts dpda_design.inspect

puts dpda_design.accepts?('(((((((((())))))))))')

puts dpda_design.accepts?('()(())((()))(()(()))')

puts dpda_design.accepts?('(()(()(()()(()()))()')


# p.117 「DPDA設計」のテスト2
# dpda_design.accepts?('())')
# NoMethodError: undefined method `follow' for nil:NilClass

# pp.117-118 「PDAの構成」の実装1
class PDAConfiguration
  STUCK_STATE = Object.new
  def stuck
    PDAConfiguration.new(STUCK_STATE, stack)
  end
  def stuck?
    state == STUCK_STATE
  end
end

# p.118 DPDAの実装3
class DPDA
  def next_configuration(character)
    if rulebook.applies_to?(current_configuration, character)
      rulebook.next_configuration(current_configuration, character)
    else
      current_configuration.stuck
    end
  end

  def stuck?
    current_configuration.stuck?
  end

  def read_character(character)
    self.current_configuration = next_configuration(character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character) unless stuck?
    end
  end
end

# p.118 DPDAのテスト3
puts "\n9 : ----------"

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)

puts dpda.inspect

dpda.read_string('())')

puts dpda.current_configuration.inspect

puts dpda.accepting?

puts dpda.stuck?

puts dpda_design.accepts?('())')

