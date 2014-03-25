#This test harness runs the lexer on each test file and compares
#the output to the expected output. If there's a difference, the test
#and line number of the first error are displayed.

#Run by setting /WollowskiLexerTestcases as your current directory
#and runnning "ruby testRunner.rb" with Ruby 2.0 or higher.
java = Dir["./FullTests/*.java"].sort
output = Dir["./ExpectedOutput/*.out"].sort

(0..java.length - 1).each do |i| 
  `ruby ../lexer/lexer.rb #{java[i]} > out.txt`
  out = `cmp #{output[i]} out.txt`
  puts "#{java[i]}: #{out}" if out != ""
end
`rm out.txt`
