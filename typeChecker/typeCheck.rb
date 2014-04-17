require "../parser/parser.rb"
require "../lexer/lexer.rb"

def getType(tree)
  :int
end

class Variable
	@type

	attr_accessor :type

	def initailize(type)
		@type = type
	end
end

class Method
	@arguements
	@returnValue
	@location

	attr_accessor :arguments, :returnValue, :location

	def initialize(args, ret, loc)
		@arguements = args
		@returnValue = ret
		@location = loc
	end

	def initialize()
		@arguements = Array.new
	end

end

class SyntaxError < Exception
end

def lookup(symbol, env)
	if env.last[symbol]
   		return env.last[symbol]
	end

	if env.length > 2
		a = lookup(symbol, env[0..-2])
		return a if a
	end

	if env.last[:super]
		a = lookup(symbol, lookup(env.last[:super], [env.first]))
		return a if a
	end

	if env.first[symbol]
		return env.first[symbol]
	end

	return nil
end

				
#turns a type token into int, boolean, or a name
def resolveType(token)
	if token.type == :int or token.type == :bool
		token = token.type
	else
		token = token.children[0].value
	end
	token
end

#returns the type given by performing math on two types
def mathTypes(typeA, typeB)
	if typeA == :int
		if typeB == :int or typeB == :bool
			return :int
		else
			raise SyntaxError
		end
	elsif typeA == :bool
		if typeB == :bool
			return :bool
		elsif typeB == :int
			return :int
		else
			raise SyntaxError
		end
	else
		raise SyntaxError
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
			if a == :int or a == :bool
				return :bool
			else
				raise SyntaxError
			end
		elsif tree.type = '-'
			if a == :int or a == :bool
				return a
			end
		else
			return a
		end

	when :Expr8
		if tree.children.length == 1
			return resolveExprType(tree.children[0], env)
		end
		# oh my this will be complicated
		# this is where we have to verify methods are called with correct args

	when :Expr9
		item = tree.children[0]
		case item.type
		when :new
			return item.children[0].value
		when :id
			return lookup(item.value, env)
		when :this
			return lookup(
		when :Integer, :null
			return :int
		when :true, false
			return :bool
		when :expr
			return resolveExprType(tree.children[0], env)
		end
	end
end

def walk(tree, tables)
  if not tree
    return
  end
  case tree.name
  when :Program
    env = [{}]
    tree.children.each { |c| walk(c, env) }
  when :ClassDeclSt
    tree.children.each { |c| walk(c, tables) }
  when :MainClassDecl
    tables << {}
    #ignoring String[] ID since it can't be referenced...ever
    walk(tree.children[2], tables)
    t = tables.pop
    tables.last[tree.children[0].value] = t
    p tables

  when :StmtSt
    tree.children.each { |c| walk(c, tables) }
  when :ClassDecl
    if tree.children.length > 1 and tree.children[1].type == :id
      #extending class
      if not tables.last[tree.children[1].value]
        puts "ERROR"
      end
      tables << {}
      tables.last[:super] = tree.children[1].value
    else
      tables << {}
    end
    tree.children.each { |c|
      unless c.name == :id
        walk(c, tables)
      end }
    env = tables.pop
    tables.last[tree.children[0].value] = env
    p tables
  when :MethodDeclSt
    tree.children.each { |c| walk(c, tables) }
  when :ClassVarDeclSt
    tree.children.each { |c| walk(c, tables) }
  when :MethodDecl
    tables << {}
    tree.children[1..-1].each { |c| walk(c, tables) }
    ret = resolveType(tree.children[0])
	method = Method.new
	method.returnValue = ret


	unless ret == resolveTypeExpr(tree.children[-1], tables)
      puts tree.children[0].name
      puts "MethodDecl ERROR"
    end
    tables.pop

	formal = tree.children[2]
	while true
		case formal.name
		when :FormalSt
			if formal.children.size > 0
				formal = formal.children[0]
			else
				break
			end
		when :FormalPl
			method.arguements.push resolveType(formal.children[0].children[0])
			formal = formal.children[1]
		when :Formal
			method.arguements.push resolveType(formal.children[0].children[0])
		end
	end

    tables.last[tree.children[1].value] = :methodGoesHere
  when :ClassVarDecl
	  if tables.last[tree.children[0].value]
		  puts "ERROR - variable #{tree.children[0]} already defined"
	  end

	  tables.last[tree.children[0].value] = Variable.new(resolveType(tree.children[1]))
    
  when :FormalSt
    tree.children.each { |c| walk(c, tables) }

  when :FormalPl
	  tree.children.each { |c| walk(c, tables) }
    
  when :Formal
	  tables.last[tree.children[0].value] = Variable.new(resolveType(tree.children[1]))

  when :Type
	  #We shouldn't ever get here
	  puts "ERROR - I don't even know"
    
  when :Stmt
	  case tree.type
	  when :block
		  tables << {}
		  tree.children.each { |c| walk(c, tables) }
		  tables.pop
	  
	  when :if, :while
		  tree.children.each { |c| walk(c, tables) }

	  when :var_dec
		  unless resolveType(tree.children[0]) == resolveTypeExpr(tree.children[2])
			  puts "Error - that expression doesn't make that type"
		  end

		  if tables.last[tree.children[1].value]
			  puts "ERROR - variable #{tree.children[1]} already defined"
		  end

		  var = Variable.new(resolveType(tree.children[0]))

		  tables.last[tree.children[1].value] = var

	  when :var_asgn

		  unless lookup(tree.children[0].value, env).type == resolveTypeExpr(tree.children[1])
			  puts "Error - that expression doesn't make that type"
		  end

		  unless tables.last[tree.children[0].value]
			  puts "ERROR - variable #{tree.children[0]} not already defined"
		  end

	  when :print
		  resolveExprType(tree.children[0], tables)
	end
    
  end
end



if __FILE__ == $PROGRAM_NAME
  source = File.absolute_path(ARGF.filename)
  parse_tree = program(Lexer.get_words(source))
  walk(parse_tree, nil)
end

