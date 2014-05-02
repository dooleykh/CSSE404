BlankSymbol = :blank

class Machine
	@tapes
	# hash of name -> tape

	@states
	# hash of name -> state

	def initialize
		@tapes = Hash.new
		@states = Hash.new
	end

end

class Transition
	@conditions
	# hash of tape name -> required symbol on that tape
	@actions
	# array of actions

	def initialize
		@conditions = Hash.new
		@actions = Array.new
	end
end

class Action
	@tape
	# Tape: name of the tape in question
	@action
	# action: :left, :right, :print, :halt, or symbol to write

	def initialize
	end
end

class State
	@transitions

	def initialize
		@transitions = Array.new
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
