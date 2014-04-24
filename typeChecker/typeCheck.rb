require_relative "../parser/parser.rb"
require_relative  "../lexer/lexer.rb"

GlobalEnv = Hash.new
failed = false

def walk(tree, env)
	if not tree
		return
	end

	case tree.name
	when :Program, :ClassDeclSt, :ClassDecl, :MethodDeclSt, :ClassVarDeclSt, :MainClassDecl, :MethodDecl, :ClassVarDecl, :FormalSt, :FormalPl, :Formal, :Type
		puts "Shouldn't happen" #handled by earlier passes
		failed = true

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
			  failed = true

        raise JavaSyntaxError
		  end

		  if env.last[tree.children[1].value]
			  puts "ERROR - variable #{tree.children[1]} already defined"
			  failed = true
        raise JavaSyntaxError
		  end

		  var = JavaVariable.new(resolveType(tree.children[0]))

		  env.last[tree.children[1].value] = var

	  when :var_asgn

		  unless lookup(tree.children[0].value, env).type == resolveTypeExpr(tree.children[1])
			  puts "Error - that expression doesn't make that type"
			  failed = true
        raise JavaSyntaxError
		  end

		  unless env.last[tree.children[0].value]
			  puts "ERROR - variable #{tree.children[0]} not already defined"
			  failed = true
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

		if GlobalEnv[name]
			puts "Error - class #{name} already declared"
			  failed = true
			next
		end

		GlobalEnv[name] = JavaClass.new
		GlobalEnv[name].parseTree = x
	}




	#Second pass - define each method and field in the class environments
	GlobalEnv.each_value { |classObject|
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
			  failed = true
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
			  failed = true
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

	# Third pass - validate methods
	GlobalEnv.each_value { |i|

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
				puts "Error - method #{j.name} does not return the correct type"
			  failed = true
			end

			j.parseTree = nil
		}
	}


end

def lookup(symbol, env)
	if env == nil
		return GlobalEnv[symbol]
	end


	if env.last[symbol]
		return env.last[symbol]
	elsif env.size > 1
		return lookup(symbol, env[0..-2])
	elsif env.first[:super]
		return lookup(symbol, [env.first[:super].env])
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
			  failed = true
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
		puts "Method #{symbol.children[0].value} doesn't exist"
			  failed = true
		raise JavaSyntaxError
	end

	unless matchArgs(method, symbol.children[1], env)
		puts "Args don't match"
			  failed = true
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
  unless failed
	  puts "Y'okay!"
  end
end

