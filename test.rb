a = [0, 1]
if a[0]
	puts 1
end

a = "test1 0"
result = a.split('test1')
puts "size #{ result.size }"

token = result[2] || "ttttt"
puts token
puts token.empty?
puts token
puts result[0].empty?
puts result[1].nil?

#puts result[0]
#puts result.size

def test
	return 1000, "hhhhh"
end

result = test
puts result[0]
puts result[1]

payload = {
    data: 1,
    exp: 2, #5s later
    nbf: 2  #2s later
  }
puts payload

puts "ss" == 'ssd'