path = File.dirname(__FILE__)
zones = IO.readlines("#{path}/timezones.txt")

total = 0
pass = 0

zones.each do |zone|
  zone.chomp!

  result = %x[export TZ="#{zone}" && spec #{path}/../spec/timezone_spec.rb 2> /dev/null]

  total += 1


  printf("%60s | ", zone)

  if result.match(/FAILED/)
    puts "FAIL"
  else
    puts "pass"
    pass += 1
  end

end

puts "="*80
puts "="*80
puts "#{pass}/#{total} = %d" % (pass.to_f/total).round
