require_relative "../parser/parser.rb"
require_relative  "../lexer/lexer.rb"

#def getType(tree)
#  :int
#end

#
#def lookup(symbol, env)
#  if env.nil?
#    return nil
#  end
#
#  if symbol == "this"
#  end
#  if env.last[symbol]
#    return env.last[symbol]
#	end
#
#	if env.length > 2
#		a = lookup(symbol, env[0..-2])
#		return a if a
#	end
#
#	if env.last[:super]
#    a = lookup(symbol, [env.first, lookup(env.last[:super], [env.first])])
#    return a if a
#	end
#
#	if env.first[symbol]
#		return env.first[symbol]
#	end
#
#	return nil
#end
#
#
##turns a type token into int, boolean, or a name
#def resolveType(token)
#	if token.type == :int or token.type == :boolean
#		token = token.type
#	else
#		token = token.value
#	end
#	token
#end
#
##returns the type given by performing math on two types
#def mathTypes(typeA, typeB)
#	if typeA == :int
#		if typeB == :int or typeB == :boolean
#			return :int
#		else
#			raise JavaSyntaxError
#		end
#	elsif typeA == :boolean
#		if typeB == :boolean
#			return :boolean
#		elsif typeB == :int
#			return :int
#		else
#			raise JavaSyntaxError
#		end
#	else
#		raise JavaSyntaxError
#	end
#end
#
#def matchArgs(method, exprls, env)
#	return true
#end
#
#def expr8chain(symbol, type, env)
#  method = lookup(symbol.children[0].value, env)
#  if method.nil?
#		puts "Method #{symbol.children[0].value} doesn't exist"
#		raise JavaSyntaxError
#	end
#
#	unless matchArgs(method, symbol.children[1], env)
#		puts "Args don't match"
#		raise JavaSyntaxError
#	end
#
#	type = method.returnValue
#	
#	if symbol.children.last.name == :Expr8Pr
#		return expr8chain(symbol.children.last, type, env)
#	else
#		return type
#	end
#end
#
#
#def resolveExprType(tree, env)
#	case tree.name
#	when :Expr, :Expr2, :Expr3, :Expr4, :Expr5, :Expr6
#		if tree.children.length == 1
#			return resolveExprType(tree.children[0], env)
#		end
#		a = resolveExprType(tree.children[0], env)
#		b = resolveExprType(tree.children[1], env)
#		return mathTypes(a, b)
#
#	when :Expr7
#		a = resolveExprType(tree.children[0], env)
#		if tree.type == '!'
#			if a == :int or a == :boolean
#				return :boolean
#			else
#				raise JavaSyntaxError
#			end
#		elsif tree.type = '-'
#			if a == :int or a == :boolean
#				return a
#			end
#		else
#			return a
#		end
#
#	when :Expr8
#		if tree.children.length == 1
#			return resolveExprType(tree.children[0], env)
#		end
#
#		a = resolveExprType(tree.children[0], env)
#		return expr8chain(tree.children[1], a, env)
#
#	when :Expr9
#		item = tree.children[0]
#		case tree.type
#		when :new
#			return item.children[0].value
#		when :id
#      l = lookup(item.value, env)
#      if l.nil?
#        #variable doesn't exist
#        raise JavaSyntaxError
#      end
#      return l.type
#		when :this
#      return lookup(:this, env)
#		when :integer, :null
#			return :int
#		when :true, :false
#			return :boolean
#		when :expr
#			return resolveExprType(tree.children[0], env)
#		end
#  end
#  
#end
#
#def walk(tree, tables)
#  if not tree
#    return
#  end
#  case tree.name
#  when :Program
#    env = [{}]
#    tree.children.each { |c| walk(c, env) }
#  when :ClassDeclSt
#    tree.children.each { |c| walk(c, tables) }
#  when :MainClassDecl
#    tables << {}
#    #ignoring String[] ID since it can't be referenced...ever
#    walk(tree.children[2], tables)
#    t = tables.pop
#    tables.last[tree.children[0].value] = t
#  when :StmtSt
#    tree.children.each { |c| walk(c, tables) }
#  when :ClassDecl
#    if tree.children.length > 1 and tree.children[1].type == :id
#      #extending class
#      if not tables.last[tree.children[1].value]
#        puts "ERROR"
#        raise JavaSyntaxError
#      end
#      tables << {}
#      tables.last[:super] = tree.children[1].value
#    else
#      tables << {}
#    end
#        tables.last[:this] = tables.last
#    tree.children.each { |c|
#      unless c.name == :id
#        walk(c, tables)
#      end }
#    env = tables.pop
#    tables.last[tree.children[0].value] = env
#  when :MethodDeclSt
#    tree.children.each { |c| walk(c, tables) }
#  when :ClassVarDeclSt
#    tree.children.each { |c| walk(c, tables) }
#  when :MethodDecl
#    if tables.last[tree.children[1].value]
#      #method exists. Throw
#      raise JavaSyntaxError
#    end
#    if tables.last[:super]
#      l = lookup(tree.children[1], tables) 
#      if l
#        unless l.is_a?(JavaMethod) && l.type == resolveType(tree.children[0])
#          puts "HELP ERROR"
#          raise JavaSyntaxError
#        end
#      end
#    end
#    formal = tree.children[2]
#    if formal.name == :FormalSt
#      while true
#        case formal.name
#        when :FormalSt
#          if formal.children.size > 0
#            formal = formal.children[0]
#          else
#            break
#          end
#        when :FormalPl
#          method.arguements.push resolveType(formal.children[0].children[0])
#          formal = formal.children[1]
#        when :Formal
#          method.arguements.push resolveType(formal.children[0].children[0])
#        end
#      end
#    end
#
#    ret = resolveType(tree.children[0])
#    method = JavaMethod.new
#    method.returnValue = ret
#
#    tables.last[tree.children[1].value] = method
#    unless ret == resolveExprType(tree.children[-1], tables)
#      # p ret
#      # p resolveExprType(tree.children[-1], tables)
#      # puts tree.children[-1].name
#      puts "MethodDecl ERROR"
#      raise JavaSyntaxError
#    end
#
#    tables << {}
#    tree.children[1..-1].each { |c| walk(c, tables) }
#
#
#    tables.pop
#
#  when :ClassVarDecl
#    unless lookup(tree.children[1].value, tables).nil?
#		  puts "ERROR - variable #{tree.children[0]} already defined"
#      raise JavaSyntaxError
#	  end
#
#	  tables.last[tree.children[1].value] = Variable.new(resolveType(tree.children[0]))
#  when :FormalSt
#    tree.children.each { |c| walk(c, tables) }
#
#  when :FormalPl
#	  tree.children.each { |c| walk(c, tables) }
#    
#  when :Formal
#	  tables.last[tree.children[0].value] = Variable.new(resolveType(tree.children[1]))
#
#  when :Type
#	  #We shouldn't ever get here
#	  puts "ERROR - I don't even know"
#		raise JavaSyntaxError
#    
#  when :Stmt
#	  case tree.type
#	  when :block
#		  tables << {}
#		  tree.children.each { |c| walk(c, tables) }
#		  tables.pop
#      
#	  when :if, :while
#        tree.children.each { |c| walk(c, tables) }
#
#	  when :var_dec
#		  unless resolveType(tree.children[0]) == resolveExprType(tree.children[2], tables)
#			  puts "Error - that expression doesn't make that type"
#        raise JavaSyntaxError
#		  end
#
#		  if tables.last[tree.children[1].value]
#			  puts "ERROR - variable #{tree.children[1]} already defined"
#        raise JavaSyntaxError
#		  end
#
#		  var = Variable.new(resolveType(tree.children[0]))
#
#		  tables.last[tree.children[1].value] = var
#
#	  when :var_asgn
#
#		  unless lookup(tree.children[0].value, env).type == resolveTypeExpr(tree.children[1])
#			  puts "Error - that expression doesn't make that type"
#        raise JavaSyntaxError
#		  end
#
#		  unless tables.last[tree.children[0].value]
#			  puts "ERROR - variable #{tree.children[0]} not already defined"
#        raise JavaSyntaxError
#		  end
#
#	  when :print
#		  resolveExprType(tree.children[0], tables)
#    end
#    
#  end
#end

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

	attr_accessor :env, :name, :parseTree

	def initialize()
		@env = Hash.new
	end
end

class JavaSyntaxError < Exception
end

GlobalEnv = Hash.new

def walk(parse_tree)

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
			next
		end

		GlobalEnv[name] = JavaClass.new
		GlobalEnv[name].parseTree = x
	}




	#Second pass - define each method and field in the class environments
	GlobalEnv.each_value { |classObject|
		#For each class

		classObject.name = classObject.parseTree.children[0].value

		if classObject.parseTree.name == :MainClassDecl
			classObject.env['main'] = JavaMethod.new()
			classObject.env['main'].args = [:StringArr]
			classObject.env['main'].argnames = [ classObject.parseTree.children[1].value ]
			classObject.env['main'].name = 'main'
			classObject.env['main'].parseTree = classObject.parseTree.children[2]
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



if __FILE__ == $PROGRAM_NAME
  source = File.absolute_path(ARGF.filename)
  parse_tree = program(Lexer.get_words(source))
  walk(parse_tree)
  p GlobalEnv
end

