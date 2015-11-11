require 'mysql2'

added_file = File.open("ip_adds.txt","w")
deleted_file = File.open("ip_deletes.txt","w")

added = [] 
deleted = [] 

db = Mysql2::Client.new(:host => 'localhost', :username => 'root',  :password => '',  
     :socket => '/okl/hostmgr/prod/mysql/tmp/run/mysqld.sock', :database => 'hostmgr', 
     :defaults_file => '/okl/hostmgr/prod/mysql/conf/my.cnf')

keys = db.query("SELECT * FROM hosts ", :as => :hash)

pbnew = File.open("pb.newx", "w")
keys.each do |row|
  pbnew.puts "#{row["name"]},#{row["ipaddr"]}" if row["ipaddr"] =~ /\d+\.\d+\.\d+\.\d+/
  pbnew.puts "#{row["con_name"]},#{row["con_ipaddr"]}" if row["con_ipaddr"] =~ /\d+\.\d+\.\d+\.\d+/
end
pbnew.close

pbnew = File.open("pb.new", "r")
pbold = File.open("pb.out", "r")
pbnew.each do | newline |
  found = false
  newname, newip = newline.chop.split(/,/)
  pbold = File.open("pb.out", "r")
  pbold.each do | oldline |
    oldname, oldip = oldline.chop.split(/,/)
    if newip == oldip
      found = true
      break
    end
  end
  added.push(newip) unless found
end 

pbold.close
pbnew.close
   
pbnew = File.open("pb.new", "r")
pbold = File.open("pb.out", "r")

pbold.each do | oldline |
  found = false
  oldname, oldip = oldline.chop.split(/,/)
  pbnew = File.open("pb.new", "r")
  pbnew.each do | newline |
    newname, newip = newline.chop.split(/,/)
    if oldip == newip
      found = true
      break
    end
  end
  deleted.push(oldip) unless found
end 

deleted.each do |ip|
  deleted_file.puts ip
end
  
added.each do |ip|
  added_file.puts ip
end

