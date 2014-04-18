require_relative "../lexer/lexer.rb"

module Parser
  @iter
  @tree

  First = {
    :Stmt => ["{", "if", "while", "System.out.print.ln", :ID, "integer", "boolean"]
  }
  
  class ParseTree
    attr_accessor :main, :classes

    def initialize()
      @main = JavaClass.new
      @classes = []
    end
  end
  
  class JavaClass
    attr_accessor :id, :extends, :decl, :methods, :return

    def initialize()
      @decl = []
      @methods = []
    end
  end

  class Method
    attr_accessor :id, :type, :formals, :statements

    def initialize()
      @formals = []
      @statements = []
    end
  end

  class ParseError < Exception
  end

  def Parser.readRequiredSymbol(symbol)
    if symbol.is_a? String
      while symbol != @iter.peek.value
        puts "Parse Error on line #{@iter.peek.line_num}: Expected #{symbol}, read #{@iter.peek.value}"
        @iter.next
      end
    else
      while symbol != @iter.peek.token
        puts "Parse Error on line #{@iter.peek.line_num}: Expected #{symbol}, read #{@iter.peek.value}"
        @iter.next
      end
    end    
    @iter.next.value
  end
  
  def Parser.parse
    @tree = ParseTree.new
    #start with MainClassDecl
    mainClassDecl
  end

  def Parser.mainClassDecl
    #@tree.main = JavaClass.new
    readRequiredSymbol("class")
    @tree.main.id = readRequiredSymbol(:ID)
    ["{", "public", "static", "void", "main", "(", "String", "[", "]"].each { |sym| readRequiredSymbol(sym)}
    @tree.main.methods << Method.new
    @tree.main.methods.last.id = :main
    @tree.main.methods.last.formals << ["String[]", readRequiredSymbol(:ID)]
    [")", "{"].each { |sym| readRequiredSymbol(sym)}
    @tree.main.methods.last.statements = stmtSt
    ["}", "}"].each { |sym| readRequiredSymbol(sym) }

    begin
      #Check if we have more tokens for ClassDeclSt
      while @iter.peek
        classDeclSt
      end
    rescue StopIteration
      #Nope. We're done.
    end
  end

  def Parser.classDeclSt
    #We have at least one class
    c = []
    c << classDecl
    begin
      while @iter.peek
        c2 = classDecl
        c << c2
      end
    rescue StopIteration
      
    end
    c
  end

  def Parser.classDecl
    readRequiredSymbol("class")
    c = JavaClass.new
    c.id = readRequiredSymbol(:ID)
    while @iter.peek
      if @iter.peek.value == "extends"
        c.extends = readRequiredSymbol(:ID)
        break
      elsif @iter.peek.value == "{"
        break
      else
        puts "Parse Error on line #{@iter.peek.line_num}: Expected class name or \"extends\", read #{@iter.peek.value}"
        @iter.next
      end
    end
    readRequiredSymbol("{")
    c.decl = classVarDeclSt
    c.methods = methodDeclSt
    readRequiredSymbol("}")
    c
  end

  def Parser.classVarDeclSt
    t = []
    while @iter.peek
      if ["int", "boolean"].include? @iter.peek.value || @iter.peek.token == :ID
        t2 = []
        t2 << @iter.peek.token
        @iter.next
        t2 << readRequiredSymbol(:ID)
        readRequiredSymbol(";")
        t << t2
      else
        break
      end
    end
    t
  end
  
  def Parser.stmtSt
    t = []
    while @iter.peek
      pv = @iter.peek.value
      pt = @iter.peek.token
      if First[:Stmt].include?(pv) || First[:Stmt].include?(pt)
        t << stmt
      else
        break
      end
    end
    t
  end

  def Parser.stmt
    
  end

  def Parser.methodDeclSt
    t = []
    while @iter.peek
      if @iter.peek.value == "public"
        t << methodDecl
      else
        break
      end
    end
    t
  end

  def Parser.methodDecl
    readRequiredSymbol("public")
    m = Method.new
    while @iter.peek
      if ["int", "boolean"].include? @iter.peek.value || @iter.peek.token == :ID
        m.type = @iter.next.value
        break
      else
        puts "Parse Error on line #{@iter.peek.line_num}: Expected int, boolean, or class name, read #{@iter.peek.value}"
        @iter.next
      end
    end
    m.id = readRequiredSymbol(:ID)
    readRequiredSymbol("(")
    m.formals = formalSt
    [")", "{"].each { |sym| readRequiredSymbol(sym) }
    m.statements = stmtSt
    readRequiredSymbol("return")
    m.return = expr
    [";", "}"].each { |sym| readRequiredSymbol(sym) }
    m
  end

  def Parser.formalSt
    t = []
    while @iter.peek
      t2 = []
      if ["int", "boolean"].include? @iter.peek.value || @iter.peek.token == :ID
        t2 << @iter.peek.value
        @iter.next
        t2 << readRequiredSymbol(:ID)
        t << t2
      elsif @iter.peek.value == ","
        readRequiredSymbol(",")
      elsif @iter.peek.value == ")"
        break
      else
        puts "Parse Error on line #{@iter.peek.line_num}: Invalid sequence #{@iter.peek.value} in formal list."
        @iter.next
      end
    end
    t
  end

  def Parser.expr
    
  end
  
  if $PROGRAM_NAME == __FILE__
    source = File.absolute_path(ARGF.filename)
    @iter = Lexer.get_words(source)
    Parser.parse
    puts "Main"
    p @tree.main.decl
    p @tree.main.methods

  end
end
