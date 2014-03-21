java = Dir["./FullTests/*.java"].sort
output = Dir["./ExpectedOutput/*.out"].sort

(0..java.length - 1).each do |i| 
  #puts "Testing: #{java[i]}"
  `ruby ../lexer/lexer.rb #{java[i]} > out.txt`
  out = `cmp #{output[i]} out.txt`
  puts "#{java[i]}: #{out}" if out != ""#out if out != ""
end
