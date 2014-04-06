# We can't rely on error checking to chose the rule, even when one of the
# options is epsilon. If we do, we'll discard tokens until we can resume
# applying the room, where we could have gotten epsilon and made a valid tree.

# How do we resolve ID?
require '../lexer/lexer.rb'

First = { :Program => ["class"], :MainClassDecl => ["class"], :ClassDeclSt => ["class", :epsilon],
		  :StmtSt => [:epsilon, "{", "if", "while", "System.out.println", :ID, "int", "boolean"]
}

class ParseTree
	@name
	@children
	@type #represents which rule was chosen; i.e. + or -

	def print
		self.print_recurse(0)
	end

	def print_recurse(depth)
		print ' '*depth
		print @name
		@type && print " (#{type})"

		if @children
			print "\n\\"
			@children.each { |x| x.print_recurse(depth + 1) }
			print "/\n"
		end
	end

end

class InvalidParse < Exception
end

def template(iter)

	# Check for this symbol going to epsilon
	# Only needed if that's valid
	unless checkFirst(:Template, iter.peek)
		if checkFirst(:Template, :epsilon)
			return :epsilon
		end
	end

	# Eat symbols until we find a symbol in this symbol's first set
	begin
		errorCheck(:Template, iter)
	rescue StopIteration
		return :epsilon
	end

	# Initialize the node
	result = ParseTree.new
	result.name = :Template
	result.children = Array.new

	#if getting any tokens
	begin
		#do things
	rescue StopIteration
		# We ran out of input looking for the tokens we need for this production
		puts "Unexpected end of input in Template"
		# This will be propogated up; we can only be here if we're at end of input.
		raise InvalidParse
	end

	# Eliminate children that returned empty string
	result.children.filter { |x| x != :epsilon}
	result
end

def checkFirst(symbol, token)
	firstSet = First[symbol]
	firstSet.each { |x|
		if x.class == String
			if token.value == x
				return true
			end
		else
			if token.token == x
				return true
			end
		end
	}

	false
end

def errorCheck(symbol, iter)
	until checkFirst(symbol, iter.peek)
		puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\", cannot start #{symbol}"
		iter.next
	end
end

def eatThru(symbol, iter)
	while true
		if symbol.class == String && iter.peek.value == symbol
			break
		elsif iter.peek.token == symbol
			break
		else
			puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\""
			iter.next
		end
	end

	iter.next
end


def program(iter)

	begin
		errorCheck(:Program, iter)
	rescue StopIteration
		puts "Unexpected end of input"
		return :epsilon
	end
	
	result = ParseTree.new

	result.name = :Program
	result.children = [mainClassDecl(iter), classDeclSt(iter)]
	result.children.filter! { |x| x != :epsilon }

	result

end

def classDeclSt(iter)

	unless checkFirst(:ClassDecl, iter.peek)
		if checkFirst(:ClassDecl, :epsilon)
			return :epsilon
		end
	end

	begin
		errorCheck(:ClassDeclSt, iter)
	rescue StopIteration
		return :epsilon
	end
	
	result = ParseTree.new
	result.name = :ClassDeclSt

	result.children = [classDecl(iter), classDeclSt(iter)]
	result.children.filter! { |x| x != :epsilon }

	result
end

def mainClassDecl(iter)

	begin
		errorCheck(:mainClassDecl, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :MainClassDecl
	result.children = Array.new

	begin
		eatThru("class", iter)
		result.children.push id(iter)

		eatThru("{")
		eatThru("public")
		eatThru("static")
		eatThru("void")
		eatThru("main")
		eatThru("(")
		eatThru("String")
		eatThru("[")
		eatThru("]")

		result.children.push id(iter)

		eatThru(")")
		eatThru("{")

		result.children.push stmtSt(iter)

		eatThru("}")
		eatThru("}")

	rescue StopIteration
		puts "Unexpected end of input in ClassDecl"
		raise InvalidParse
	end
	
	result.children.filter { |x| x != :epsilon}
	result
end

def stmtSt(iter)

	unless checkFirst(:Stmt, iter.peek)
		if checkFirst(:Stmt, :epsilon)
			return :epsilon
		end
	end

	begin
		errorCheck(:StmtSt, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :StmtSt

	result.children = [stmt(iter), stmtSt(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def ClassDecl(iter)

	begin
		errorCheck(:ClassDecl, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :ClassDecl
	result.children = Array.new

	begin

		eatThru("class", iter)

		child = id(iter)
		result.children.push child

		symbol = iter.peek
		if(symbol.value == "extends")

			eatThru("extends", iter)

			child = id(iter)
			result.children.push child

		end

		eatThru("{", iter)

		result.children.push classVarDeclSt(iter)
		result.children.push methodDeclSt(iter)

		eatThru("}", iter)

	rescue StopIteration
		puts "Unexpected end of input in ClassDecl"
		raise InvalidParse
	end

	result.children.filter { |x| x != :epsilon}
	result
end

def methodDeclSt(iter)

	unless checkFirst(:MethodDecl, iter.peek)
		if checkFirst(:MethodDecl, :epsilon)
			return :epsilon
		end
	end

	begin
		errorCheck(:MethodDeclSt, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :MethodDeclSt

	result.children = [methodDecl(iter), methodDeclSt(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def classVarDeclSt(iter)

	unless checkFirst(:ClassVarDecl, iter.peek)
		if checkFirst(:ClassVarDecl, :epsilon)
			return :epsilon
		end
	end

	begin
		errorCheck(:ClassVarDeclSt, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :ClassVarDeclSt

	result.children = [classVar(iter), classVarSt(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def classVarDecl(iter)

	begin
		errorCheck(:ClassVarDecl, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :ClassVarDecl

	result.children = [type(iter), id(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def methodDecl(iter)

	begin
		errorCheck(:methodDecl, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :methodDecl
	result.children = Array.new

	begin
		eatThru("public", iter)

		result.children.push type(iter)
		result.children.push id(iter)

		eatThru("(", iter)

		result.children.push formalSt(iter)

		eatThru(")", iter)
		eatThru("{", iter)

		result.children.push stmtSt(iter)

		eatThru("return", iter)
		eatThru("}")

	rescue StopIteration
		puts "Unexpected end of input in MethodDecl"
		raise InvalidParse
	end

	result.children.filter { |x| x != :epsilon}
	result
end

def formalSt(iter)

	# Check for this symbol going to epsilon
	# Only needed if that's valid
	unless checkFirst(:FormalSt, iter.peek)
		if checkFirst(:FormalSt, :epsilon)
			return :epsilon
		end
	end

	# Eat symbols until we find a symbol in this symbol's first set
	begin
		errorCheck(:FormalSt, iter)
	rescue StopIteration
		return :epsilon
	end

	# Initialize the node
	result = ParseTree.new
	result.name = :FormalSt
	result.children = formalPl(iter)

	# Eliminate children that returned empty string
	result.children.filter { |x| x != :epsilon}
	result
end

def formalPl(iter)

	# Eat symbols until we find a symbol in this symbol's first set
	begin
		errorCheck(:FormalPl, iter)
	rescue StopIteration
		return :epsilon
	end

	# Initialize the node
	result = ParseTree.new
	result.name = :FormalPl
	result.children = Array.new

	begin
		result.children.push formal(iter)
		
		if iter.peek.value == ','
			eatThru(',', iter)
			result.children.push formalPl(iter)
		end

	rescue StopIteration
		# We ran out of input looking for the tokens we need for this production
		puts "Unexpected end of input in FormalPl"
		# This will be propogated up; we can only be here if we're at end of input.
		raise InvalidParse
	end

	# Eliminate children that returned empty string
	result.children.filter { |x| x != :epsilon}
	result
end

def formal(iter)

	begin
		errorCheck(:Formal, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :Formal

	result.children = [type(iter), id(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def type(iter)

	# Eat symbols until we find a symbol in this symbol's first set
	begin
		errorCheck(:Type, iter)
	rescue StopIteration
		return :epsilon
	end

	# Initialize the node
	result = ParseTree.new
	result.name = :type
	result.children = Array.new

	#if getting any tokens
	begin
		if iter.peek.value == 'int'
			result.type = :int
			eatThru('int', iter)
		elsif iter.peek.value == 'boolean'
			result.type = :boolean
			eatThru('boolean', iter)
		else
			result.type = :id
			result.children = [id(iter)]
		end
	rescue StopIteration
		# We ran out of input looking for the tokens we need for this production
		puts "Unexpected end of input in Type"
		# This will be propogated up; we can only be here if we're at end of input.
		raise InvalidParse
	end

	# Eliminate children that returned empty string
	result.children.filter { |x| x != :epsilon}
	result
end

def stmt(iter)

	# Eat symbols until we find a symbol in this symbol's first set
	begin
		errorCheck(:Stmt, iter)
	rescue StopIteration
		return :epsilon
	end

	# Initialize the node
	result = ParseTree.new
	result.name = :Stmt
	result.children = Array.new

	begin
		if iter.peek.value == '{'
			eatThru('{', iter)
			result.children = [ stmtSt(iter) ]
			eatThru('}', iter)

			result.type = :block
		
		elsif iter.peek.value == 'if'
			eatThru('if', iter)
			eatThru('(', iter)
			result.children.push expr(iter)
			eatThru(')', iter)
			result.children.push stmt(iter)
			eatThru('else', iter)
			result.children.push stmt(iter)

			result.type = :if

		elsif iter.peek.value == 'while'
			eatThru('while', iter)
			eatThru('(', iter)
			result.children.push expr(iter)
			eatThru(')', iter)
			result.children.push stmt(iter)

			result.type = :while

		elsif checkFirst(:Type, iter.peek)
			result.children.push type(iter)
			result.children.push id(iter)
			eatThru('=', iter)
			result.children.push expr(iter)
			eatThru(';', iter)

			result.type = :var_dec

		elsif iter.peek.token == :ID
			result.children.push id(iter)
			eatThru('=', iter)
			result.children.push expr(iter)
			eatThru(';', iter)

			result.type = :var_asgn
		
		else
			eatThru('System.out.println', iter)
			eatThru('(', iter)
			result.children.push expr(iter)
			eatThru(')', iter)
			eatThru(';', iter)
		end

	rescue StopIteration
		# We ran out of input looking for the tokens we need for this production
		puts "Unexpected end of input in Stmt"
		# This will be propogated up; we can only be here if we're at end of input.
		raise InvalidParse
	end

	# Eliminate children that returned empty string
	result.children.filter { |x| x != :epsilon}
	result
end

# These aren't nonterminals, but I think we should pretend they are so that we
# can encapsulate thier values
def id(iter)
end

def integer(iter)
end
