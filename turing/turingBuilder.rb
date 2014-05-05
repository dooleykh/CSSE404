require_relative 'turing.rb'

$nextState = 0

def getNextState
	sym = "s#{$nextState}".to_sym
	$nextState += 1
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
		@tapes.merge!(otherMachine.tapes)
		@states.merge!(otherMachine.states)
	end

	# Merges the other machine into this one such that it happens immediately after this one.
	def simpleMerge(otherMachine)
		self.merge(otherMachine)
		link(states[last], otherMachine.first)
		last = otherMachine.last
	end

end
