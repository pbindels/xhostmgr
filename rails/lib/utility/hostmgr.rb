require 'net/http'
require 'json'

env = ARGV[0]
batch_file = ARGV[1]

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
  if env == "prod"
    uri_str = "https://hostmgr.newokl.com/hosts/create"
  else
    uri_str = "http://localhost:3002/"
  end
  uri = URI.parse(uri_str)
  https = Net::HTTP.new(uri.host,uri.port,nil,nil,'pbindels','Akira0816')
  env == "prod" ? https.use_ssl = true : https.use_ssl = false
  req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  req.body = payload
  req.basic_auth 'pbindels', 'Akira0816'
  response = https.request(req)
  puts "Response #{response.code} #{response.message}: #{response.body}"
end

lines = File.open(batch_file,"r")
lines.each do | line |
  next if line =~ /^#/
  hostname,ipaddr,mac,con_ipaddr,con_mac,os,serial,ksregen,is_ipmi,user_groups,host_groups = line.split(/,/)
  ugroups = user_groups.split(/:/)
  hgroups = host_groups.split(/:/)
  location,environment,host_role,instance = hostname.split(/-/)
  name_server = gateway = boot_server = netmask = ""
  if ipaddr =~ /((\d{1,3}\.){3})\d{1,3}/
    ip_root = $1.gsub!(/\.$/,'')
    ns = name_servers[location]
    name_server = ns
    gateway = ip_gate_map[ip_root]
    boot_server = all_boot_hosts[location]
    netmask = "255.255.255.0"
    #puts "#{@host.name} - #{ip_root} - #{ns} - #{@host.gateway} - #{@host.boot_server} - #{@host.netmask}"
  end
  puts "-------"
  p hostname
  p location
  p environment
  p host_role
  p ipaddr
  p os
  p hgroups
  p ugroups
  p gateway
  p name_server
  p boot_server
  p netmask
  p con_ipaddr
  p con_mac

  payload = {
      "host" => {
          "name" => hostname,
          "ipaddr" =>  ipaddr,
          "os_version" => os,
          "macaddr" => mac,
          "con_macaddr" => con_mac,
          "con_ipaddr" => con_ipaddr,
          "name_server" => name_server,
          "boot_server" => boot_server,
          "gateway" => gateway,
          "netmask" => netmask,
          "is_ipmi" => is_ipmi,
          "ks_regen" => true,
          "serial_number" => serial
      },
      "user_groups" => ugroups,
      "host_groups" => hgroups
  }.to_json
  @post_ws = "/hosts/create"
  #@post_ws = "/services/rest/V2/?session_id=#{session_id}&format=json&method=slb.server.delete"
  submit_payload(@post_ws,payload,env)
  sleep 1
end

#curl -d "host[name]=sac-prod-kg-web-47" -d "params[user_groups]={sysadmin okl}" -d "host[ipaddr]=10.10.10.10" -d "host[macaddr]=AA:BB:CC:DD:EE:FF" -d "host[con_macaddr]=GG:HH:II:JJ:KK:LL" -d "host[host_groups]=qa:load" -d "host[os_version]=CentOS-5.9-x86_64"  localhost:3002/hosts/create > out

