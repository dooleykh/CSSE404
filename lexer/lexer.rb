module Lexer

  Word = Struct.new(:token, :value, :line_num)

  Token_classes =
    {
    :ReservedWord => /^(class|public|static|extends|void|int|boolean|if|else|while|return|null|true|false|this|new|String|main|System\.out\.println)(?=(\+|-|\*|\/|<=|<|>=|>|==|!=|&&|\|\||!|;|\.|,|=|\(|\)|\{|\}|\[|\])|\z|\s)(.*)$/,
    :Operator => /^(\+|-|\*|\/|<=|<|>=|>|==|!=|&&|\|\||!)(.*)$/,
    :Delimiter => /^(;|\.|,|=|\(|\)|\{|\}|\[|\])(.*)$/,
    :Integer => /^(0|[1-9][0-9]*)(.*)$/,
    :ID => /^([a-zA-Z])([a-zA-Z0-9]*)(.*)$/
  }
  
  def Lexer.get_words(file)
    input = File.open(file) do |f|
      f.readlines.map(&:lstrip).map(&:rstrip).map(&:chomp)
    end
    block_comment = false
    block_comment_line_num = -1
    
    words = Enumerator.new do |enum| 
      input.each_with_index { |line, line_num|
        if block_comment or line["//"] or line["/*"]
          l = ""
          i = 0
          until i > line.length - 1
            if block_comment
              if line[i, 2] == "*/"
                block_comment = false
                l += " "
                i += 2
              else
                i += 1
              end
            elsif line[i, 2] == "//"
              break
            elsif line[i, 2] == "/*"
              block_comment = true
              i += 2
            else
              l += line[i]
              i += 1
            end
          end
        else
          l = line
        end
        l = l.strip

        until l.empty?
          l2 = l
          
          Token_classes.each_key{ |x|
            if l =~ Token_classes[x]
              if x == :ID
                #We've matched an ID and may have to merge two pieces (if ID is longer than 1 char)
                enum << Word.new(x, $1.strip + $2.strip, line_num + 1)
                l = $3.strip
              elsif x == :ReservedWord
                enum << Word.new(x, $1.strip, line_num + 1)
                l = $3.strip #Use $3 due to Regex Lookahead
              else
                enum << Word.new(x, $1.strip, line_num + 1)
                l = $2.strip
              end
              break
            end
          }
          if l == l2
            #No symbols matched. Consume one character and continue tokenizing (potential errors)
            enum << Word.new(:UnknownToken, l[0], line_num + 1)
            l = l[1..-1].strip
          end
        end
      }
      if block_comment
        #Hanging block comment, so for ease raise an error
        enum << Word.new(:BlockCommentError, nil, block_comment_line_num + 1)
      end
    end
    words
  end
  
  if __FILE__ == $PROGRAM_NAME
    words = get_words(File.absolute_path(ARGF.filename))
    words.each { |word| puts "#{word.token}, #{word.value}"}
  end
end
