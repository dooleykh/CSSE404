#module Parser
  
  require_relative '../lexer/lexer.rb'

  First = {
    :Program => ["class"],
    :ClassDeclSt => ["class", :epsilon],
    :MainClassDecl => ["class"],
    :StmtSt => [:epsilon, "{", "if", "while", "System.out.println", :ID, "int", "boolean"],
    :ClassDecl => ["class"], :MethodDeclSt => [:epsilon, "public"],
    :MethodDeclSt => [:epsilon, "public"],
    :ClassVarDeclSt => [:epsilon, "int", "boolean", :ID],
    :MethodDecl => ["public"],
    :ClassVarDecl => ["int", "boolean", :ID],
    :MethodDecl => ["public"],
    :FormalSt => [:epsilon, "int", "boolean", :ID],
    :FormalPl => ["int", "boolean", :ID],
    :Formal => ["int", "boolean", :ID],
    :Type => ["int", "boolean", :ID],
    :Stmt => ["{", "if", "while", "System.out.println", :ID, "int", "boolean"],
    :Expr => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr2 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr3 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr4 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr5 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr6 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr7 => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr8 => ["new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr8St => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr8Pr => ["."],
    :Expr8Pl => ["-", "!", "new", :ID, "this", :Integer, "null", "true", "false", "("],
    :Expr9 => ["new", :ID, "this", :Integer, "null", "true", "false", "("]
  }

  class ParseTree
    @name
    @children
    @type #represents which rule was chosen; i.e. + or -

    attr_accessor :name, :children, :type
    def prin
      self.print_recurse(0, false)
    end

    def print_recurse(depth, sameline)
      #puts "depth: #{depth}"
      unless sameline
        print '|'*depth
      end

      print @name
      if @type
        print " (#{type})"
      end

      if @children
        if @children.size == 1
          print " -> "
          @children[0].print_recurse(depth, true)

        else
          puts
          @children.each { |x|
			  print '|'
            x.print_recurse(depth + 1, false) }
        end
      else
        puts
      end
    end

	def size
		if @children.size == 0
			return 1
		end

		i = 0
		@children.each{ |c|
			i += c.size
		}

		return i
	end

  end

  # for ints and ids
  class ParseNode < ParseTree
    @value
    attr_accessor :value
    def print_recurse(depth, sameline)

      unless sameline
        print '|'*depth
      end

      print @name
      if @type
        puts " (#{@type}): #{@value}"
      end

    end

	def size
		return 1
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
      puts "Unexpected end of input in Template"
      raise InvalidParse
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
    result.children.select! { |x| x != :epsilon}
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
      puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\" on line #{iter.peek.line_num}, cannot start #{symbol}"
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
        puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\", looking for #{symbol} around #{iter.peek.line_num} in caller #{caller[0]}"
        iter.next
      end
    end

    iter.next
  end


  def program(iter)

    begin
      errorCheck(:Program, iter)
    rescue StopIteration
      puts "Unexpected end of input in Program"
      raise InvalidParse
    end
    
    result = ParseTree.new

    result.name = :Program
    result.children = [mainClassDecl(iter), classDeclSt(iter)]
    result.children.select! { |x| x != :epsilon }

    result

  end

  def classDeclSt(iter)

    begin
      unless checkFirst(:ClassDecl, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    begin
      errorCheck(:ClassDeclSt, iter)
    rescue StopIteration
      puts "Unexpected end of input in ClassDeclSt"
      raise InvalidParse
    end
    
    result = ParseTree.new
    result.name = :ClassDeclSt

    result.children = [classDecl(iter), classDeclSt(iter)]
    result.children.select! { |x| x != :epsilon }

    result
  end

  def mainClassDecl(iter)

    begin
      errorCheck(:MainClassDecl, iter)
    rescue StopIteration
      puts "Unexpected end of input in MainClassDecl"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :MainClassDecl
    result.children = Array.new

    begin
      eatThru("class", iter)
      result.children.push id(iter)

      eatThru("{", iter)
      eatThru("public", iter)
      eatThru("static", iter)
      eatThru("void", iter)
      eatThru("main", iter)
      eatThru("(", iter)
      eatThru("String", iter)
      eatThru("[", iter)
      eatThru("]", iter)

      result.children.push id(iter)
      
      eatThru(")", iter)
      eatThru("{", iter)

      result.children.push stmtSt(iter)

      eatThru("}", iter)
      eatThru("}", iter)

    rescue StopIteration
      puts "Unexpected end of input in ClassDecl"
      raise InvalidParse
    end
    
    result.children.select! { |x| x != :epsilon}
    result
  end

  def stmtSt(iter)

    begin
      unless checkFirst(:StmtSt, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    begin
      errorCheck(:StmtSt, iter)
    rescue StopIteration
      puts "Unexpected end of input in StmtSt"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :StmtSt

    result.children = [stmt(iter), stmtSt(iter)]

    result.children.select! { |x| x != :epsilon}
    result
  end

  def classDecl(iter)

    begin
      errorCheck(:ClassDecl, iter)
    rescue StopIteration
      puts "Unexpected end of input in ClassDecl"
      raise InvalidParse
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

    result.children.select! { |x| x != :epsilon}
    result
  end

  def methodDeclSt(iter)

    begin
      unless checkFirst(:MethodDeclSt, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    begin
      errorCheck(:MethodDeclSt, iter)
    rescue StopIteration
      puts "Unexpected end of input in MethodDeclSt"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :MethodDeclSt

    result.children = [methodDecl(iter), methodDeclSt(iter)]

    result.children.select! { |x| x != :epsilon}
    result
  end

  def classVarDeclSt(iter)

    begin
      unless checkFirst(:ClassVarDecl, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    begin
      errorCheck(:ClassVarDeclSt, iter)
    rescue StopIteration
      puts "Unexpected end of input in ClassVarDeclSt"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :ClassVarDeclSt

    result.children = [classVarDecl(iter), classVarDeclSt(iter)]

    result.children.select! { |x| x != :epsilon}
    result
  end

  def classVarDecl(iter)

    begin
      errorCheck(:ClassVarDecl, iter)
    rescue StopIteration
      puts "Unexpected end of input in ClassVarDecl"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :ClassVarDecl

    result.children = [type(iter), id(iter)]
    eatThru(";", iter)

    result.children.select! { |x| x != :epsilon}
    result
  end

  def methodDecl(iter)

    begin
      errorCheck(:MethodDecl, iter)
    rescue StopIteration
      puts "Unexpected end of input in MethodDecl"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :MethodDecl
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
      result.children.push expr(iter)
      eatThru(";", iter)
      eatThru("}", iter)

    rescue StopIteration
      puts "Unexpected end of input in MethodDecl"
      raise InvalidParse
    end

    result.children.select! { |x| x != :epsilon}
    result
  end

  def formalSt(iter)

    begin
      unless checkFirst(:FormalSt, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:FormalSt, iter)
    rescue StopIteration
      puts "Unexpected end of input in FormalSt"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :FormalSt
    result.children = [formalPl(iter)]

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def formalPl(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:FormalPl, iter)
    rescue StopIteration
      puts "Unexpected end of input in FormalPl"
      raise InvalidParse
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
    result.children.select! { |x| x != :epsilon}
    result
  end

  def formal(iter)

    begin
      errorCheck(:Formal, iter)
    rescue StopIteration
      puts "Unexpected end of input in Formal"
      raise InvalidParse
    end

    result = ParseTree.new
    result.name = :Formal

    result.children = [type(iter), id(iter)]

    result.children.select! { |x| x != :epsilon}
    result
  end

  def type(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Type, iter)
    rescue StopIteration
      puts "Unexpected end of input in Type"
      raise InvalidParse
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
      elsif
        result.type = :id
        result.children = [id(iter)]
      else
        puts "Malformed type"
        raise InvalidParse
      end
    rescue StopIteration
      # We ran out of input looking for the tokens we need for this production
      puts "Unexpected end of input in Type"
      # This will be propogated up; we can only be here if we're at end of input.
      raise InvalidParse
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def stmt(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Stmt, iter)
    rescue StopIteration
      puts "Unexpected end of input in Stmt"
      raise InvalidParse
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

      elsif iter.peek.token == :ID
        result.children.push id(iter)

        if iter.peek.value == "="
          eatThru("=", iter)
          result.children.push expr(iter)
          eatThru(";", iter)
          result.type = :var_asgn
        elsif iter.peek.token == :ID
          result.children.push id(iter)
          eatThru("=", iter)
          result.children.push expr(iter)
          eatThru(";", iter)
          result.type = :var_dec
        else
          #Error
        end

      elsif iter.peek.value == "boolean" or iter.peek.value == "int"
        result.children.push type(iter)
        result.children.push id(iter)
        eatThru("=", iter)
        result.children.push expr(iter)
        eatThru(";", iter)
        result.type = :var_dec
        
      elsif iter.peek.value == "System.out.println"
        eatThru('System.out.println', iter)
        eatThru('(', iter)
        result.children.push expr(iter)
        eatThru(')', iter)
        eatThru(';', iter)
        result.type = :print

      else
        puts "Malformed Stmt"
        raise InvalidParse
      end

    rescue StopIteration
      # We ran out of input looking for the tokens we need for this production
      puts "Unexpected end of input in Stmt"
      # This will be propogated up; we can only be here if we're at end of input.
      raise InvalidParse
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr
    result.children = Array.new

    result.children.push expr2(iter)
    begin
      if iter.peek.value == '||'
        eatThru('||', iter)
        result.children.push expr(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr2(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr2, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr2"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr2
    result.children = Array.new

    result.children.push expr3(iter)
    begin
      if iter.peek.value == '&&'
        eatThru('&&', iter)
        result.children.push expr2(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr3(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr3, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr3"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr3
    result.children = Array.new

    result.children.push expr4(iter)
    begin
      if iter.peek.value == '=='
        eatThru('==', iter)
        result.type = :eq
        result.children.push expr3(iter)
      elsif iter.peek.value == '!='
        eatThru('!=', iter)
        result.type = :neq
        result.children.push expr3(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr4(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr4, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr4"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr4
    result.children = Array.new

    result.children.push expr5(iter)
    begin
      if iter.peek.value == '<'
        eatThru('<', iter)
        result.type = :<
        result.children.push expr4(iter)
      elsif iter.peek.value == '>'
        eatThru('>', iter)
        result.type = :>
        result.children.push expr4(iter)
      elsif iter.peek.value == '<='
        eatThru('<=', iter)
        result.type = :<=
          result.children.push expr4(iter)
      elsif iter.peek.value == '>='
        eatThru('>=', iter)
        result.type = :>=
          result.children.push expr4(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr5(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr5, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr5"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr5
    result.children = Array.new

    result.children.push expr6(iter)
    begin
      if iter.peek.value == '+'
        eatThru('+', iter)
        result.type = :+
        result.children.push expr5(iter)
      elsif iter.peek.value == '-'
        eatThru('-', iter)
        result.type = :-
        result.children.push expr5(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr6(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr6, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr6"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr6
    result.children = Array.new

    result.children.push expr7(iter)
    begin
      if iter.peek.value == '*'
        eatThru('*', iter)
        result.type = :*
        result.children.push expr6(iter)
      elsif iter.peek.value == '/'
        eatThru('/', iter)
        result.type = :/
        result.children.push expr6(iter)
      end
    rescue
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr7(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr7, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr7"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr7
    result.children = Array.new

    begin
      if iter.peek.value == '-'
        eatThru('-', iter)
        result.type = :-
        result.children.push expr7(iter)
      elsif iter.peek.value == '!'
        eatThru('!', iter)
        result.type = :!
        result.children.push expr7(iter)
      else
        result.children.push expr8(iter)
      end
    rescue StopIteration
      puts "Value: #{iter.peek.value}"
      puts "Unexpected end of input in Expr7"
      raise InvalidParse
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr8(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr8, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr8"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr8
    result.children = Array.new

    result.children.push expr9(iter)
    result.children.push expr8Pr(iter)

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr8Pr(iter)
    begin
      unless checkFirst(:Expr8Pr, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    begin
      errorCheck(:Expr8Pr, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr8Pr"
      raise InvalidParse
    end

    result = ParseTree.new
    result.children = []
	result.name = :Expr8Pr
    eatThru(".", iter)
    result.children.push id(iter)
    eatThru("(", iter)
    result.children.push expr8St(iter)
    eatThru(")", iter)
    result.children.push expr8Pr(iter)
    result.children.select! { |x| x != :epsilon }
    result
  end

  def expr8St(iter)

    begin
      unless checkFirst(:Expr8St, iter.peek)
        return :epsilon
      end
    rescue StopIteration
      return :epsilon
    end

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr8St, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr8St"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr8St
    result.children = Array.new

    result.children.push expr8Pl(iter)

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr8Pl(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr8Pl, iter)
    rescue StopIteration
      puts "Unexpected end of input in expr8Pl"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr8Pl
    result.children = Array.new

    result.children.push expr(iter)
    begin
      if iter.peek.value == ','
        eatThru(',', iter)
        result.children.push expr8Pl(iter)
      end
    rescue StopIteration
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  def expr9(iter)

    # Eat symbols until we find a symbol in this symbol's first set
    begin
      errorCheck(:Expr9, iter)
    rescue StopIteration
      puts "Unexpected end of input in Expr9"
      raise InvalidParse
    end

    # Initialize the node
    result = ParseTree.new
    result.name = :Expr9
    result.children = Array.new

    begin
      if iter.peek.value == 'new'
        eatThru('new', iter)
        result.children.push id(iter)
        eatThru('(', iter)
        eatThru(')', iter)
        result.type = :new
      elsif iter.peek.token == :ID
        result.children.push id(iter)
        result.type = :id
      elsif iter.peek.value == 'this'
        eatThru('this', iter)
        result.type = :this
      elsif iter.peek.token == :Integer
        result.children.push integer(iter)
        result.type = :integer
      elsif iter.peek.value == 'null'
        eatThru('null', iter)
        result.type = :null
      elsif iter.peek.value == 'true'
        eatThru('true', iter)
        result.type = :true
      elsif iter.peek.value == 'false'
        eatThru('false', iter)
        result.type = :false
      elsif iter.peek.value == '('
        eatThru('(', iter)
        result.children.push expr(iter)
        eatThru(')', iter)
		result.type = :expr
      else
        puts "Malformed Expr9"
        raise InvalidParse
      end
      #do things
    rescue StopIteration
      # We ran out of input looking for the tokens we need for this production
      puts "Unexpected end of input in Template"
      # This will be propogated up; we can only be here if we're at end of input.
      raise InvalidParse
    end

    # Eliminate children that returned empty string
    result.children.select! { |x| x != :epsilon}
    result
  end

  # These aren't nonterminals, but I think we should pretend they are so that we
  # can encapsulate thier values
  def id(iter)
    until iter.peek.token == :ID
      puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\", expecting id"
      iter.next
    end

    result = ParseNode.new
    result.type = :id
    result.value = iter.next.value

    result
  end

  def integer(iter)
    until iter.peek.token == :Integer
      puts "UNHAPPY: ignored #{iter.peek.token}: \"#{iter.peek.value}\", expecting integer"
      iter.next
    end

    result = ParseNode.new
    result.type = :integer
    result.value = iter.next.value
    
    result
  end

  if __FILE__ == $PROGRAM_NAME
    source = File.absolute_path(ARGF.filename)
    iter = Lexer.get_words(source)
    program(iter).prin
  end
#end
