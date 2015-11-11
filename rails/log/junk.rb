str =   "11:22:33:DD:EE:FE"

if str =~ /^(([[:alnum:]]{2}\:){5})([0-9,A-Z]{2})$/
  puts $1
  puts $3
  puts str
end

str1 = "\t\tu-sysadmin u-okl"
str2 = "\t\tu-sysadmin mbergman ptsai"
strs = [ str1, str2]
strs.each do |str|
  str.gsub!(/u-|^\s*/,'')
  fields = str.split(/\s+/)
  p fields
end
                  
a = File.open("testfile",File::TRUNC|File::RDWR)

a.puts "also"
a.puts "also"

