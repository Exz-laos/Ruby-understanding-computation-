#!/usr/bin/ruby

# 準備
require 'set'

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end
  def follow
    next_state
  end
  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    rule_for(state, character).follow
  end
  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end
  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end
  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end
  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end
  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
  def follow_free_moves(states)
    more_states = next_states(states, nil)
    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states)
    end
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end
  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end
  def current_states
    rulebook.follow_free_moves(super)
  end
  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end


# pp.81-82 正規表現の各構文クラスの実装1
## Pattern（パターン）
module Pattern
  def bracket(outer_precedence)
    if precedence < outer_precedence
      '(' + to_s + ')'
    else
      to_s
    end
  end

  def inspect
    "/#{self}/"
  end
end
## Empty（空文字列）
class Empty
  include Pattern

  def to_s
    ''
  end

  def precedence
    3
  end
end

## Literal（文字リテラル）
class Literal <Struct.new(:character)
  include Pattern
  def to_s
    character
  end

  def precedence
    3
  end
end

## Concatenate（結合）
class Concatenate < Struct.new(:first, :second)
  include Pattern

  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join
  end
  
  def precedence
    1
  end
end

## Choose（選択）
class Choose < Struct.new(:first, :second)
  include Pattern

  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence)}.join('|')
  end

  def precedence
    0
  end
end

## Repeat（繰り返し）
class Repeat < Struct.new(:pattern)
  include Pattern

  def to_s
    pattern.bracket(precedence) + '*'
  end

  def precedence
    2
  end
end

# p.83 テストコード1（正規表現を表す木構造の構築）
i = 1
puts i.to_s + ": ----------"

pattern =
  Repeat.new(
    Choose.new(
      Concatenate.new(Literal.new('a'), Literal.new('b')),
      Literal.new('a')
    )
  )
puts pattern.inspect

# p.84 正規表現の実装2（EmptyとLiteralに対して、NFAを生成する#to_nfa_designメソッドを実装）
class Empty
  def to_nfa_design
    start_state = Object.new
    accept_states = [start_state]
    rulebook = NFARulebook.new([])

    NFADesign.new(start_state, accept_states, rulebook)
  end
end

class Literal
  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rule = FARule.new(start_state, character, accept_state)
    rulebook = NFARulebook.new([rule])

    NFADesign.new(start_state, [accept_state], rulebook)
  end
end

# p.85 テストコード2（EmptyとLiteralの#to_nfa_designメソッドのテスト）
puts ""
i += 1
puts i.to_s + ": ----------"

nfa_design = Empty.new.to_nfa_design
puts nfa_design.inspect

puts nfa_design.accepts?('')
puts nfa_design.accepts?('a')

nfa_design = Literal.new('a').to_nfa_design
puts nfa_design.inspect

puts nfa_design.accepts?('')
puts nfa_design.accepts?('a')
puts nfa_design.accepts?('b')

# p.85 正規表現の実装3（Patternの#matches?メソッドで#to_nfa_designを利用）
module Pattern
  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

# p.85 テストコード3（#matches?メソッドのテスト）
puts ""
i += 1
puts i.to_s + ": ----------"

puts Empty.new.matches?('a')
puts Literal.new('a').matches?('a')

# pp.86-87 Concatenate#to_nfa_designの実装
class Concatenate
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design

    start_state = first_nfa_design.start_state
    accept_states = second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = first_nfa_design.accept_states.map { |state|
      FARule.new(state, nil, second_nfa_design.start_state)
  }
  rulebook = NFARulebook.new(rules + extra_rules)

  NFADesign.new(start_state, accept_states, rulebook)
 end
end
    

# p.87 テストコード4（Concatenate#to_nfa_designのテスト1）
puts ""
i += 1
puts i.to_s + ": ----------"

pattern = Concatenate.new(Literal.new('a'), Literal.new('b'))
puts pattern.inspect

puts pattern.matches?('a')
puts pattern.matches?('ab')
puts pattern.matches?('abc')


# p.87 テストコード5（Concatenate#to_nfa_designのテスト2）
puts ""
i += 1
puts i.to_s + ": ----------"

pattern =
  Concatenate.new(
    Literal.new('a'),
    Concatenate.new(Literal.new('b'), Literal.new('c'))
  )
puts pattern.inspect

puts pattern.matches?('a')
puts pattern.matches?('ab')
puts pattern.matches?('abc')

# p.89 Choose#to_nfa_designの実装
class Choose
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design

    start_state = Object.new
    accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design|
      FARule.new(start_state, nil, nfa_design.start_state)
    }
    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(start_state, accept_states, rulebook)
  end
end



# p.89 テストコード6（Choose#to_nfa_designのテスト）
puts ""
i += 1
puts i.to_s + ": ----------"

pattern = Choose.new(Literal.new('a'), Literal.new('b'))
puts pattern.inspect

puts pattern.matches?('a')
puts pattern.matches?('b')
puts pattern.matches?('c')


# p.91 Repeat#to_nfa_designの実装
class Repeat
  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design

    start_state = Object.new
    accept_states = pattern_nfa_design.accept_states + [start_state]
    rules = pattern_nfa_design.rulebook.rules
    extra_rules = pattern_nfa_design.accept_states.map { |accept_state|
      FARule.new(accept_state, nil, pattern_nfa_design.start_state)} + 
      [FARule.new(start_state, nil, pattern_nfa_design.start_state)]
      rulebook = NFARulebook.new(rules + extra_rules)

      NFADesign.new(start_state, accept_states, rulebook)
  end
end
# p.91 テストコード7（Repeat#to_nfa_designのテスト1）
puts ""
i += 1
puts i.to_s + ": ----------"

pattern = Repeat.new(Literal.new('a'))
puts pattern.inspect

puts pattern.matches?('')
puts pattern.matches?('a')
puts pattern.matches?('aaaa')
puts pattern.matches?('b')


# pp.91-92 テストコード8（Repeat#to_nfa_designのテスト2）
puts ""
i += 1
puts i.to_s + ": ----------"

pattern =
  Repeat.new(
    Concatenate.new(
      Literal.new('a'),
      Choose.new(Empty.new, Literal.new('b'))
    )
  )
puts pattern.inspect

puts pattern.matches?('')
puts pattern.matches?('a')
puts pattern.matches?('ab')
puts pattern.matches?('aba')
puts pattern.matches?('abab')
puts pattern.matches?('abaab')
puts pattern.matches?('abba')

# p.98 NFADesign#to_nfa に引数として current_states を追加
class NFADesign 
  def to_nfa(current_states = Set[start_state])
    NFA.new(current_states, accept_states, rulebook)
  end
end

# p.98 テストコード9（任意の状態から実行を開始1）
puts ""
i += 1
puts i.to_s + ": ----------"

rulebook = NFARulebook.new([
                             FARule.new(1, 'a', 1), FARule.new(1, 'a', 2), FARule.new(1, nil, 2),
                             FARule.new(2, 'b', 3),
                             FARule.new(3, 'b', 1), FARule.new(3, nil, 2)
                           ])
puts rulebook.inspect

nfa_design = NFADesign.new(1, [3], rulebook)
puts nfa_design.inspect

puts nfa_design.to_nfa.current_states.inspect

puts nfa_design.to_nfa(Set[2]).current_states.inspect
puts nfa_design.to_nfa(Set[3]).current_states.inspect

# p.99 テストコード10（任意の状態から実行を開始2）
puts ""
i += 1
puts i.to_s + ": ----------"

nfa = nfa_design.to_nfa(Set[2, 3])
puts nfa.inspect

nfa.read_character('b');
puts nfa.current_states

# p.99 NFASimulationクラスの実装
class NFASimulation < Struct.new(:nfa_design)
  def next_state(states, character)
    nfa_design.to_nfa(states).tap { |nfa| 
      nfa.read_character(character)}.current_states
  end
end



# pp.99-100 テストコード11（NFASimulationのテスト1）
puts ""
i += 1
puts i.to_s + ": ----------"

simulation = NFASimulation.new(nfa_design)

puts simulation.inspect

puts simulation.next_state(Set[1, 2], 'a').inspect
puts simulation.next_state(Set[1, 2], 'b').inspect
puts simulation.next_state(Set[3, 2], 'b').inspect
puts simulation.next_state(Set[1, 3, 2], 'b').inspect
puts simulation.next_state(Set[1, 3, 2], 'a').inspect

# p.100 NFARulebook#alphabetの実装
class NFARulebook
  def alphabet
    rules.map(&:character).compact.uniq
  end
end



# p.100 NFASimulation#rules_forの実装
class NFASimulation
  def rules_for(state)
    nfa_design.rulebook.alphabet.map { |character|
      FARule.new(state, character, next_state(state, character))
    }
  end
end


# p.100 テストコード12（NFASimulation#rules_forのテスト）
puts ""
i += 1
puts i.to_s + ": ----------"

puts rulebook.alphabet.inspect

puts simulation.rules_for(Set[1, 2]).inspect
puts simulation.rules_for(Set[3, 2]).inspect

# pp.100-101 NFASimulation#discover_states_and_rules の実装
class NFASimulation
  def discover_states_and_rules(states)
    rules = states.flat_map { |state| rules_for(state)}
    more_states = rules.map(&:follow).to_set

    if more_states.subset?(states)
      [states, rules]
    else
      discover_states_and_rules(states + more_states)
    end
  end
end

# p.101 テストコード13（NFASimulation#discover_states_and_rules のテスト）
puts ""
i += 1
puts i.to_s + ": ----------"

start_state = nfa_design.to_nfa.current_states
puts start_state.inspect

puts simulation.discover_states_and_rules(Set[start_state]).inspect

# p.101 テストコード14（NFAのシミュレーション状態の判別）
puts ""
i += 1
puts i.to_s + ": ----------"

puts nfa_design.to_nfa(Set[1, 2]).accepting?
puts nfa_design.to_nfa(Set[2, 3]).accepting?

# p.102 NFASimulation#to_dfa_designの実装
class NFASimulation
  def to_dfa_design
    start_state = nfa_design.to_nfa.current_states
    states, rules = discover_states_and_rules(Set[start_state])
    accept_states = states.select { |state| nfa_design.to_nfa(state).accepting? }

    DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
  end
end

# p.102 テストコード15（）
puts ""
i += 1
puts i.to_s + ": ----------"

dfa_design = simulation.to_dfa_design
puts dfa_design.inspect

puts dfa_design.accepts?('aaa')
puts dfa_design.accepts?('aab')
puts dfa_design.accepts?('bbbabb')
