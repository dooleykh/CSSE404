java = Dir["./FullTests/*.java"].sort
output = Dir["./ExpectedOutput/*.out"].sort

puts "Tests are printed consecutively. If there's no output after \"Testing: ...\", the test passed.\n"
(0..java.length - 1).each do |i| 
  puts "Testing: #{java[i]}"
  `ruby ../lexer/lexer.rb #{java[i]} > out.txt`
  out = `cmp --silent #{output[i]} out.txt || echo "files are different"`
  puts out if out != ""
end
