require_relative "../parser/parser.rb"
require_relative  "../lexer/lexer.rb"
require_relative "./turingBuilder.rb"

$GlobalEnv = Hash.new
$Failed = false

# Recursively typecheck some statements
def walk(tree, env)
	if not tree
		return
	end

	case tree.name
	when :Program, :ClassDeclSt, :ClassDecl, :MethodDeclSt, :ClassVarDeclSt, :MainClassDecl, :MethodDecl, :ClassVarDecl, :FormalSt, :FormalPl, :Formal, :Type
		puts "Shouldn't happen" #handled by earlier passes
		$Failed = true

	when :StmtSt
		tree.children.each { |c| walk(c, env) }

	when :Expr
		resolveExprType(tree, env)

	when :Stmt
	  	case tree.type
	  	when :block
		  	env << {}
		  	tree.children.each { |c| walk(c, env) }
		  	env.pop
      
		when :if, :while
			tree.children.each { |c| walk(c, env) }

		when :var_dec
			unless resolveType(tree.children[0]) == resolveExprType(tree.children[2], env)
				puts "Error - that expression doesn't make that type"
				$Failed = true
				raise JavaSyntaxError
			end

			if env.last[tree.children[1].value]
				puts "ERROR - variable #{tree.children[1]} already defined"
				$Failed = true
				raise JavaSyntaxError
			end

			var = JavaVariable.new(resolveType(tree.children[0]))
			env.last[tree.children[1].value] = var

	  	when :var_asgn

		  	unless lookup(tree.children[0].value, env).type == resolveExprType(tree.children[1], env)
				puts "Error - that expression doesn't make that type"
				$Failed = true
        		
				raise JavaSyntaxError
		  	end

		  	unless env.last[tree.children[0].value]
			  	puts "ERROR - variable #{tree.children[0]} not already defined"
			  	$Failed = true
        		raise JavaSyntaxError
		  	end

		when :print
		  resolveExprType(tree.children[0], env)
    end
    
  end
end

# turns a :type into :int, :boolean, or the string of the id
def resolveType(token)
	if token.type == :int or token.type == :boolean
		token = token.type
	else
		token = token.value
	end
	token
end

class JavaVariable
	@name
	@type

	attr_accessor :type, :name

	def initialize(type)
		@type = type
	end
end

class JavaMethod
	@name
	@args
	@argnames
	@ret
	@location
	@parseTree

	attr_accessor :name, :args, :argnames, :ret, :location, :parseTree

	def initialize()
	end

end

class JavaClass
	@name
	@env
	@parseTree
	@main

	attr_accessor :env, :name, :parseTree, :main

	def initialize()
		@env = Hash.new
		@main = false
	end
end

class JavaSyntaxError < Exception
end

def passes(parse_tree)
	firstPass(parse_tree)
	secondPass
	thirdPass
end

def firstPass(parse_tree)

	#first pass - class prototypes
	classes = Array.new

	#construct list of classes
	classes.push parse_tree.children[0]
	while parse_tree.children.size > 1
		parse_tree = parse_tree.children[1]
		classes.push parse_tree.children[0]
	end

	#Define each class in the global environment
	classes.each { |x|
		name = x.children[0].value

		if $GlobalEnv[name]
			puts "Error - class #{name} already declared"
			  $Failed = true
			next
		end

		$GlobalEnv[name] = JavaClass.new
		$GlobalEnv[name].parseTree = x
	}
end

def secondPass

	#Second pass - define each method and field in the class environments
	$GlobalEnv.each_value { |classObject|
		#For each class

		classObject.name = classObject.parseTree.children[0].value
		classObject.env[:this] = classObject.name

		if classObject.parseTree.name == :MainClassDecl
			classObject.env['main'] = JavaMethod.new()
			classObject.env['main'].args = [:StringArr]
			classObject.env['main'].argnames = [ classObject.parseTree.children[1].value ]
			classObject.env['main'].name = 'main'
			classObject.env['main'].parseTree = classObject.parseTree
			classObject.main = true
			# We don't really have to worry about this very much because you
			# can't ever actually call main because you can't pass it a string
			# array

		
		else
			# Define each field and method in the class's environment

			methodList = Array.new
			classVarList = Array.new


			classObject.parseTree.children.each_index { |i|
				child = classObject.parseTree.children[i]

				if i == 0 # This class's name

				elsif child.type == :id # Class we're extending
					classObject.env[:super] = child.value
					if child.value == classObject.name
						puts "Class #{child.value} can't extend itself"
						$Failed = true
					end

				# Flatten the tree into a list of methods and a list of methods
				elsif child.name == :ClassVarDeclSt
					classVarList.push child.children[0]
					while child.children.size > 1
						child = child.children[1]
						classVarList.push child.children[0]
					end

				elsif child.name == :MethodDeclSt
					methodList.push child.children[0]
					while child.children.size > 1
						child = child.children[1]
						methodList.push child.children[0]
					end
				end
			}


			# Define each class variable
			classVarList.each { |varTree|
				name = varTree.children[1].value
				if classObject.env[name]
					puts "Error - class variable #{name} already declared"
			  $Failed = true
					next
				end

				classObject.env[name] = JavaVariable.new(resolveType(varTree.children[0]))
				classObject.env[name].name = name
			}

			# Define each method
			methodList.each { |methodTree|
				name = methodTree.children[1].value

				if classObject.env[name]
					puts "Error - method #{name} already declared"
			  $Failed = true
					next
				end

				methodObject = JavaMethod.new
				classObject.env[name] = methodObject

				methodObject.name = name
				methodObject.ret = resolveType(methodTree.children[0])
				methodObject.parseTree = methodTree
				methodObject.args = Array.new
				methodObject.argnames = Array.new

				formals = methodTree.children[2]
				unless formals.name == :FormalSt
					# The method has no arguements
					next
				end

				# Flatten into a list of formals
				formalsList = Array.new

				while true
					case formals.name
					
					when :FormalSt
						formals = formals.children[0]

					when :FormalPl
						formalsList.push formals.children[0]

						if(formals.children.size > 1)
							formals = formals.children[1]
						else
							break
						end

					when :Formal
						formalsList.push formals
						break

					end
				end

				formalsList.each { |formal|
					methodObject.args.push resolveType(formal.children[0])
					methodObject.argnames.push formal.children[1].value
				}
			}
		end

		classObject.parseTree = nil
	}
end

def thirdPass

	# Third pass - validate methods
	$GlobalEnv.each_value { |i|

		# Mainclass (and therefore main method)
		if i.main
			method = i.env['main']

			if method.parseTree.children.size > 2
				env = [method.env, Hash.new]
				# No point in binding String[] args because it can't be referenced

				walk(method.parseTree.children[2], env)
			end
			method.parseTree = nil
			next
		end

		# Each method in each class
		i.env.each_value { |j|
			unless j.class == JavaMethod
				next
			end

			# Bind the arguements in the new environment
			env = [i.env, Hash.new]
			j.args.each_index { |k|
				var = JavaVariable.new(j.args[k])
				var.name = j.argnames[k]
				env.last[var.name] = var
			}

			#find the method body
			stmt = nil
			if j.parseTree.children.size > 2
				if j.parseTree.children[1].name == :StmtSt
					stmt = j.parseTree.children[1]
				elsif j.parseTree.children[2].name == :StmtSt
					stmt = j.parseTree.children[2]
				end
			end
			
			#validate the method body
			if stmt
				walk(stmt, env)
			end

			#verify the return type
			unless resolveExprType(j.parseTree.children[-1], env) == j.ret
				puts "Error - method #{j.name} in #{i.name} does not return the correct type"
			  $Failed = true
			end

			j.parseTree = nil
		}
	}


end

def lookup(symbol, env)
	if env == nil
		return $GlobalEnv[symbol]
	end


	if env.last[symbol]
		return env.last[symbol]
	elsif env.size > 1
		return lookup(symbol, env[0..-2])
	elsif env.first[:super]
		return lookup(symbol, [$GlobalEnv[env.first[:super]].env])
	else
		return lookup(symbol, nil)
	end
end

#returns the type given by performing math on two types
def mathTypes(typeA, typeB)
	if typeA == :int
		if typeB == :int or typeB == :boolean
			return :int
		else
			raise JavaSyntaxError
		end
	elsif typeA == :boolean
		if typeB == :boolean
			return :boolean
		elsif typeB == :int
			return :int
		else
			raise JavaSyntaxError
		end
	else
		raise JavaSyntaxError
	end
end

def compileExpr(tree, env)
	case tree.name
	when :Expr9
		case tree.type
		when :new
			return newObject(:acc, $GlobalEnv[tree.value])
		when :id
			return getVar(:acc, tree.value)
		when :this
			return getVar(:acc, :this)
		when :integer
			return writeConstant(:acc, tree.value)
		when :null
			return writeConstant(:acc, 0)
		when :true
			return writeConstant(:acc, 1)
		when :false
			return writeConstant(:acc, 0)
		when :expr
			return compileExpr(tree.children[0], env)
		end

	when :Expr8
		if tree.children.length == 1
			return compileExpr(tree.children[0], env)
		end

		return 'todo'

	when :Expr7
		m = compileExpr(tree.children[0], env)
		if tree.type == :-
			m.simpleMerge invert(:acc)
		elsif tree.type == :!
			m2 = writeConstant(:ra, 0)
			m3 = eq(:ra, :acc)
			m3.mergeTrue writeConstant(:acc, 1)
			m3.mergeFalse writeConstant(:acc, 0)

			m.simpleMerge m2
			m.simpleMerge m3.join
		end

		return m

	when :Expr6
		m = compileExpr(tree.children[0], env)
		
		if tree.children.size == 1
			return m
		end

		m.simpleMerge push(:stack)
		m.simpleMerge copy(:acc, :stack)

		m.simpleMerge compileExpression(tree.children[1], env)

		if tree.type == :/
			return 'todo'
		end

		m.simpleMerge mult(:acc, :stack)
		m.simpleMerge pop(:stack)

		return m
		
	when :Expr5
		m = compileExpr(tree.children[0], env)

		if tree.children.size == 1
			return m
		end

		m.simpleMerge push(:stack)
		m.simpleMerge copy(:acc, :stack)

		m.simpleMerge compileExpression(tree.children[1], env)

		if tree.type == :+
			m.simpleMerge add(:acc, :stack)
		else
			m.simpleMerge sub(:acc, :stack)
		end

		m.simpleMerge pop(:stack)

		return m

	when :Expr4
		m = compileExpr(tree.children[0], env)

		if tree.children.size == 1
			return m
		else
			return 'todo'
		end

	when :Expr3
		m = compileExpr(tree.children[0], env)

		if tree.children.size == 1
			return m
		end

		m.simpleMerge push(:stack)
		m.simpleMerge copy(:acc, :stack)

		m.simpleMerge compileExpression(tree.children[1], env)

		if tree.type == :==
			m2 = eq(:acc, :stack)
			m2.mergeTrue writeConstant(:acc, 1)
			m2.mergeFalse writeConstant(:acc, 0)
			m.simpleMerge m2.join
		else
			m2 = eq(:acc, :stack)
			m2.mergeTrue writeConstant(:acc, 0)
			m2.mergeFalse writeConstant(:acc, 1)
			m.simpleMerge m2.join
		end

		m.simpleMerge pop(:stack)

		return m

	when :Expr2
		m = compileExpr(tree.children[0], env)

		if tree.children.size == 1
			return m
		end

		m.simpleMerge writeConstant(:ra, 0)
		m = eq(:ra, :acc).mergeAfter m
		m.mergeTrue writeConstant(:acc, 0)

		m.mergeFalse compileExpression(tree.children[1], env)

		m2 = eq(:ra, :acc)
		m2.mergeFalse writeConstant(:acc, 1)
		m2.mergeTrue writeConstant(:acc, 0)
		m2 = m2.join

		m.mergeFalse m2

		m = m.join

		return m

	when :Expr
		m = compileExpr(tree.children[0], env)

		if tree.children.size == 1
			return m
		end

		m.simpleMerge writeConstant(:ra, 0)
		m = eq(:ra, :acc).mergeAfter m
		m.mergeFalse writeConstant(:acc, 1)

		m.mergeTrue compileExpression(tree.children[1], env)

		m2 = eq(:ra, :acc)
		m2.mergeTrue writeConstant(:acc, 0)
		m2.mergeFalse writeConstant(:acc, 1)
		m2 = m2.join

		m.mergeTrue m2

		m = m.join

		return m
    
  when :StmtSt
    m = SubMachine.empty 'StmtSt'
    m.simpleMerge compileExpression(tree.children[0])
    m.simpleMerge compileExpression(tree.children[1])
    return m

  when :Stmt
    case tree.type
    when :block
      m = SubMachine.empty 'Stmt: block'
      m.simpleMerge createScope
      m.simpleMerge compileExpression(tree.children[0])
      m.simpleMerge destroyScope
      return m
    when :if
      expr = compileExpression(tree.children[0])
      if_true = compileExpression(tree.children[1])
      if_false = compileExpression(tree.children[2])

      m = writeConstant(:ra, 0)
      m.simpleMerge eq(:acc, :ra)
      m.simpleMergeAfter(expr)
      m.mergeTrue if_false
      m.mergeFalse if_true
      return m.join
    when :while
      m = SubMachine.empty
      m.simpleMerge compileExpr(tree.children[0])
      m.simpleMerge writeConstant(:ra, 0)
      m = eq(:acc, :ra).simpleMergeAfter m
      m.mergeFalse compileExpr(tree.children[1])
      m2 = SubMachine.empty
      link(m.states[m.lastFalse], m2.first)
      m2.simpleMerge m 'Stmt: while'
      link(m.states[m.lastTrue], m2.last)
      return m2
    when :var_asgn
      
    when :var_dec

    end
	end
end






			



def resolveExprType(tree, env)
	case tree.name
	when :Expr, :Expr2, :Expr3, :Expr4, :Expr5, :Expr6
		if tree.children.length == 1
			return resolveExprType(tree.children[0], env)
		end
		a = resolveExprType(tree.children[0], env)
		b = resolveExprType(tree.children[1], env)
		return mathTypes(a, b)

	when :Expr7
		a = resolveExprType(tree.children[0], env)
		if tree.type == '!'
			if a == :int or a == :boolean
				return :boolean
			else
				raise JavaSyntaxError
			end
		elsif tree.type = '-'
			if a == :int or a == :boolean
				return a
			end
		else
			return a
		end

	when :Expr8
		if tree.children.length == 1
			return resolveExprType(tree.children[0], env)
		end

		a = resolveExprType(tree.children[0], env)
		return expr8chain(tree.children[1], a, env)

	when :Expr9
		item = tree.children[0]
		case tree.type
		when :new
			return item.children[0].value
		when :id
      l = lookup(item.value, env)
      if l.nil?
        #variable doesn't exist
        raise JavaSyntaxError
      end
      return l.type
		when :this
      return lookup(:this, env)
		when :integer, :null
			return :int
		when :true, :false
			return :boolean
		when :expr
			return resolveExprType(tree.children[0], env)
		end
  end
  
end

def matchArgs(method, argslist, env)
	if argslist == nil
		if method.args.size == 0
			return true
		else
			return false
		end
	end

	types = Array.new
	while true
		case argslist.name
		when :Expr8St
			argslist = argslist.children[0]
		when :Expr8Pl
			types.push resolveExprType(argslist.children[0], env)
			if(argslist.children.size > 1)
				argslist = argslist.children[1]
			else
				break
			end
		end
	end

	if types.size != method.args.size
		puts "Wrong number of arguements"
			  $Failed = true
		return false
	end

	types.each_index { |i|
		if types[i] != method.args[i]
			return false
		end
	}

	return true
end

def expr8chain(symbol, type, env)
  method = lookup(symbol.children[0].value, env)
  if method.nil?
		puts "Method #{symbol.children[0].value} in #{env.first[:this]} doesn't exist"
			  $Failed = true
		raise JavaSyntaxError
	end

	unless matchArgs(method, symbol.children[1], env)
		puts "Args don't match"
			  $Failed = true
		raise JavaSyntaxError
	end

	type = method.ret
	
	if symbol.children.last.name == :Expr8Pr
		return expr8chain(symbol.children.last, type, env)
	else
		return type
	end
end

if __FILE__ == $PROGRAM_NAME
  source = File.absolute_path(ARGF.filename)
  parse_tree = program(Lexer.get_words(source))
  passes(parse_tree)
  unless $Failed
	  puts "Y'okay!"
  end
end

