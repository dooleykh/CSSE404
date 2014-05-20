require_relative 'turing/turing.rb'
require_relative 'turing/turingBuilder.rb'

def main
	if ARGV.size < 1
		puts 'no input file'
		return
	end

	fname = ARGV[0]

	f = open(fname, 'r')
	machine = Marshal.load(f.read)
	f.close

	if ARGV.size == 2
		machine.run(nil, ARGV[1].to_f, false)
	elsif ARGV.size == 3
		if ARGV[2] != 'i'
			puts 'Invalid argument'
			return
		end
		machine.run(nil, ARGV[1].to_f, false, true)
	else
		machine.run(nil, nil, false, false)
	end
end

main
