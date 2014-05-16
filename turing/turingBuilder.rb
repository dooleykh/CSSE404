require_relative 'turing.rb'

BitWidth = 32
TapeNames = [:output, :input, :env, :objects, :call, :stack, :acc, :ra, :rb, :rc, :args]
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

def init
	m = SubMachine.stub 'init'
	m.simpleMerge writeConstant(:acc, 0)
	m.simpleMerge writeConstant(:ra, 0)
	m.simpleMerge writeConstant(:rb, 0)
	m.simpleMerge writeConstant(:rc, 0)
	m.simpleMerge writeSymbol(:objects, :loc)	
	m.simpleMerge writeConstant(:objects, 0)
	m.simpleMerge writeSymbol(:env, :methodScope)
	m.simpleMerge writeConstant(:output, 0)

	return m
end

def halt
	m = SubMachine.stub 'halt'
	m.states[m.first].transitions = [Transition.new( Hash.new, [Action.new(:halt, nil)], m.first)]
	return m
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

	def self.stub(label = nil)
		m = SubMachine.new(nil, nil)
		m.states = Hash.new
		if label
			labelNo = getLabelNo label
			m.first = getNextState "#{label}-#{labelNo}-stub"
			m.last = m.first
		else
			m.first = getNextState
			m.last = m.first
		end
		m.states[m.first] = State.new ( Array.new )
		return m
	end

	def finalize
		@states[:start] = State.new( [Transition.new( Hash.new, Array.new, @first)] )
		# @states[@last].transitions = [Transition.new(Hash.new, [Action.new(:halt, nil)], @last)]
		@tapes = Hash.new
		TapeNames.each{ |n|
			@tapes[n] = Tape.new(Array.new)
		}
	end
end

class GotoState < Machine
	@labels
	@first
	@last

	def initialize
		@labels = Hash.new
		@first = getNextState 'goto-front'
		@last = getNextState 'goto-end'
		@states = Hash.new
		@states[@last] = State.new ( Array.new )
		@states[@first] = State.new ( Array.new )
	end

	def register(stateName)
		@labels.push stateName
	end

	def finalize
		@labels.each{ |l|
			@states[@first].transitions.push(
				Transition.new( {:call=>l}, [Action.new(BlankSymbol, :call), Action.new(:left, :call)], l))}
	end	

end

Goto = GotoState.new

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

def writeSymbol(tape, symbol)
	m = SubMachine.empty "writeSymbol-#{tape},#{symbol}"
	m.states[m.first].transitions = [Transition.new( Hash.new, [Action.new(symbol, tape), Action.new(:right, tape)], m.last)]
	return m
end


# makes a new instance of given class, leaving a reference to it on tape. Uses tape and ra
def newObject(tape, javaClass)
	m = SubMachine.stub "newObject-#{tape},#{symbol}"
	m.simpleMerge scan(:objects, :right, BlankSymbol)
	m.simpleMerge scanBefore(:objects, :left, :loc)
	m.simpleMerge copy(:objects, tape)
	m.simpleMerge writeConstant(:ra, 1)
	m.simpleMerge add(tape, :ra)
	m.simpleMerge scan(:objects, :right, BlankSymbol)
	m.simpleMerge writeSymbol(:objects, :loc)
	m.simpleMerge copy(:ra, :objects)
	
	javaClass.env.each_key { |k|
		unless javaClass.env[k].class == JavaVariable
			next
		end

		m.simpleMerge writeSymbol(:objects, k)
		m.simpleMerge writeConstant(:objects, 0)
		m.simpleMerge moveDistance(:objects, BitWidth, :right)
	}

	m
end

# gets the value of variable, copies it to tape. If found on :object , writes 1 to ra, else writes 0.
# todo so much debugging
def getVar(tape, name)
	mFoundEnv = SubMachine.stub 'lookup3'
	mFoundEnv.simpleMerge copy(:env, tape)
	mFoundEnv.simpleMerge writeConstant(:ra, 0)

	# Scan to end of env
	mNotFound = scan(:env, :right, BlankSymbol)

	# look for this in env
	mNotFound.simpleMerge scanBefore(:env, :left, :this)

	# copy reference to current class
	mNotFound.simpleMerge copy(:env, tape)

	# scan to front of objects
	mNotFound.simpleMerge scan(:objects, :left, BlankSymbol)


	# Scans for the right reference
	mNF2 = SubMachine.empty 'lookupThis'

	# checks if we're at the right reference
	checkLoc = eq(tape, :objects)
	link(checkLoc.states[checkLoc.lastFalse], mNF2.first)
	checkLoc.mergeTrue copy(:objects, tape)
	checkLoc.mergeTrue writeConstant(:ra, 1)
	link(checkLoc.states[checkLoc.lastTrue], mNF2.last)

	errorState = SubMachine.empty 'lookupError'
	errorState.simpleMerge writeConstant(:output, 1)
	errorState.simpleMerge invert(:output)
	errorState.simpleMerge output(:output)
	es2 = SubMachine.empty 'lookupErrorHalt'
	es2.states[es2.first].transitions = [
		Transition.new( Hash.new, [Action.new(:halt, nil)], es2.last)]
	errorState.simpleMerge es2
	
	mNF2.states[mNF2.first].transitions = [
		Transition.new({:objects=>:loc}, [Action.new(:right, :objects)], checkLoc.first ),
		Transition.new({:objects=>BlankSymbol}, Array.new, errorState.first ),
		Transition.new(Hash.new, [Action.new(:right, :objects)], mNF2.first)]
	
	mNF2.merge errorState
	mNF2.merge checkLoc


	# at this point mNotFound goes to the object that we're in
	mNotFound.simpleMerge mNF2

	mFoundObjects = copy(:objects, tape)

	mNF3 = SubMachine.empty 'lookupInObject'
	mNF3.states[mNF3.first].transitions = [
		Transition.new( {:objects => name}, [Action.new(:right, :objects)], mFoundObjects.first),
		Transition.new( Hash.new, [Action.new(:right, :objects)], mNF3.first)]
	mNF3.merge mFoundObjects
	link(mFoundObjects.states[mFoundObjects.last], mNF3.last)

	mNotFound.simpleMerge mNF3

	# Go to end of env
	m = SubMachine.stub "getVar-#{tape},#{name}"
	m.simpleMerge scan(:env, :right, BlankSymbol)

	# look for var in env
	m2 = SubMachine.empty 'lookup2'
	m2.merge mFoundEnv
	link(mFoundEnv.states[mFoundEnv.last], m2.last)
	m2.merge mNotFound
	link(mNotFound.states[mNotFound.last], m2.last)
	m2.states[m2.first].transitions = [
		Transition.new( {:env=> :methodScope}, Array.new, mNotFound.first),
		Transition.new( {:env=> name}, [Action.new(:right, :env)], mFoundEnv.first),
		Transition.new( Hash.new, [Action.new(:left, :env)], m2.first)]
	m.simpleMerge m2

	m

end
	
# If the values of the two tapes are equal
def eq(tape1, tape2)
	m = ForkSubMachine.empty "eq-#{tape1},#{tape2}"

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
	m = ForkSubMachine.empty "pos-#{tape}"
	m.states[m.first] = State.new([
		Transition.new( {tape => 0}, Array.new, m.lastTrue ),
		Transition.new( {tape => 1}, Array.new, m.lastFalse )])
	return m
end

# Write a constant int to the tape, starting on the current position.
def writeConstant(tape, int)
	m2 = SubMachine.stub "writeConstant-#{tape},#{int}"
	m2.simpleMerge moveDistance(tape, BitWidth - 1, :right)
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
	m = SubMachine.empty "moveDistance-#{tape},#{dist},#{direction}"
	a = Array.new
	dist.times{ a.push Action.new(direction, tape) }

	m.states[m.first] = State.new [Transition.new( Hash.new, a, m.last )]
	m.states[m.last] = State.new []

	m
end

# Scans the tape, stopping on the first instance of symbol
def scan(tape, direction, symbol)
	m = SubMachine.empty "scan-#{tape},#{direction},#{symbol}"

	m.states = {
		m.first => State.new(
			[Transition.new( {tape => symbol}, Array.new, m.last),
			Transition.new( Hash.new , [Action.new(direction, tape)], m.first)]),
		m.last => State.new( Array.new )
	}

	m
end

def scanBefore(tape, direction, symbol)
	oppdir = :right
	oppdir = :left if direction== :right
	
	m = SubMachine.stub "scanBefore-#{tape},#{direction},#{symbol}"
	m.simpleMerge scan(tape, direction, symbol)
	m2 = moveDistance(tape, 1, oppdir)
	m.simpleMerge m2

	m
end


# copies BitWidth symbols from tape1 to tape2
def copy(tape1, tape2)
	m = SubMachine.empty "copy-#{tape1},#{tape2}"
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
	m = SubMachine.stub "push-#{tape}"
	m.simpleMerge moveDistance(tape, BitWidth, :right)
	m.simpleMerge writeSymbol(tape, :sep)
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

	m = SubMachine.empty "pop-#{tape}"
	m.states[m.first].transitions = [Transition.new( Hash.new, a, m.last)]

	# Now we're on top of the last bit of the prev. value on stack
	m2 = moveDistance(tape, (2*BitWidth) + 1, :left)
	m.simpleMerge(m2)

	m
end

def output(tape)
	m = SubMachine.stub "output-#{tape}"
	m.simpleMerge copy(tape, :output)
	m2 = SubMachine.empty
	m2.states[m2.first].transitions = [ Transition.new( Hash.new, [Action.new(:print, :output)], m2.last) ]

	m.simpleMerge m2

	m
end

# Inverts the value on tape. Uses ra.
def invert(tape)
	m = SubMachine.empty "invert-#{tape}"

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
	m = SubMachine.stub "sub-#{tape1},#{tape2}"
	m.simpleMerge invert(tape2)
	m.simpleMerge add(tape1, tape2)
	m.simpleMerge invert(tape2)

	m
end

# multiplies tape1 by tape2. Uses ra, rb
def mult(tape1, tape2)
	setup = SubMachine.stub "mult-#{tape1},#{tape2}"
	setup.simpleMerge writeConstant(:rb, 1)
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
	m = SubMachine.stub "add-#{tape1},#{tape2}"
	m.simpleMerge moveDistance(tape2, BitWidth - 1, :right)
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

def createScope()
	m = SubMachine.stub "createScope"
	m.simpleMerge scan(:env, :right, BlankSymbol)
	m.simpleMerge writeSymbol(:env, :scope)
	return m
end

def createMethodScope()
	m = SubMachine.stub "createMethodScope"
	m.simpleMerge scan(:env, :right, BlankSymbol)
	m.simpleMerge writeSymbol(:env, :scope)
	return m
end

def destroyScope()
	m = SubMachine.stub "destroyScope"
  m.simpleMerge scanBefore(:env, :right, BlankSymbol)
  m2 = SubMachine.empty 'DestroyScope'
  m2.states[m2.first].transitions = [
	  Transition.new({:env => :scope},[Action.new(BlankSymbol, :env), Action.new(:left, :env)], m2.last), 
	  Transition.new(Hash.new, [Action.new(BlankSymbol, :env), Action.new(:left, :env)], m2.first)]
  m.simpleMerge m2
  return m
end

def destroyMethodScope()
	m = SubMachine.stub "destroyMethodScope"
  m.simpleMerge scanBefore(:env, :right, BlankSymbol)
  m2 = SubMachine.empty 'DestroyMethodScope'
  m2.states[m2.first].transitions = [
	  Transition.new({:env => :methodScope},[Action.new(BlankSymbol, :env), Action.new(:left, :env)], m2.last), 
	  Transition.new(Hash.new, [Action.new(BlankSymbol, :env), Action.new(:left, :env)], m2.first)]

	m.simpleMerge m2
	return m
end

if __FILE__ == $PROGRAM_NAME
	m = writeConstant(:acc, 5)
	m.simpleMerge writeConstant(:r0, 5)
	m.simpleMerge mult(:acc, :r0)
	m.simpleMerge output(:acc)
	m.finalize

	print m.to_s
	m.run nil
end
