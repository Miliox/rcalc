# encoding: utf-8
module RCalc
  module Tokenizer
    BLANK = [' ', "\n", "\r", "\v"]
    NUMBER = '0'..'9'
    OPERATOR = ['+', '-', '*', '/', '(', ')']

    def self.push_and_clear(number, tokens)
      unless number.empty?
        tokens.push number.join.to_i
        number.clear
      end
    end

    public
    def self.tokenize(math_expr)
      tokens, number = [], []
      math_expr.each_char do |c|
        if OPERATOR.include? c
          push_and_clear(number, tokens)
          tokens.push c.to_sym
        elsif NUMBER.include? c
          number.push c
        elsif BLANK.include? c
          push_and_clear(number, tokens)
        else
          raise "invalid character #{c}"
        end
      end
      push_and_clear(number, tokens)
      tokens
    end
  end

  module Translator
    POP_PRIORY = {:'+' => 1, :'-' => 1, :'*' => 2, :'/' => 2,
                  :'(' => 0}
    PUSH_PRIORY = {:'+' => 1, :'-' => 1, :'*' => 2, :'/' => 2,
                   :'(' => 3}
    def self.translate(infix)
      postfix, op_stack = [], []
      ctx_stack = [op_stack]

      is_first = true
      infix.each do |t|
        postfix.push 0 if is_first and [:'+', :'-'].include? t
        is_first = false

        if [:'+', :'-', :'*', :'/'].include? t
          postfix.push op_stack.pop \
            while !op_stack.empty? \
              and POP_PRIORY[op_stack.last] >= PUSH_PRIORY[t]
          op_stack.push t
        elsif :'(' == t
          ctx_stack.push []
          op_stack = ctx_stack.last

          is_first = true
        elsif :')' == t
          postfix += ctx_stack.pop.reverse
          op_stack = ctx_stack.last

          raise 'stack underflow' unless ctx_stack.size > 0
        elsif t.is_a? Numeric
          postfix.push t
        else
          raise "invalid token #{t}"
        end
      end
      raise 'unclosed bracket' unless ctx_stack.size == 1
      postfix + op_stack.reverse
    end
  end

  module PostfixMachine
    OPERATION = {:'+' => ->(x,y){x+y}, :'-' => ->(x,y){x-y},
                 :'*' => ->(x,y){x*y}, :'/' => ->(x,y){x/y}}
    def self.process(expr)
      stack = []
      expr.each do |e|
        if e.is_a? Numeric
          stack.push e
        elsif OPERATION.has_key? e
          arg2, arg1 = stack.pop, stack.pop
          stack.push OPERATION[e].call(arg1, arg2)
        else
          raise "invalid element #{e}"
        end
      end
      raise 'incomple expression' unless stack.size == 1
      stack.pop
    end
  end

  def self.calculate(expression)
    PostfixMachine::process(
      Translator::translate(
        Tokenizer::tokenize( expression ) ) )
  end
end
