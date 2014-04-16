require "../parser/parser.rb"
require "../lexer/lexer.rb"

def getType(tree)
  :int
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
    #Note: write functions for checking types
    ret = tree.children[0]
    if ret.type == :int or ret.type == :bool
      ret = ret.type
    else
      ret = ret.children[0].value
    end
    unless ret == getType(tree.children[-1]) #TODO
      puts tree.children[0].name
      puts "MethodDecl ERROR"
    end
    tables.pop
    tables.last[tree.children[1].value] = :methodGoesHere
  when :ClassVarDecl
    
  when :MethodDecl
    
  when :FormalSt
    tree.children.each { |c| walk(c, tables) }
  when :FormalPl
    
  when :Formal
    
  when :Type
    
  when :Stmt
    
  when :Program
    
    
  end
end


if __FILE__ == $PROGRAM_NAME
  source = File.absolute_path(ARGF.filename)
  parse_tree = program(Lexer.get_words(source))
  walk(parse_tree, nil)
end

