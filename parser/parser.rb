# We can't rely on error checking to chose the rule, even when one of the
# options is epsilon. If we do, we'll discard tokens until we can resume
# applying the room, where we could have gotten epsilon and made a valid tree.
require '../lexer/lexer.rb'

First = { :Program => ["class"], :MainClassDecl => ["class"], :ClassDeclSt => ["class", :epsilon],
		  :StmtSt => [:epsilon, "{", "if", "while", "System.out.println", :ID, "int", "boolean"]
}

class ParseTree
	@name
	@children
	@type #represents which rule was chosen; i.e. + or -
end

class InvalidParse < Exception
end

def template(iter)

	# Check for this symbol going to epsilon
	unless checkFirst(:ClassDecl, iter.peek)
		if checkFirst(:ClassDecl, :epsilon)
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

def classVarSt(iter)

	begin
		errorCheck(:ClassVarSt, iter)
	rescue StopIteration
		return :epsilon
	end

	result = ParseTree.new
	result.name = :ClassVarSt

	result.children = [classVar(iter), classVarSt(iter)]

	result.children.filter { |x| x != :epsilon}
	result
end

def ClassVarDecl(iter)

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
