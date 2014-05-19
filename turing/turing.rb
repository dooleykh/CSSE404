require 'set'
BlankSymbol = :blank

class Machine
	@tapes
	# hash of name -> tape

	@states
	# hash of name -> state

	@halted

	attr_accessor :tapes, :states, :halted

	def initialize(tapes, states)
		@tapes = tapes
		@states = states
		@halted = false
	end

	def states_size
		return @states.size
	end

	def transitions_size
		i = 0
		@states.each_value{ |s|
			i += s.transitions.size
		}
		return i
	end

	def actions_size
		i = 0
		@states.each_value{ |s|
			s.transitions.each{ |t|
				i += t.actions.size
			}
		}
		return i
	end

	def run(input, delay = nil, names = false)
		lastTime = Time.now
		state = :start
		unless delay == nil
			printState state
		end
		
		transitionsCount = 0
		
		while !@halted
			unless delay == nil
				while Time.now < lastTime + delay
					a = (lastTime + delay) - Time.now
					if a > 0
						sleep a
					end
				end
				lastTime = Time.now
			end

			if names
				puts state
			end
			state = @states[state].nextState(self)
			transitionsCount += 1
			unless delay==nil
				printState state
			end
		end

		puts "Halted after #{transitionsCount} transitions."
	end

	def printState(state)
		print "\n"*80
		puts "State: #{state}"
		@tapes.each_key { |k|
			puts k
			puts @tapes[k].to_s
		}
	end

	def to_s
		result = ""
		@states.keys.sort.each{|s|
		#@states.each_key{|s|
			result = "#{result}State #{s}:\n#{@states[s].to_s}"
		}

		return result
	end

	def to_s_short
		result = ""
		@states.keys.sort.each{|s|
			result = "#{result}State #{s} => \{#{@states[s].to_s_short}\}\n"
		}
		return result
	end

	def optimize
		puts "\nOptimizing..."
		removeUnlinked
		removeEpsilon
		while mergeIdentical
		end

	end

	def removeEpsilon
		i = 0
		@states.each_key{ |name|
			if name == :start
				next
			end


			state = @states[name]
			if (
				state.transitions.size == 1 and 
				state.transitions[0].conditions.empty? and 
				state.transitions[0].actions.empty?
			)
				oldState = name
				newState = state.transitions[0].nextState

				@states.each_value{ |s|
					s.transitions.each{ |t|
						if t.nextState == oldState
							t.nextState = newState
						end
					}
				}

				@states.delete name
				i += 1
			end
		}

		if i>0
			puts "    Removed #{i} epsilon transitions"
		end
	end



	def removeUnlinked
		linked = Set.new
		linked.add :start
		stack = [:start]

		until stack.empty?
			state = stack.pop
			@states[state].transitions.each{ |t|
				nextState = t.nextState

				unless linked.include? nextState
					unless stack.include? nextState
						stack.push nextState
					end

					linked.add nextState
				end
			}
		end

		i = 0
		@states.each_key{ |k|
			unless linked.include? k
				@states.delete k
				i += 1
			end
		}

		if i > 0
			puts "    Removed #{i} unreachable states"
		end
	end

	def mergeIdentical
		names = @states.keys.to_ary
		count = 0
		(0..(@states.size()-2)).each{ |i|
			((i+1)..(@states.size()-1)).each{ |j|
				unless @states[names[i]]
					next
				end

				unless @states[names[j]]
					next
				end

				if @states[names[i]] == @states[names[j]]
					mergeStates(names[i], names[j])
					count += 1
				end
			}
		}

		if count > 0
			puts "    Merged #{count} identical states"
			return true
		else
			return false
		end
	end

	# Merges two identical states (they had better be identical)
	def mergeStates(state1, state2)
		#p state1
		#p state2
		@states.each_value{ |s|
			s.transitions.each{ |t|
				if t.nextState == state2
					t.nextState = state1
				end
			}
		}

		@states.delete state2
	end

	# remove states with unconditional transitions (append actions to transitions to that state)

	# combine identical states 

	# rename states and tape symbols
end

class Transition
	@conditions
	# hash of tape name -> required symbol on that tape
	
	@actions
	# array of actions

	@nextState

	attr_accessor :nextState, :actions, :conditions

	def to_s
		result = ''
		if @conditions.size > 0
			result += 'When '
			@conditions.each_key{ |k|
				result += "(#{k}, #{@conditions[k]}), "
			}
		end

		result += 'do '

		@actions.each{ |a|
			result += "#{a.to_s}, "
		}

		result += "goto #{@nextState}"

		return result
	end




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
		@actions.each{ |a| a.perform machine }
		return @nextState
	end

	def ==(b)
		if b.class != Transition
			return false
		end

		if b.conditions != @conditions
			return false
		end

		if b.nextState != @nextState
			return false
		end

		if b.actions != @actions
			return false
		end

		return true
	end

end

class Action
	@tape
	# Tape: name of the tape in question
	@action
	# action: :left, :right, :print, :halt, or symbol to write

	attr_accessor :tape, :action

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
			machine.tapes[@tape].to_s
		when :halt
			machine.halted = true
		else
			machine.tapes[@tape].write @action
		end
	end

	def to_s
		case @action
		when :left
			return "(#{@tape} <)"
		when :right
			return "(#{@tape} >)"
		when :print
			return "(#{@tape} print)"
		when :halt
			return "(halt)"
		else
			return "(#{@tape} write \"#{@action}\")"
		end
	end

	def ==(b)
		if b.class != Action
			return false
		end

		if b.tape != @tape
			return false
		end

		if b.action != @action
			return false
		end

		return true
	end

end

class State
	@transitions
	# array of transitions

	attr_accessor :transitions

	def initialize(transitions)
		@transitions = transitions
	end

	def to_s
		result = ""
		@transitions.each {|t|
			result = "#{result}  #{t.to_s}\n"
		}

		return result
	end

	def to_s_short
		result = ""
		prev = nil
		@transitions.map{|x| x.nextState}.sort.uniq.each{|t|
			result += " #{t}"
		}
		return result
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

	def ==(b)
		if b.class != State
			return false
		end

		if b.transitions != @transitions
			return false
		end

		return true
	end
end

class Tape
	# The tape is initially of infinite length and full of BlankSymbols
	# Oh, and its a doubly linked list, because this is THE PERFECT APPLICATION for that.

	@node

	# def initialize
	# 	@node = TapeNode.new(BlankSymbol)
	# end

	def initialize(array)
		@node = TapeNode.new(BlankSymbol)
		currentNode = @node
		array.each_index {|i|
			currentNode.symbol = array[i]

			if i < (array.size() -1)
				newNode = TapeNode.new(BlankSymbol)
				currentNode.right = newNode
				newNode.left = currentNode
				currentNode = newNode
			end
		}
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
		{:output => Tape.new(Array.new), :input => Tape.new([1, 1, 1, 1, 1])},
		{:start => State.new(
			[Transition.new({:input => 1}, [
				Action.new("1", :output), 
				Action.new(:right, :output), 
				Action.new("1", :output), 
				Action.new(:right, :output),
				Action.new(:right, :input)],
			:start),
			Transition.new({:input => BlankSymbol}, [
				Action.new(:print, :output)],
			:end)]),
		:end => State.new(
			[Transition.new(Hash.new, [Action.new(:halt, nil)], :end)])})
	m.run nil
	print m.to_s



	# m = Machine.new(
	# 	{:output => Tape.new},
	# 	{:start => State.new(
	# 		[Transition.new(Hash.new, [Action.new("h", :output), Action.new(:right, :output)], :s1)]),
	# 	:s1 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("e", :output), Action.new(:right, :output)], :s2)]),
	# 	:s2 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s3)]),
	# 	:s3 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s4)]),
	# 	:s4 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("o", :output), Action.new(:right, :output)], :s5)]),
	# 	:s5 => State.new(
	# 		[Transition.new(Hash.new, [Action.new(" ", :output), Action.new(:right, :output)], :s6)]),
	# 	:s6 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("w", :output), Action.new(:right, :output)], :s7)]),
	# 	:s7 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("o", :output), Action.new(:right, :output)], :s8)]),
	# 	:s8 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("r", :output), Action.new(:right, :output)], :s9)]),
	# 	:s9 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("l", :output), Action.new(:right, :output)], :s10)]),
	# 	:s10 => State.new(
	# 		[Transition.new(Hash.new, [Action.new("d", :output)], :end)]),
	# 	:end => State.new(
	# 		[Transition.new(Hash.new, [Action.new(:print, :output), Action.new(:halt, nil)], :end)])})
	# m.run nil
	# print m.to_s
end
