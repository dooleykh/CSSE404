require_relative 'turing.rb'

BitWidth = 32

$nextState = 0

TapeNames = [:output, :input, :env, :objects, :call, :stack, :acc, :r0, :args, :ret]

def getNextState
	sym = "s#{$nextState}".to_sym
	$nextState += 1
	sym
end

# Makes state1 unconditionally point to state2 (for linking two submachines)
# state1 is a state and state2 is a state name
def link(state1, state2)
	state1.transitions = [Transition.new( Hash.new, Array.new, state2 )]
end

class SubMachine < Machine
	@first
	@last
	# These are the names of the first and last states of the submachine. The
	# last state should have no outgoing transitions so that submachines can be
	# linked by unconditionally pointing the last state somewhere.

	attr_accessor :first, :last

	# Merges the other machine's states into this one (and its tapes, but there shouldn't be any yet)
	# doesn't update first, last, or link the machines.
	def merge(otherMachine)
		@states.merge!(otherMachine.states)
	end

	# Merges the other machine into this one such that it happens immediately after this one.
	def simpleMerge(otherMachine)
		self.merge(otherMachine)
		link(states[last], otherMachine.first)
		@last = otherMachine.last
	end

	def self.empty
		m = SubMachine.new(nil, nil)
		m.states = Hash.new
		m.first = getNextState
		m.last = getNextState
		m.states[m.last] = State.new ( Array.new )
		return m
	end

	def finalize
		@states[:start] = State.new( [Transition.new( Hash.new, Array.new, @first)] )
		@states[@last].transitions = [Transition.new(Hash.new, [Action.new(:halt, nil)], @last)]
		@tapes = Hash.new
		TapeNames.each{ |n|
			@tapes[n] = Tape.new(Array.new)
		}
	end

end

def writeConstant(tape, int)
	# m = scanLeft(tape)

	# m2 = moveDistance(tape, BitWidth, :right)
	# m.simpleMerge(m2)

	# puts '----------'
	# print m.to_s
	# p m.first
	# p m.last
	# puts '----------'

	m3 = SubMachine.empty
	a = Array.new
	(0..(BitWidth-1)).each {|i|
		val = int % 2
		int = int / 2

		a.push Action.new(val, tape)
		a.push Action.new(:left, tape)
	}
	a.pop

	m3.states[m3.first] = State.new [Transition.new( Hash.new, a, m3.last)]
	m3.states[m3.last] = State.new []

	m3
end

def moveDistance(tape, dist, direction)
	m = SubMachine.empty
	a = Array.new
	dist.times{ a.push Action.new(direction, tape) }

	m.states[m.first] = State.new [Transition.new( Hash.new, a, m.last )]
	m.states[m.last] = State.new []

	m
end

def scanLeft(tape)
	m = SubMachine.empty

	m.states = {
		m.first => State.new(
			[Transition.new( {tape => BlankSymbol}, [Action.new(:right, tape)], m.last),
			Transition.new( Hash.new , [Action.new(:left, tape)], m.first)]),
		m.last => State.new( Array.new )
	}

	m
end

def add(tape)
	m = moveDistance(:acc, BitWidth - 1, :right)
	m2 = moveDistance(tape,  BitWidth - 1, :right)
	m.simpleMerge(m2)

	m3 = SubMachine.empty
	n1 = Array.new
	n2 = Array.new
	BitWidth.times{
		n1.push getNextState
		n2.push getNextState
	}

	n1.each_index { |i|
		if i < (n1.size() -1)
			next1 = n1[i+1]
			next2 = n2[i+1]
		else
			next1 = next2 = m3.last
		end
		
		m3.states[n1[i]] = State.new([
			Transition.new( {:acc => 0, tape => 0}, [Action.new(:left, tape), Action.new(:left, :acc)], next1),
			Transition.new( {:acc => 1, tape => 0}, [Action.new(1, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next1),
			Transition.new( {:acc => 0, tape => 1}, [Action.new(1, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next1),
			Transition.new( {:acc => 1, tape => 1}, [Action.new(0, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next2)])

		m3.states[n2[i]] = State.new([
			Transition.new( {:acc => 0, tape => 0}, [Action.new(1, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next1),
			Transition.new( {:acc => 1, tape => 0}, [Action.new(0, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next2),
			Transition.new( {:acc => 0, tape => 1}, [Action.new(0, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next2),
			Transition.new( {:acc => 1, tape => 1}, [Action.new(1, :acc), Action.new(:left, tape), Action.new(:left, :acc)], next2)])
	}

	newLast = getNextState
	m3.states[m3.last].transitions = [Transition.new(Hash.new, [Action.new(:right, tape), Action.new(:right, :acc)], newLast)]
	m3.last = newLast
	m3.states[newLast] = State.new( Array.new )

	m3.states[m3.first] = State.new ([Transition.new(Hash.new, Array.new, n1[0])])

	m.simpleMerge(m3)

	m
end

if __FILE__ == $PROGRAM_NAME
	m = writeConstant(:acc, 31)
	m2 = writeConstant(:r0, 8)
	m3 = add(:r0)
	m.simpleMerge(m2)
	m.simpleMerge(m3)
	m.finalize
	print m.to_s
	m.runAnimated nil
end
