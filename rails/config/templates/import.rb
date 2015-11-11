require 'net/http'
require 'json'

env = ARGV[0]

name_servers = {
                 "sfo" => "10.110.2.61",
                 "sac" => "10.120.2.61",
                 "ec2" => "10.130.2.61"
}
all_boot_hosts = {
                  "sfo" => "sfo-ops-adm-01.unix.newokl.com",
                  "sac" => "sac-ops-adm-01.unix.newokl.com",
                  "ec2" => "NA"
}
ip_gate_map = {
    "10.110.11"=> "10.110.11.254",
    "10.110.2"=> "10.110.2.1",
    "10.110.3"=> "10.110.3.1",
    "10.120.2"=> "10.120.2.1",
    "10.120.3"=> "10.120.3.1",
    "10.130.2"=> "10.120.2.1",
    "10.130.3"=> "10.120.3.1"
}

def submit_payload(post_ws,payload,env)
  uri_str = ""
  puts env
  if env == "prod"
    uri_str = "https://hostmgr.newokl.com/hosts/create"
  else
    uri_str = "http://localhost:3002/"
  end
  uri = URI.parse(uri_str)
  puts "#{uri.path} - #{uri.host} - #{uri.port}"
  https = Net::HTTP.new(uri.host,uri.port,nil,nil,'pbindels','Akira0816')
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  req.body = payload
  req.basic_auth 'pbindels', 'Akira0816'
  response = https.request(req)
  #puts "location is #{response['location']}"
  puts "Response #{response.code} #{response.message}: #{response.body}"
  #
  #req = Net::HTTP::Post.new(post_ws, initheader = {'Content-Type' =>'application/json'})
  #req.body = payload
  #uri = URI.parse("http://hostmgr.newokl.com")
  #puts "#{uri.path} - #{uri.host} - #{uri.port}"
  #response = Net::HTTP.new("hostmgr.newokl.com").start {|http|  http.request(req) }
  #puts "Response #{response.code} #{response.message}: #{response.body}"
  #uri_str = response['location']
  #uri = URI.parse(uri_str)
  #puts "#{uri.path} - #{uri.host} - #{uri.port}"
  #https = Net::HTTP.new(uri.host,uri.port)
  #https.use_ssl = true
  #req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  #req.body = payload
  #res = https.request(req)
  #puts "Response #{response.code} #{response.message}: #{response.body}"
end

def get_host_groups (hostname)
  arr = Array.new
  netgroup = File.open("netgroup.orig","r")
  hgroups = Hash.new
  arr = Array.new
  netgroup.each do | line |
    next if  line !~ /^h-(.*) \\/
    grp_name = $1
    while ( line = netgroup.gets ) !~ /^\n$/ &&  ( line != nil ) 
      if line =~ /#{hostname}/
        arr.push grp_name
      end
    end
  end
  if arr.size == 0
    arr.push("none")
  end
  return arr
end

def get_ec2_hosts
  netgroup = File.open("netgroup.orig","r")
  arr = Array.new
  netgroup.each do | line |
    if line =~ /^u-(ec2.*)?.unix.newokl.com/
      arr.push($1)
    end
  end
  return arr
end

def get_host_macs
  dhcpd = File.open("dhcpd-local.conf","r")
  host_macs = Hash.new
  mac = ""
  dhcpd.each do | line |
    next if line =~ /^\s*?#/
    if line =~ /host (.*?)(-con|\.unix)\.newokl.com/i
      mactype = $2.tr('-.','')
      host = $1
      while ((hw_line = dhcpd.readline) =~ /^\s*?#/ )
        #continue
      end
      if hw_line =~ /hardware ethernet (.*)/
        mac = $1.gsub!(/;/,'')
      end
      if !  host_macs.has_key?(host)
        host_macs[host] = Hash.new 
      end
      mactype == "con" ? host_macs[host]["con_mac"] = mac : host_macs[host]["mac"] = mac
      host_macs[host]["con_name"] = "#{host}-con.newokl.com"
      host_macs[host]["con_ipaddr"] = get_ipaddr(host_macs[host]["con_name"])
      #host_macs[host]["con_ipaddr"] = "10.110.3.10"
      p host_macs[host]
    end
  end
  host_macs.each do | host, macs |
    host_macs[host]["con_mac"] == nil ? host_macs[host]["con_mac"] = "NA_#{rand(10..1000000)}" : nil
    host_macs[host]["mac"] == nil ? host_macs[host]["mac"] = "NA_#{rand(10..1000000)}" : nil
  end

  return host_macs
end

def get_user_groups ( hostnm )
  netgroup = File.open("netgroup.orig","r")
  user_groups = Array.new
  netgroup.each do | line |
    if line =~ /#{hostnm}/
      user_groups = netgroup.readline.gsub!(/u-|^\s+/,'').split(/\s+/)
      netgroup.close
      return user_groups
    end
  end
  if user_groups.size == 0
    user_groups.push("none")
  end
  return user_groups 
end

def get_ipaddr(hostnm)
  #puts "ssh sac-ops-adm-01.unix.newokl.com \"nslookup #{hostnm} | grep Address | tail -1 | cut -d: -f2"
  #host = `ssh sac-ops-adm-01.unix.newokl.com \"nslookup #{hostnm} | grep Address | tail -1 | cut -d: -f2"`
  ip = `ssh sac-ops-adm-01.unix.newokl.com \"host #{hostnm} | cut -d' ' -f4 " `
  puts ip
  if ip !~ /((\d{1,3}\.){3})\d{1,3}/
    return "NA_#{rand(10..1000000)}"
  else
  #host = `ssh sfo-ops-adm-01.unix.newokl.com \"nslookup #{hostnm}.unix.newokl.com | grep Address | tail -1 | cut -d: -f2"`
    return ip.strip!
  end
end
  

all_loc_hosts = File.open("l_us_all","r").readlines.map! { |e| e.gsub(/\n/,'')}
all_hosts = get_host_macs
all_ec2_hosts = get_ec2_hosts

all_ec2_hosts.each do | host|
  all_hosts[host] = Hash.new
  all_hosts[host]["con_name"] = "sac-ops-xen-02"
  all_hosts[host]["con_ipaddr"] = "NA"
  all_hosts[host]["con_mac"] = "NA"
  all_hosts[host]["gateway"] = "NA"
  all_hosts[host]["netmask"] = "NA"
  all_hosts[host]["name_server"] = "NA"
  all_hosts[host]["boot_server"] = "NA"
  all_hosts[host]["mac"] = "NA"
end

#p all_hosts
p all_loc_hosts
is_ipmi = true
all_hosts.each do | hostname, macs |
  next if ! all_loc_hosts.include?(hostname)
  #puts hostname
  mac = macs["mac"]
  con_mac = macs["con_mac"]
  if con_mac =~ /^NA/
    is_ipmi = false
  end
  con_name = macs["con_name"]
  con_ipaddr = macs["con_ipaddr"]
  location,environment,host_role,instance = hostname.split(/-/)
  hgroups = get_host_groups(hostname)
  ugroups = get_user_groups(hostname)
  ipaddr = get_ipaddr("#{hostname}.unix.newokl.com")
  #ipaddr = "10.110.2.101"
  if hostname =~ /dw|vgr|debian/
    os = "Debian-6.0.6-amd64"
  else
    os = "CentOS-5.9-x86_64"
  end
  name_server = gateway = boot_server = netmask = ""
  if ipaddr =~ /((\d{1,3}\.){3})\d{1,3}/
    #puts "ip_root"
    ip_root = $1.gsub!(/\.$/,'')
    p name_servers

    ns = name_servers[location]
    name_server = ns
    gateway = ip_gate_map[ip_root]
    boot_server = all_boot_hosts[location]
    netmask = "255.255.255.0"
    #puts "#{@host.name} - #{ip_root} - #{ns} - #{@host.gateway} - #{@host.boot_server} - #{@host.netmask}"

  end
  #next if macs.size != 2
  puts "-------"
  p macs.size
  p hostname
  p con_name
  p location
  p environment
  p host_role
  p ipaddr
  p os
  p macs
  p hgroups
  p ugroups
  p gateway
  p name_server
  p boot_server
  p netmask
  p con_ipaddr
  p con_mac
  #
  #user_groups = ugroups.map { |k| "#{k}" }.join(":")
  #host_groups = hgroups.map { |k| "#{k}" }.join(":")

  #p user_groups
  #p host_groups
  #puts "sleeping 2"
  #sleep 2


  payload = {
      "host" => {
          "name" => hostname,
          "ipaddr" =>  ipaddr,
          "os_version" => os,
          "macaddr" => mac,
          "con_macaddr" => con_mac,
          "con_name" =>  con_name,
          "con_ipaddr" => con_ipaddr,
          "name_server" => name_server,
          "boot_server" => boot_server,
          "gateway" => gateway,
          "netmask" => netmask,
          "is_ipmi" => is_ipmi,
          "serial_number" => rand(10..1000000),
          "ks_regen" => true
      },
      "user_groups" => ugroups,
      "host_groups" => hgroups
  }.to_json
  @post_ws = "/hosts/create"
  #@post_ws = "/services/rest/V2/?session_id=#{session_id}&format=json&method=slb.server.delete"
  submit_payload(@post_ws,payload,env)
  puts "sleeping 5"
  sleep 1

end

exit

#curl -d "host[name]=sac-prod-kg-web-47" -d "params[user_groups]={sysadmin okl}" -d "host[ipaddr]=10.10.10.10" -d "host[macaddr]=AA:BB:CC:DD:EE:FF" -d "host[con_macaddr]=GG:HH:II:JJ:KK:LL" -d "host[host_groups]=qa:load" -d "host[os_version]=CentOS-5.9-x86_64"  localhost:3002/hosts/create > out

dhcpd = File.open("dhcpd.conf","r")

dhcpd.each do | line |
  line.chomp!
  next if line !~ /host/
  user_groups = Array.new
  host_groups = Array.new
  if line =~ /host (.*?)(-con|\.unix)\.newokl.com/
    hostnm = $1
    mactype = $2
    hw_line = dhcpd.readline
    if hw_line =~ /hardware ethernet (.*)/
      macaddr = $1
      if mactype =~ /con/
        conmac = $1
      elsif mactype =~ /unix/
        mac = $1
      end
      #puts "#{line} - #{hostnm} - #{mactype} - #{macaddr}"
      hgroups = get_host_groups(hostnm)
      #puts "hgroups"
      #p hgroups
      #sleep 1
      netgroup = File.open("netgroup.orig","r")
      netgroup.each do | line |
        if line =~ /#{hostnm}/
          user_groups = netgroup.readline.strip!.split(/u-/)
          #puts "user groups"
          #p user_groups[1..-1]
          netgroup.close
          break
        end
      end
    end
    #sleep 2
  end
end

#get_host_groups

def generate_zone_file ()
  zone_dir = Rails.configuration.my_scope.zone_dir
  env_zone_file = "#{@log_root}/db-newokl.com-genesis"
  host_zone_file = "#{@log_root}/db-newokl.com+env-genesis"
  env_zone = File.open(env_zone_file, "w")
  host_zone = File.open(host_zone_file, "w")

  Project.all.each do | pr |
    pr.environments.each do | e |
      env_zone.puts "#{pr.name}-#{e.name}\tIN  CNAME\tall-www-elb.newoklcom."
      e.vms.each do |vm|
        host_zone.puts "#{vm.name}\tIN CNAME\t#{vm.dns_name}."
      end
    end
  end
  @project.environments.each do |e|
    env_zone.puts "#{@project.name}-#{e.name}\tIN\tCNAME\tall-www-elb.newoklcom."
    e.vms.each do |vm|
      host_zone.puts "#{vm.name}\tIN CNAME\t#{vm.dns_name}."
    end
  end
  env_zone.close
  host_zone.close

  `cp #{env_zone_file} #{zone_dir}`
  `cp #{host_zone_file} #{zone_dir}`
end

def update_dns()
  @dns_zones = Rails.configuration.my_scope.dns_zones

  #Update master files serial #
  @dns_zones.each do | zone |
    src_zone = "#{@log_root}/db-newokl.com:#{zone}"
    #gen_zone = "#{@log_root}/#{src_zone}.new"
    serial = `egrep '\\d{9};.*serial' #{src_zone} | cut -f5 | tr -d ";" `.to_i
    serial_new = (serial + 1).to_s
    `sed -i.bak 's/#{serial}/#{serial_new}/g' #{src_zone}`
  end
  #Push configs (cfengine?)
  #`/usr/sbin/cfagent -qK`
end

# PUT /projects/1
# PUT /projects/1.json
def update
  @project = Project.find(params[:id])
  respond_to do |format|
    if @project.update_attributes(params[:project])
      format.html { redirect_to @project, notice: 'Project was successfully updated.' }
      format.json { head :no_content }
    else
      format.html { render action: "edit" }
      format.json { render json: @project.errors, status: :unprocessable_entity }
    end
  end
end