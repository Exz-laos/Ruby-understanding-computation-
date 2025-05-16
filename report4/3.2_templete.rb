#!/usr/bin/ruby

# 準備
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

# NFAのシミュレーション

# pp.73-74 NFAの規則集の実装1
require 'set'
class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_rules_for(state,character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end


# p.74 テストコード
puts "(1)----------\n"
rulebook = NFARulebook.new([
FARule.new(1, 'a', 1),
FARule.new(1, 'b', 1),
FARule.new(1, 'b', 2),
FARule.new(2, 'a', 3),
FARule.new(2, 'b', 3),
FARule.new(3, 'a', 4),
FARule.new(3, 'b', 4)
])

puts rulebook.inspect

puts rulebook.next_states(Set[1], 'b').inspect
puts rulebook.next_states(Set[1, 2], 'a').inspect
puts rulebook.next_states(Set[1, 3], 'b').inspect


# p.74 NFAの実装1
class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end
end



# p.75 テストコード
puts "(2)----------\n"
puts NFA.new(Set[1], [4], rulebook).accepting?.inspect
puts NFA.new(Set[1, 2, 4], [4], rulebook).accepting?.inspect

# p.75 NFAの実装2
class NFA
  def read_character(character)
    self.current_states =  rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

# pp.75-76 テストコード
puts "(3)----------\n"
nfa = NFA.new(Set[1], [4], rulebook);
puts nfa.inspect

nfa.read_character('b');
puts "'b': " + nfa.accepting?.to_s

nfa.read_character('a');
puts "'a': " + nfa.accepting?.to_s

nfa.read_character('b');
puts "'b': " + nfa.accepting?.to_s

nfa = NFA.new(Set[1], [4], rulebook)
puts nfa.inspect

nfa.read_string('bbbbb');
puts "'bbbbb': " + nfa.accepting?.to_s

# p.76 NFAの「設計」の実装
## 入力シーケンスごとにDFAオブジェクトを生成し、受理できるかどうかを判断する
class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
     to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end


# p.76 テストコード
puts "(4)----------\n"
nfa_design = NFADesign.new(1, [4], rulebook)

puts "'bab': " + nfa_design.accepts?('bab').to_s
puts "'bbbbb': " + nfa_design.accepts?('bbbbb').to_s
puts "'bbabb': " + nfa_design.accepts?('bbabb').to_s

# p.78 テストコード
puts "(5)----------\n"
rulebook = NFARulebook.new([
FARule.new(1, nil, 2),
FARule.new(1, nil, 4),
FARule.new(2, 'a', 3),
FARule.new(3, 'a', 2),
FARule.new(4, 'a', 5),
FARule.new(5, 'a', 6),
FARule.new(6, 'a', 4)
])

puts rulebook.next_states(Set[1], nil).inspect

# p.78 NFAの規則集の実装2
class NFARulebook
  def follow_free_moves(states)
    more_states = next_states(states, nil)

    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states)
    end
  end
end

# p.79 テストコード
puts "(6)----------\n"
puts rulebook.follow_free_moves(Set[1]).inspect

# p.79 NFAの実装3
class NFA
  def current_states
    rulebook.follow_free_moves(super)
  end
end

# p.79 テストコード2
puts "(7)----------\n"
nfa_design = NFADesign.new(1, [2, 4], rulebook)
puts "'aa': " + nfa_design.accepts?('aa').to_s
puts "'aaa': " + nfa_design.accepts?('aaa').to_s
puts "'aaaaa': " + nfa_design.accepts?('aaaaa').to_s
puts "'aaaaaa': " + nfa_design.accepts?('aaaaaa').to_s
