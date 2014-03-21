input = ARGF.readlines.map(&:lstrip).map(&:rstrip).map(&:chomp)
token_classes = {
  "ReservedWord" => /^(class|public|static|extends|void|int|boolean|if|else|while|return|null|true|false|this|new|String|main|System\.out\.println)(?=(\+|-|\*|\/|<=|<|>|>=|==|!=|&&|\|\||!|;|\.|,|=|\(|\)|\{|\}|\[|\])|\z|\s)(.*)$/,
  "Operator" => /^(\+|-|\*|\/|<=|<|>=|>|==|!=|&&|\|\||!)(.*)$/,
  "Delimiter" => /^(;|\.|,|=|\(|\)|\{|\}|\[|\])(.*)$/,
  "Integer" => /^(0|[1-9][0-9]*)(.*)$/,
  "ID" => /^([a-zA-Z])([a-zA-Z0-9]*)(.*)$/
}

blockComment = false
input.each { |line|
  if blockComment or line["//"] or line["/*"]
    l = ""
    i = 0
    until i > line.length - 1
      if blockComment
        if line[i, 2] == "*/"
          blockComment = false
          l += " "
          i += 2
        else
          i += 1
        end
      elsif line[i, 2] == "//"
        break
      elsif line[i, 2] == "/*"
        blockComment = true
        i += 2
      else
        l += line[i]
        i += 1
      end
    end
  else
    l = line
  end
  l.lstrip
  
  until l.empty?
    l2 = l
    token_classes.each_key{ |x|
      if l =~ token_classes[x]
        if x == "ID"
          #We've matched an ID and may have to merge two pieces (if ID is longer than 1 char)
          puts "#{x}, #{$1 + $2}"
          l = $3.lstrip
        elsif x == "ReservedWord"
          puts "#{x}, #{$1}"
          l = $3.lstrip #Use $3 due to Regex Lookahead
        else
          puts "#{x}, #{$1}"
          l = $2.lstrip
        end
        break
      end     
    }
    if l == l2
      #No symbols matched. Consume one character and continue tokenizing (potential errors)
      #TODO: Decide on approach for failures in tokenizing
      l = l[1..-1]
    end
  end

  if blockComment
    #TODO: If reached, block comment was not closed. Decide how to handle. Halt? Parse? Alert developer?
  end
}
