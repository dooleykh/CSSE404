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
	end

end

class SyntaxError < Exception
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

def resolveExprType(tree)
	case tree.name
	when :Expr, :Expr2, :Expr3, :Expr4, :Expr5, :Expr6
		if tree.children.length == 1
			return resolveExprType(tree.children[0])
		end
		a = resolveExprType(tree.children[0])
		b = resolveExprType(tree.children[1])
		return mathTypes(a, b)

	when :Expr7
		a = resolveExprType(tree.children[0])
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
			return resolveExprType(tree.children[0])
		end
		# oh my this will be complicated


			

##true for int, bool, false for methods, classes
#def canMath(token)
#	i = resolveType(token)
#	return i==:int or i==:bool
#end

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
    #Note: write functions for checking types
    ret = resolveType(tree.children[0])

    #if ret.type == :int or ret.type == :bool
    #  ret = ret.type
    #else
    #  ret = ret.children[0].value
    #end

    unless ret == getType(tree.children[-1])
      puts tree.children[0].name
      puts "MethodDecl ERROR"
    end
    tables.pop
    tables.last[tree.children[1].value] = :methodGoesHere
  when :ClassVarDecl
	  if tables.last[tree.children[0]]
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
	  #complicated
    
  when :Program
    
    
  end
end


if __FILE__ == $PROGRAM_NAME
  source = File.absolute_path(ARGF.filename)
  parse_tree = program(Lexer.get_words(source))
  walk(parse_tree, nil)
end

