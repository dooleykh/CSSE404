input = ARGF.readlines.map(&:lstrip).map(&:rstrip).map(&:chomp)

token_classes = {
  "ReservedWord" => /^(class|public|static|extends|void|int|boolean|if|else|while|return|null|true|false|this|new|String|main|System\.out\.println)(.*)/,
  "Operator" => /^(\+|-|\*|\/|<=|<|>|>=|==|!=|&&|\|\||!)(.*)/,
  "Delimiter" => /^(;|\.|,|=|\(|\)|\{|\}|\[|\])(.*)/,
  "Integer" => /^(0|[1-9][0-9]*)(.*)/,
  "ID" => /^([a-zA-Z])([a-zA-Z0-9]*)(.*)/
}

blockComment = false
input.each { |line| 
  l = line

  if blockComment
    if l["*/"]
      #      l = l.gsub(/.*\*\/(.*)/, ' ').lstrip
      l = l.gsub(/.*\*\/.*/, ' ').lstrip
      blockComment = false
    else
      l = ""
    end
  end
  
  if l["/*"]
    if l["*/"]
      #The block comment ends on the same line. Find the comment and replace it with whitespace
      l = l.gsub(/\/\*(.*)\*\//, ' ').lstrip
    else
      #The comment carries onto other lines. Grab any code from here and set a flag.
      l = l.gsub(/\/\*.*/, ' ').lstrip
      blockComment = true
    end
  end

  if l["//"]
    l = l.gsub(/\/\/.*/, ' ').lstrip
  end
  
  until l.empty?
    token_classes.each_key{ |x|
      if l =~ token_classes[x]
        if $3
          #We've matched an ID and may have to merge two pieces (if ID is longer than 1 char)
          puts "#{x}, #{$1 + $2}"
          l = $3.lstrip
        else
          puts "#{x}, #{$1}"
          l = $2.lstrip
        end
        break
      end
    }
  end
}
