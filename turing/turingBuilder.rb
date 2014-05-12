require_relative 'turing.rb'

BitWidth = 32
TapeNames = [:output, :input, :env, :objects, :call, :stack, :acc, :r0, :ra, :rb, :rc, :args, :ret]
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

class ForkSubMachine < Machine
	@first
	@lastTrue
	@lastFalse

	attr_accessor :first, :lastTrue, :lastFalse

	# Merges the other machine's states into this one (and its tapes, but there shouldn't be any yet)
	# doesn't update first, last, or link the machines.
	def merge(otherMachine)
		@states.merge!(otherMachine.states)
	end

	# Merges the other machine into this one such that it happens immediately before this one
	def simpleMergeAfter(otherMachine)
		self.merge(otherMachine)
		link(otherMachine.states[otherMachine.last], @first)
		@first = otherMachine.first

		self
	end

	# Merges the other machine into this one such that it happens immediately after this one.
	def mergeTrue(otherMachine)
		self.merge(otherMachine)
		link(states[lastTrue], otherMachine.first)
		@lastTrue = otherMachine.last
	end

	# Merges the other machine into this one such that it happens immediately after this one.
	def mergeFalse(otherMachine)
		self.merge(otherMachine)
		link(states[lastFalse], otherMachine.first)
		@lastFalse = otherMachine.last
	end

	def self.empty(label = nil)
		m = ForkSubMachine.new(nil, nil)
		m.states = Hash.new
		if label
			labelNo = getLabelNo label
			m.first = getNextState "#{label}-#{labelNo}-first"
			m.lastFalse = getNextState "#{label}-#{labelNo}-lastFalse"
			m.lastTrue = getNextState "#{label}-#{labelNo}-lastTrue"
		else
			m.first = getNextState
			m.lastFalse = getNextState
			m.lastTrue = getNextState
			m.last = nil
		end
		m.states[m.lastFalse] = State.new ( Array.new )
		m.states[m.lastTrue] = State.new ( Array.new )
		m.states[m.first] = State.new ( Array.new )
		return m
	end

	#Fuses the two paths of execution into one, returns machine that does that.
	def join
		m = SubMachine.empty('join')
		m.merge self
		m.states[m.first].transitions = [Transition.new(Hash.new, Array.new, @first)]

		@states[@lastTrue].transitions = [Transition.new(Hash.new, Array.new, m.last ) ]
		@states[@lastFalse].transitions = [Transition.new(Hash.new, Array.new, m.last ) ]

		return m
	end
end

# If the values of the two tapes are equal
def eq(tape1, tape2)
	m = ForkSubMachine.empty 'eq'

	n = Array.new
	n.push m.first
	(BitWidth - 1).times { n.push getNextState }

	n.each_index{|i|
		trueActions = [Action.new(:right, tape1), Action.new(:right, tape2)]
		falseActions = Array.new
		i.times{ 
			falseActions.push Action.new(:left, tape1)
			falseActions.push Action.new(:left, tape2)
		}

		nextState = nil
		if(i < n.size()-1)
			nextState = n[i+1]
		else
			nextState = m.lastTrue
		end

		m.states[n[i]] = State.new([
			Transition.new( {tape1 => 0, tape2 => 0}, trueActions, nextState),
			Transition.new( {tape1 => 0, tape2 => 1}, falseActions, m.lastFalse),
			Transition.new( {tape1 => 1, tape2 => 0}, falseActions, m.lastFalse),
			Transition.new( {tape1 => 1, tape2 => 1}, trueActions, nextState)])
	}

	m2 = moveDistance(tape1, BitWidth, :left)
	m3 = moveDistance(tape2, BitWidth, :left)

	m.mergeTrue m2
	m.mergeTrue m3

	m
end

# if the value on the tape is positive
def pos(tape)
	m = ForkSubMachine.empty 'pos'
	m.states[m.first] = State.new([
		Transition.new( {tape => 0}, Array.new, m.lastTrue ),
		Transition.new( {tape => 1}, Array.new, m.lastFalse )])
	return m
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

	m2 = moveDistance(tape, BitWidth - 1, :right)
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

	m2.simpleMerge m3

	m2
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

# pushes space for a new value onto tape as in a stack. Doesn't actually write a new value.
def push(tape)
	m = moveDistance(tape, BitWidth, :right)
	m2 = SubMachine.empty 'push'
	m2.states[m2.first].transitions = [ Transition.new( Hash.new, [Action.new(:sep, tape), Action.new(:right, tape)], m2.last)]
	m.simpleMerge(m2)
	m
end

# deletes the top value from tape, as in a stack.
def pop(tape)
	a = Array.new
	# Move back to the stack seperator
	a.push Action.new(:left, tape)

	# Erase the stack seperator and the value
	(BitWidth + 1).times{
		a.push Action.new(BlankSymbol, tape)
		a.push Action.new(:right, tape)
	}

	m = SubMachine.empty 'pop'
	m.states[m.first].transitions = [Transition.new( Hash.new, a, m.last)]

	# Now we're on top of the last bit of the prev. value on stack
	m2 = moveDistance(tape, BitWidth - 1, :left)
	m.simpleMerge(m2)

	m
end

def output(tape)
	m = copy(tape, :output)
	m2 = SubMachine.empty
	m2.states[m2.first].transitions = [ Transition.new( Hash.new, [Action.new(:print, :output)], m2.last) ]

	m.simpleMerge m2

	m
end

# Inverts the value on tape. Uses ra.
def invert(tape)
	m = SubMachine.empty 'invert'

	n = Array.new
	n.push m.first
	(BitWidth-1).times{
		n.push getNextState
	}

	n.each_index{ |i|
		nextName = ''
		if i == n.size - 1
			nextName = m.last
		else
			nextName = n[i+1]
		end

		m.states[n[i]] = State.new([
			Transition.new( {tape => 0}, [Action.new(1, tape), Action.new(:right, tape)], nextName),
			Transition.new( {tape => 1}, [Action.new(0, tape), Action.new(:right, tape)], nextName)])
	}

	m2 = moveDistance(tape, BitWidth, :left)
	m3 = writeConstant(:ra, 1)
	m4 = add(tape, :ra)

	m.simpleMerge(m2)
	m.simpleMerge(m3)
	m.simpleMerge(m4)

	m
end

# subtracts tape2 from tape1. Uses ra
def sub(tape1, tape2)
	m = invert(tape2)
	m.simpleMerge add(tape1, tape2)
	m.simpleMerge invert(tape2)

	m
end

# multiplies tape1 by tape2. Uses ra, rb
def mult(tape1, tape2)
	setup = writeConstant(:rb, 1)
	setup.simpleMerge invert(:rb)
	# rb = -1
	setup.simpleMerge copy(tape1, :ra)
	# ra = tape2
	setup.simpleMerge writeConstant(tape1, 0)

	loopM = add(:ra, :rb)
	loopM = pos(:ra).simpleMergeAfter(loopM)
	loopM.mergeTrue add(tape1, tape2)

	m = SubMachine.empty 'mult'
	m.merge setup
	m.merge loopM

	link(m.states[m.first], setup.first)
	link(setup.states[setup.last], loopM.first)
	link(loopM.states[loopM.lastFalse], m.last)
	link(loopM.states[loopM.lastTrue], loopM.first)


	m
end

# Adds tape2 to tape1
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
			Transition.new( {tape2 => 1, tape1 => 0}, [Action.new(1, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 0, tape1 => 1}, [Action.new(1, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 1, tape1 => 1}, [Action.new(0, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next2)])

		m3.states[n2[i]] = State.new([
			Transition.new( {tape2 => 0, tape1 => 0}, [Action.new(1, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next1),
			Transition.new( {tape2 => 1, tape1 => 0}, [Action.new(0, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next2),
			Transition.new( {tape2 => 0, tape1 => 1}, [Action.new(0, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next2),
			Transition.new( {tape2 => 1, tape1 => 1}, [Action.new(1, tape1), Action.new(:left, tape1), Action.new(:left, tape2)], next2)])
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
	m = writeConstant(:acc, 167)
	m.simpleMerge writeConstant(:r0, 35)
	m.simpleMerge mult(:acc, :r0)
	m.simpleMerge output(:acc)
	m.finalize

	#print m.to_s
	m.runAnimated nil
end
