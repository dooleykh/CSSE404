input = ARGF.read

token_classes = {"number" => /^(0|[1-9][0-9]*)(.*)$/,
				 "plus" => /^(\+)(.*)$/,
				 "minus" => /^(-)(.*)$/}

until input.empty?
	token_classes.each_key{ |x|
		if input =~ token_classes[x]
			puts "#{x}, #{$1}"
			input = $2
			break
		end
	}
end
