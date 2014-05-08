require_relative 'turing.rb'

BitWidth = 32
TapeNames = [:output, :input, :env, :objects, :call, :stack, :acc, :r0, :args, :ret]
NameLength = 5

$nextState = 0
$labelDict = Hash.new


def getLabelNo(label)
	unless $labelDict[label]
		$labelDict[label] = -1
	end

	$labelDict[label] += 1
	$labelDict[label]
end

# Gets a new unique state name, which includes the optionally specified label
def getNextState(label = nil)
	sym = ''
	name = $nextState.to_s
	while name.length < NameLength
		name = '0' + name
	end
	if label
		sym = "s#{name}-#{label}".to_sym
	else
		sym = "s#{name}".to_sym
	end
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

	def self.empty(label = nil)
		m = SubMachine.new(nil, nil)
		m.states = Hash.new
		if label
			labelNo = getLabelNo label
			m.first = getNextState "#{label}-#{labelNo}-first"
			m.last = getNextState "#{label}-#{labelNo}-last"
		else
			m.first = getNextState
			m.last = getNextState
		end
		m.states[m.last] = State.new ( Array.new )
		m.states[m.first] = State.new ( Array.new )
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

# Write a constant int to the tape, starting on the current position.
def writeConstant(tape, int)
	# m = scanLeft(tape)

	# m2 = moveDistance(tape, BitWidth, :right)
	# m.simpleMerge(m2)

	# puts '----------'
	# print m.to_s
	# p m.first
	# p m.last
	# puts '----------'

	m3 = SubMachine.empty 'WCons'
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

# Moves a tape a certian distance
def moveDistance(tape, dist, direction)
	m = SubMachine.empty 'mv'
	a = Array.new
	dist.times{ a.push Action.new(direction, tape) }

	m.states[m.first] = State.new [Transition.new( Hash.new, a, m.last )]
	m.states[m.last] = State.new []

	m
end

# Scans the tape left, stopping on the last non blank symbol
def scanLeft(tape)
	m = SubMachine.empty 'scanL'

	m.states = {
		m.first => State.new(
			[Transition.new( {tape => BlankSymbol}, [Action.new(:right, tape)], m.last),
			Transition.new( Hash.new , [Action.new(:left, tape)], m.first)]),
		m.last => State.new( Array.new )
	}

	m
end

# copies BitWidth symbols from tape1 to tape2
def copy(tape1, tape2)
	m = SubMachine.empty 'copy'
	n = Array.new
	n.push m.first
	(BitWidth - 1).times{
		n.push getNextState
	}

	n.each_index { |i|
		nextName = nil
		if i == (n.size() -1)
			nextName = m.last
		else
			nextName = n[i+1]
		end

		m.states[n[i]] = State.new([
			Transition.new( {tape1 => 0}, [Action.new(0, tape2), Action.new(:right, tape1), Action.new(:right, tape2)], nextName),
			Transition.new( {tape1 => 1}, [Action.new(1, tape2), Action.new(:right, tape1), Action.new(:right, tape2)], nextName)
		])
	}

	m2 = moveDistance(tape1, BitWidth, :left)
	m3 = moveDistance(tape2, BitWidth, :left)
	m.simpleMerge(m2)
	m.simpleMerge(m3)

	m
end
								 
def add(tape1, tape2)
	m = moveDistance(tape2, BitWidth - 1, :right)
	m2 = moveDistance(tape1,  BitWidth - 1, :right)
	m.simpleMerge(m2)

	m3 = SubMachine.empty 'add'
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
			Transition.new( {tape2 => 0, tape1 => 0}, [Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 1, tape1 => 0}, [Action.new(1, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 0, tape1 => 1}, [Action.new(1, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 1, tape1 => 1}, [Action.new(0, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next2)])

		m3.states[n2[i]] = State.new([
			Transition.new( {tape2 => 0, tape1 => 0}, [Action.new(1, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 1, tape1 => 0}, [Action.new(0, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next2),
			Transition.new( {tape2 => 0, tape1 => 1}, [Action.new(0, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next2),
			Transition.new( {tape2 => 1, tape1 => 1}, [Action.new(1, tape2), Action.new(:left, tape1), Action.new(:left, tape2)], next2)])
	}

	newLast = getNextState
	m3.states[m3.last].transitions = [Transition.new(Hash.new, [Action.new(:right, tape1), Action.new(:right, tape2)], newLast)]
	m3.last = newLast
	m3.states[newLast] = State.new( Array.new )

	m3.states[m3.first] = State.new ([Transition.new(Hash.new, Array.new, n1[0])])

	m.simpleMerge(m3)

	m
end

if __FILE__ == $PROGRAM_NAME
	m = writeConstant(:acc, 31)
	m2 = writeConstant(:r0, 8)
	m3 = add(:r0, :acc)
	m.simpleMerge(m2)
	m.simpleMerge(m3)
	m4 = copy(:acc, :output)
	m.simpleMerge(m4)
	m.finalize
	print m.to_s
	m.runAnimated nil
end
