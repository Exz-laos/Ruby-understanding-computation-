#!/usr/bin/ruby

# DFAのシミュレーション

# p.67 規則集（rulebook）の実装
class FARule < Struct.new(:state, :character, :next_state)
   def applies_to?(state, character)
      self.state == state && self.character == character
   end

   def follow
     next_state
   end

   def inspect
      "#<FARule #{state.inspect} -- #{character}--> #{next_state.inspect}>"
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


# pp.67-68 テストコード

## テスト用DFAの定義
puts "(1)----------\n"
rulebook = DFARulebook.new([
FARule.new(1, 'a', 2),
FARule.new(1, 'b', 1),
FARule.new(2, 'a', 2),
FARule.new(2, 'b', 3),
FARule.new(3, 'a', 3),
FARule.new(3, 'b', 3)])

puts rulebook.inspect

## 遷移規則テスト
puts rulebook.next_state(1, 'a').inspect
puts rulebook.next_state(1, 'b').inspect
puts rulebook.next_state(2, 'b').inspect

# p.68 DFAの実装1
class DFA < Struct.new(:current_state, :accept_states, :rulebook)
    def accepting?
        accept_states.include?(current_state)
    end
end

# p.68 テストコード1
puts "(2)----------\n"

## 受理判定テスト
puts DFA.new(1, [1, 3], rulebook).accepting?
puts DFA.new(1, [3], rulebook).accepting?

# p.68 DFAの実装2
class DFA
    def read_character(character)
        self.current_state = rulebook.next_state(current_state, character)
    end
end

# p.68 テストコード2
puts "(3)----------\n"

## 遷移テスト（1文字ずつ読み込み）
dfa = DFA.new(1, [3], rulebook);

puts "init:\n"
puts dfa.current_state
puts dfa.accepting?

## 入力シンボル受付後の状態確認
dfa.read_character('b');

puts "after reading 'b'"
puts dfa.current_state
puts dfa.accepting?

dfa.read_character('a');

puts "after reading 'a'"
puts dfa.current_state
puts dfa.accepting?

dfa.read_character('b');

puts "after reading 'b'"
puts dfa.current_state
puts dfa.accepting?

# pp.68-69 テストコード2
puts "(3)----------\n"

## 遷移テスト（1文字ずつ読み込み）
dfa = DFA.new(1, [3], rulebook);

puts "init:\n"
puts dfa.current_state
puts dfa.accepting?

## 入力シンボル受付後の状態確認
dfa.read_character('b');

puts "after reading 'b'"
puts dfa.current_state
puts dfa.accepting?

3.times do dfa.read_character('a') end;

puts "after reading 'aaa'"
puts dfa.current_state
puts dfa.accepting?

dfa.read_character('b');

puts "after reading 'bbb'"
puts dfa.current_state
puts dfa.accepting?

# p.69 DFAの実装3
class DFA 
    def read_string(string)
        string.chars.each do |character|
            read_character(character)
        end
    end
end

# p.69 テストコード1
puts "(4)----------\n"

## 遷移テスト（文字列を読み込み）

dfa = DFA.new(1, [3], rulebook);

puts "init:\n"
puts dfa.current_state
puts dfa.accepting?

dfa.read_string('baaab');

puts "after reading 'baaab'"
puts dfa.current_state
puts dfa.accepting?

# p.69 DFAの「設計」の実装
class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
    def to_dfa
        DFA.new(start_state, accept_states, rulebook)
    end

    def accepts?(string)
        to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
    end
end


# pp.69-70 テストコード
puts "(5)----------\n"
dfa_design = DFADesign.new(1, [3], rulebook)

puts dfa_design.inspect

puts "'a': " + dfa_design.accepts?('a').to_s
puts "'baa': " + dfa_design.accepts?('baa').to_s
puts "'baba': " + dfa_design.accepts?('baba').to_s
