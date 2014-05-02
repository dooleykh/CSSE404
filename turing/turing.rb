BlankSymbol = :blank

class Machine
	@tapes
	# hash of name -> tape

	@states
	# hash of name -> state

	@halted

	attr_accessor :tapes, :states

	def initialize
		@tapes = Hash.new
		@states = Hash.new
		@halted = false
	end

	def run(input)
		state = states[:start]
		while !@halted
			p state
			state = state.nextState(self)
		end
	end

end

class Transition
	@conditions
	# hash of tape name -> required symbol on that tape
	
	@actions
	# array of actions

	@nextState

	attr_accessor :nestState

	def initialize(conditions, actions, nxt)
		@conditions = conditions
		@actions = actions
		@nextState = nxt
	end

	# Determines if this transition's conditions are met by machine
	def match(machine)
		@conditions.each_key{ |k|
			unless machine.tapes[k].read == @conditions[k]
				return false
			end
		}
		return true
	end

	# Performs the actions associated with this transition, returning the next state
	def do(machine)
		actions.each{ |a| a.perform machine }
		return @nextState
	end
end

class Action
	@tape
	# Tape: name of the tape in question
	@action
	# action: :left, :right, :print, :halt, or symbol to write

	def initialize(action, tape)
		@action = action
		@tape = tape
	end

	def perform(machine)
		case @action
		when :left
			machine.tapes[@tape].left
		when :right
			machine.tapes[@tape].right
		when :print
			puts "#{machine.tapes[@tape]}"
		when :halt
			machine.halted = true
		else
			machine.tapes[@tape].write @action
		end
	end
end

class State
	@transitions
	# array of transitions

	def initialize(transitions)
		@transitions = transitions
	end

	# performs a transition, doing whatever actions are associated and 
	def nextState(machine)
		if machine.halted
			return nil
		end

		@transitions.each{ |t|
			if t.match machine
				return t.do machine
			end
		}
		machine.halted = true
		return nil
	end


end

class Tape
	# The tape is initially of infinite length and full of BlankSymbols
	# Oh, and its a doubly linked list, because this is THE PERFECT APPLICATION for that.

	@node

	def initialize
		@node = TapeNode.new(BlankSymbol)
	end

	def read
		@node.symbol
	end

	def write(symbol)
		@node.symbol = symbol
	end

	def left
		if @node.left == nil
			@node.left = TapeNode.new(BlankSymbol)
			@node.left.right = @node
		end

		@node = @node.left

		if (@node.right.symbol == BlankSymbol) and (@node.right.right == nil)
			@node.right = nil
		end
	end

	def right
		if @node.right == nil
			@node.right = TapeNode.new(BlankSymbol)
			@node.right.left = @node
		end

		@node = @node.right

		if(@node.left.symbol == BlankSymbol) and (@node.left.left == nil)
			@node.left = nil
		end
	end

	def to_s
		pNode = @node
		while pNode.left != nil
			pNode = pNode.left
		end

		print '|'
		while true

			if pNode == @node
				print '>'
			end

			print pNode.symbol
			print '|'
			pNode = pNode.right
			if pNode == nil
				break
			end
		end
		puts
	end

end

class TapeNode
	@left
	@right
	@symbol

	attr_accessor :left, :right, :symbol

	def initialize(symbol)
		@symbol = symbol
	end
end

if __FILE__ == $PROGRAM_NAME
	m = Machine.new(
		{:output => Tape.new},
		{:start => State.new(
			[Transition.new(Hash.new, [Action.new("h", :output), Action.new(:right, :output)], :s1)]),
		:s1 => State.new(
			[Transition.new(Hash.new, [Action.new("e", :output), Action.new(:right, :output)], :s2)]),
		:s2 => State.new(
			[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s3)]),
		:s3 => State.new(
			[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s4)]),
		:s4 => State.new(
			[Transition.new(Hash.new, [Action.new("o", :output), Action.new(:right, :output)], :s5)]),
		:s5 => State.new(
			[Transition.new(Hash.new, [Action.new(" ", :output), Action.new(:right, :output)], :s6)]),
		:s6 => State.new(
			[Transition.new(Hash.new, [Action.new("w", :output), Action.new(:right, :output)], :s7)]),
		:s7 => State.new(
			[Transition.new(Hash.new, [Action.new("o", :output), Action.new(:right, :output)], :s8)]),
		:s8 => State.new(
			[Transition.new(Hash.new, [Action.new("r", :output), Action.new(:right, :output)], :s9)]),
		:s9 => State.new(
			[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s10)]),
		:s10 => State.new(
			[Transition.new(Hash.new, [Action.new("d", :output), Action.new(:right, :output)], :end)]),
		:end => State.new(
			[Transition.new(Hash.new, [Action.new(:print, nil), Action.nil(:halt, nil)], :end)])})
	m.run nil
end


