class HostsController < ApplicationController
  require 'fileutils'
  require 'erb'
  require 'ipaddr'
  require File.expand_path('app/models/template.rb')
  require File.expand_path('app/models/template2.rb')
  helper_method :sort_column, :sort_direction
  # skip_before_filter  :verify_authenticity_token
  # GET /hosts
  # GET /hosts.json


  def index
    if params[:attribute].nil? || params[:attribute] == '' || params[:q] == ''
      @hosts = Host.order(sort_column + " " + sort_direction )
    else
      @hosts = Host.where("#{params[:attribute]} LIKE ?", "%#{params[:q]}%")
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @hosts }
    end
  end

  def search
    puts params.inspect
    @hosts = Host.where("#{params[:attribute]} = ?", "#{params[:q]}" )
    @hosts.each do |h|
      puts h.name
      puts h.location
    end

    #@hosts = Host.order(sort_column + " " + sort_direction )
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @hosts }
    end
  end

  # GET /hosts/1
  # GET /hosts/1.json
  def show
    @host = Host.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @host }
    end
  end

  # GET /hosts/new
  # GET /hosts/new.json
  def new
    puts "in new method"
    @host = Host.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @host }
    end
  end

  # GET /hosts/1/edit/
  def edit
    @host = Host.find(params[:id])
  end

  # POST /hosts
  # POST /hosts.json
  def create

    if params[:host][:manual_host] == "0"
      params[:host][:name] = params[:location] + "-" +  params[:environment] + "-" + params[:product] + "-" + params[:hostrole] + "-" +  params[:instance]
    end

    params[:host].delete("manual_host")

    params.inspect
    # Check validity of Device Type and physical location  (refactor from create and update)
    if params[:host][:host_type] =~ /Physical/
      params[:host][:physical_location] = params[:host][:geo_location].upcase + ":C" + params[:host][:cage].to_s + ":R"\
                                         + params[:host][:rack].to_s + ":U" + params[:host][:start_unit] + "-" \
                                         + (params[:host][:start_unit].to_i  + params[:host][:unit_range].to_i - 1).to_s
      Rails.logger.info("HERE")
      Rails.logger.info("params[:host] is #{params[:host]}")
      validate_physical_location(params[:host])
      check_status and return
      params[:host][:esx_host] = "NA"
    else
      params[:host][:physical_location] = params[:host][:esx_host]
    end

    #Ensure the hostname coming in as a fqdn
    if params[:host][:name] !~ /\..*\.com$/
      params[:host][:name] = "#{params[:host][:name].downcase}.unix.newokl.com"
    end

    con_domain = params[:con_domain][:con_domain]

    if params[:host][:is_ipmi]  == "1"
      params[:host][:con_name]="#{params[:host][:name].gsub(/.unix.newokl.com/,'')}-con#{con_domain}"
    else
      params[:host][:con_name].downcase!
      params[:host][:con_macaddr]= "NA_#{Random.new.rand(1..1000000)}"
      params[:host][:con_ipaddr]= "NA_#{Random.new.rand(1..1000000)}"
    end

    params[:host][:con_macaddr].upcase!
    params[:host][:macaddr].upcase!

    @host = Host.new(params[:host])

    @host.user_groups = params[:user_groups] == nil ? "None" : params[:user_groups].map { |k| "#{k}" }.join(":")
    @host.host_groups = params[:host_groups] == nil ? "None" : params[:host_groups].map { |k| "#{k}" }.join(":")

    @name = @host.name

    session[:status] = true
    session[:msg] = ""


    validate_hostname
    check_status and return

    #generate_icinga    if @host.location =~ /sfo|sac/
    #check_status and return

    validate_addrs
    check_status and return

    clean_tmp
    check_status and return

    generate_dns
    check_status and return

    generate_netgroup3
    check_status and return

    generate_location
    check_status and return

    generate_tftp
    check_status and return

    generate_ks
    check_status and return

    #generate_nagios3
    #check_status and return

    generate_dhcpd
    check_status and return

    sync_to_synto
    check_status and return

    respond_to do |format|
      if @host.save
        UserMailer.status_email("pbindels@onekingslane.com",@current_user,@host,@site_root).deliver
        #UserMailer.status_email("techops@onekingslane.com",@current_user,@host,@site_root).deliver
        format.html { redirect_to @host, notice: 'Host was successfully created.' }
        format.json { render json: @host, status: :created, location: @host }
      else
        format.html { render action: "new" }
        format.json { render json: @host.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /hosts/1
  # PUT /hosts/1.json
  def update
    @host = Host.find(params[:id])
    #@host = Host.new(params[:host])

    @host.name.downcase!
    #p params.inspect

    #if params[:host][:host_type] != ""   &&  params[:host][:host_type] != "NA"
    session[:status] = true
    session[:msg] = ""

    # Check validity of Device Type and physical location
    if params[:host][:host_type] != ""
      if params[:host][:host_type] =~ /Physical/
        params[:host][:physical_location] = params[:host][:geo_location].upcase + ":C" + params[:host][:cage].to_s + ":R"\
                                              + params[:host][:rack].to_s + ":U" + params[:host][:start_unit] + "-" \
                                              + (params[:host][:start_unit].to_i  + params[:host][:unit_range].to_i - 1).to_s
        validate_physical_location(params[:host])
        check_status and return
        params[:host][:esx_host] = "NA"
      else
        params[:host][:physical_location] = params[:host][:esx_host]
      end
    end

    if params[:host][:manual_host] == "0"
      if params[:product].nil?
      params[:host][:name] = params[:location] + "-" +  params[:environment] + "-"  + params[:hostrole] + "-" +  params[:instance]
      else
        params[:host][:name] = params[:location] + "-" +  params[:environment] + "-" + params[:product] + "-" + params[:hostrole] + "-" +  params[:instance]
      end
    end

    params[:host].delete("manual_host")

    #Ensure the hostname coming in is a fqdn
    if params[:host][:name] !~ /\..*\.com$/
      params[:host][:name] = "#{params[:host][:name].downcase}.unix.newokl.com"
    end

    if params[:host][:is_ipmi]  == "1"
      params[:host][:con_name]="#{params[:host][:name].gsub(/.unix.newokl.com/,'')}-con.newokl.com"
    else
      params[:host][:con_name].downcase!
      params[:host][:con_macaddr]= "NA_#{Random.new.rand(1..1000000)}"
      params[:host][:con_ipaddr]= "NA_#{Random.new.rand(1..1000000)}"
    end

    @host.user_groups = params[:user_groups] == nil ? "None" : params[:user_groups].map { |k| "#{k}" }.join(":")
    @host.host_groups = params[:host_groups] == nil ? "None" : params[:host_groups].map { |k| "#{k}" }.join(":")

    @name = params[:host][:name]
    params[:host][:con_macaddr].upcase!
    params[:host][:macaddr].upcase!

    #session[:status] = true
    #session[:msg] = ""

    validate_addrs
    check_status and return

    validate_hostname
    check_status and return

    clean_tmp
    check_status and return

    respond_to do |format|

      if @host.update_attributes(params[:host])

        generate_dns
        check_status and return

        Rails.logger.info "Running netgroup3"
        generate_netgroup3
        check_status and return

        generate_location
        check_status and return

        generate_tftp
        check_status and return

        generate_ks
        check_status and return

        #generate_ifmgr
        #check_status and return

        generate_dhcpd
        check_status and return

        sync_to_synto
        check_status and return

        format.html { redirect_to @host, notice: 'Host was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @host.errors, status: :unprocessable_entity }
      end
    end
  end


  def do_task
    @task_name = params[:task_name]
    Rails.logger.info "HERE"
    Rails.logger.info params
    Rails.logger.info "#{@task_name} is task"
    case @task_name
      when /add host$/i;                            redirect_to new_host_path
      when /add product/i;                         redirect_to new_product_path
      when /add role/i;                            redirect_to new_role_path
      when /add host type/i;                       redirect_to new_host_type_path
      when /show hosts/i ;                         redirect_to hosts_path
      when /show products/i;                       redirect_to products_path
      when /show roles/i;                          redirect_to roles_path
      when /show host types/i;                     redirect_to host_types_path
      else
        respond_to do |format|
          format.html  # index.html.erb
          format.json { render json: @hosts }
        end
    end
  end

  # DELETE /hosts/1
  # DELETE /hosts/1.json
  def destroy

    @host = Host.find(params[:id])
    @name = @host.name
    session[:status] = true
    session[:msg] = ""

    clean_tmp
    check_status and return

    generate_dns
    check_status and return

    generate_netgroup3
    check_status and return

    generate_location
    check_status and return

    generate_tftp
    check_status and return

    generate_ks
    check_status and return

    generate_dhcpd
    check_status and return

    sync_to_synto
    check_status and return

    @host.destroy

    respond_to do |format|
      UserMailer.delete_email("pbindels@onekingslane.com",@current_user,@host,@site_root).deliver
      #UserMailer.delete_email("techops@onekingslane.com",@current_user,@host,@site_root).deliver

      format.html { redirect_to hosts_url }
      format.json { head :no_content }
    end
  end
end

def check_status
  if session[:status] == false
    msg = session[:msg]
    msg = msg.html_safe
    render "/hosts/standard_error.html.erb", :locals => { :var => msg }
    return  true
  else
    return false
  end
end

def clean_tmp
  tmp_dir =  "#{@tmp_root}/#{@synto_root}"
  Rails.logger.info "Clearing #{tmp_dir}!!!"
  if File.exists?(tmp_dir)
    dirs = Dir.entries(tmp_dir)
    dirs.each do | dir |
      next if dir == '.' || dir == '..'
      Rails.logger.info "Deleting #{tmp_dir}/#{dir}"
      FileUtils.rm_r "#{tmp_dir}/#{dir}"
    end
  end
end

def sync_to_synto
  Rails.logger.info "sync_synto.rb #{@tmp_root}/data #{@sync_root}"
  if Rails.env == "development"
    system("ruby #{@rails_root}/lib/utility/sync_synto.rb #{@tmp_root}/data #{@sync_root} #{@synto_root} #{@archive_root} >> #{@log_root}/sync.log  2>&1")
  elsif Rails.env == "production" || Rails.env == "qa"
    system("sudo /usr/local/bin/ruby #{@rails_root}/lib/utility/sync_synto.rb  >> #{@log_root}/sync.log  2>&1")
  else
    Rails.logger.info "Sync has not been selected"
  end
end

def validate_addrs
  h = Host.new(params[:host])

  ip_addrs = %W(#{h.ipaddr})
  ip_addrs.push h.con_ipaddr if h.is_ipmi

  mac_addrs = %W(#{h.macaddr})
  mac_addrs.push h.con_macaddr if h.is_ipmi

  ip_addrs.each do |ip|
    if ip !~ /^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}([01]?\d\d?|2[0-4]\d|25[0-5])$/
      session[:status] = false
      session[:msg] += "\nError in IP address format: #{ip}<br>"
    end
  end
  mac_addrs.each do |mac|
    next if mac == "NA"
    if mac !~ /^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i
      session[:status] = false
      session[:msg] += "\nError in MAC address format:  #{mac}<br>"
    end
  end
end

def validate_hostname
  fields = @name.split(/-/)

  if fields.size < 5
    if  @all_locations.include?(fields[0]) &&
        ( @all_environments.include?(fields[1].gsub(/\d+$/,''))) &&
        #   ( @all_products.include?(fields[2])) &&
        ( @all_host_roles.include?(fields[2])) &&
        ( fields[3] =~ /^\d\d\.unix.newokl.com$/ )
      @host.location = fields[0]
      @host.environment = fields[1]
      @host.product = "NA"
      @host.hostrole = fields[2]
    else
      session[:status] = false
      session[:msg] += "\nError in Host name format!"
    end
  else
    if  @all_locations.include?(fields[0]) &&
        ( @all_environments.include?(fields[1].gsub(/\d+$/,''))) &&
        ( @all_products.include?(fields[2])) &&
        ( @all_host_roles.include?(fields[3])) &&
        ( fields[4] =~ /^\d\d\.unix.newokl.com$/ )
      @host.location    = fields[0]
      @host.environment = fields[1]
      @host.product     = fields[2]
      @host.hostrole    = fields[3]
    else
      session[:status] = false
      session[:msg] += "\nError in Host name format!"
    end
  end

  if params[:host][:ipaddr] =~ /(((\d{1,3}\.){2})\d{1,3})\.\d{1,3}/
    short_root = $2.gsub!(/\.$/,'')
    @host.location = @ip_location_map[short_root]
    ns = @name_servers[@host.location]
    @host.name_server = ns
    @host.gateway = get_gateway(params[:host][:ipaddr])
    @host.boot_server = @all_boot_hosts[@host.location]
    @host.netmask = @net_masks[@host.location]
  end
end

def validate_physical_location(p)
  puts "physical location is #{p[:physical_location]}"
  if p[:physical_location] !~ /^\w{2,3}\:C\d+\:R\d+\:U\d+\-\d+$/  || p[:unit_range] == ""
    session[:status] = false
    session[:msg] += "\nError in Device Type or Physical Location"
  end
end

def get_gateway ( ip )
  netmask_file = File.open("/etc/netmasks","r")
  Rails.logger.info "here=============="
  netmask_file.each do | line |
    Rails.logger.info "- #{line}"
    line.chomp!
    next if line =~ /^#/
    network, netmask = line.split(/\s+/)
    result_network = IPAddr.new(ip).mask(netmask)
    if network.to_s == result_network.to_s
      return @ip_gate_map[network]
    end
  end
  return "NA"
end

def generate_dhcpd
  dhcpd_dir = "#{@tmp_root}/#{@synto_root}/etc"
  FileUtils.mkdir_p(dhcpd_dir) if (! File.exists?(dhcpd_dir))

  dhcpd_file = "#{dhcpd_dir}/dhcpd-hostmgr.conf"
  dhcpd = File.open(dhcpd_file,"w")

  #dhcpd = File.open(dhcpd_file,File::TRUNC|File::RDWR)
  #chunk1_file = "#{@log_root}/dhcpd.conf.chunk.1"
  #chunk1 = File.open(chunk1_file,"r")
  #dhcpd.puts chunk1.read

  @location_files.keys.each do | loc |
    next if loc == "ec2"
    next if loc == "ash"

    dhcpd_hosts = Host.where("location = ?", loc )

    #if @host.name =~ /^#{loc}/  && params["action"] != "destroy"
    if @host.location == loc  && params["action"] != "destroy"
      dhcpd_hosts.push @host  unless dhcpd_hosts.include?(@host)
    end
    dhcpd_hosts.each do | host |
      next if (params["action"] == "destroy" && @host.name == host.name)
      unless host.disabled
        dhcpd.puts <<-EOM
\thost #{host.name} {
\t\thardware ethernet #{host.macaddr};
\t\tfixed-address #{host.name};
\t\toption host-name "#{host.name}";
\t}
        EOM
      end
      if host.con_macaddr =~ /^(([[:alnum:]]{2}\:){5})([[:alnum:]]{2})$/  &&  host.is_ipmi
        dhcpd.puts <<-EOM
\thost #{host.con_name} {
\t\thardware ethernet #{host.con_macaddr};
\t\tfixed-address #{host.con_name};
\t\toption host-name "#{host.con_name}";
\t}
      EOM
      end
    end
    #dhcpd.puts "\t# hostmgr: #{@all_locations[loc]}\n}"
  end
  dhcpd.close
end

def generate_ifmgr
  #/data/synto/roots/common/etc/synto
  ifmgr_file = "#{@log_root}/common/etc/synto/ifmgr.conf"
  ifmgr = File.open(ifmgr_file, File::TRUNC|File::RDWR)
  ifmgr.puts "\# system hostname\t\tinterface name\t\tinterface hostname"

  @location_files.keys.each do |loc|
    next if loc == "ec2"
    next if loc == "ash"
    ifmgr.puts "\n#{loc.upcase}"
    loc_hosts = Host.where("location = ?", loc )
    loc_hosts.each do | h |
      #loc_file.puts "#{h.name}.unix.newokl.com"
      ifmgr.puts "#{h.name}\t\teth0:1\t\t#{h.name}-elb.unix.newokl.com"
    end
    if @host.location == loc
      ifmgr.puts "#{@host.name}\t\teth0:1\t\t#{@host.name}-elb.unix.newokl.com"
    end
  end
  ifmgr.close
end

def generate_tftp
  tftp_dir = "#{@tmp_root}/#{@synto_root}/tftpboot/netinstall/hosts.d"
  FileUtils.mkdir_p(tftp_dir) if (! File.exists?(tftp_dir))

  if Dir.entries(tftp_dir).length > 0
    Dir.foreach(tftp_dir) {|f| fn = File.join(tftp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end

  @location_files.keys.each do |loc|
    #next if loc == "ec2"
    loc_hosts = Host.where("location = ?", loc )

    #if params["action"] != "destroy"
      loc_hosts.push (@host)
    #end

    loc_hosts.each do | h |
      next if (params["action"] == "destroy" && h.name == @host.name) || h.disabled
      tftp_file = "#{tftp_dir}/#{h.name}"
      tftp = File.open(tftp_file, "w")

      hex = ip_to_hex (h.ipaddr)
      tftp.puts <<-EOM
default ks
prompt 0
timeout 20
label ks
  kernel #{h.os_version}/vmlinuz
  append ks=nfs:#{@all_boot_hosts[h.location]}:/etc/synto/netinstall/hosts.d/#{h.name}/anaconda-ks.cfg initrd=#{h.os_version}/initrd.img lang= ramdisk_size=9216 ksdevice=bootif
  IPAPPEND 2
  EOM

      cwd = Dir.pwd
      Dir.chdir(tftp_dir)
      #Rails.logger.info "Creating link...\nln -s #{h.name} #{hex}"
      #system("ln -s #{tftp_file} #{tftp_dir}/#{hex}")
      system("ln -s #{h.name} #{hex}")
      Dir.chdir(cwd)

#append ks=nfs:10.120.2.61:/etc/synto/netinstall/hosts.d/sac-prod-biapp-01.unix.newokl.com/anaconda-ks.cfg initrd=CentOS-5.9-x86_64/initrd.img lang= ramdisk_size=9216 ksdevice=eth0
    end
  end
end

def ip_to_hex (ipaddr)
  fields = ipaddr.split(/\./)
  sum = 0
  fields.length.times do | index |
    sum += (256 ** (fields.length - index - 1)) * fields[index].to_i
  end
  #sum.to_s(16).upcase
  sum = "0#{sum.to_s(16).upcase}"
end

def generate_location
  @location_files.keys.each do |loc|
    cfe_dir = "#{@tmp_root}/#{@synto_root}/etc/synto/cfengine/inputs/groups"
    FileUtils.mkdir_p(cfe_dir) if (! File.exists?(cfe_dir))
    begin
      #loc_file = File.open("#{cfe_dir}/#{@all_locations[loc]}",File::TRUNC|File::RDWR)
      loc_file = File.open("#{cfe_dir}/#{@location_files[loc]}","w")
    rescue Exception=>e
      session[:msg] += "\nError with location file: #{e}"
      session[:status] = false
      return
    end

    loc_file.puts <<-EOM
#
# cfrun directives
#
outputdir=/var/cfengine/logs
maxchild=32
## CentOS 5 Linux x86_64
    EOM
    loc_hosts = Host.where("location = ?", loc )
    loc_hosts.push @host if @host.location == loc && ! loc_hosts.include?(@host) &&  @host.synto
    loc_hosts.each do | h |
      next if (params["action"] == "destroy" && h.name == @host.name)
      loc_file.puts "#{h.name}"  if  (h.synto && ! h.disabled)
    end
    loc_file.close
  end
end

def generate_netgroup3

  netgroup_dir = "#{@tmp_root}/#{@synto_root}/etc/netgroups.d"
  FileUtils.mkdir_p(netgroup_dir) if (! File.exists?(netgroup_dir))
  all_hosts = Host.all
  all_hosts.push @host unless all_hosts.include?(@host)

  #Take this out of the loop as we don't want to re-write all user group files
  begin
    user_host_group_file = File.open("#{netgroup_dir}/u-#{@host.name}","w")
    Rails.logger.info "creating "#{netgroup_dir}/u-#{@host.name}"
  rescue Exception=>e
    session[:msg] += "\nError with opening file #{netgroup_dir}/u-#{host.name}: #{e}"
    session[:status] = false
    return
  end
  @host.user_groups.split(/:/).each do | grp |
    user_host_group_file.puts "#{grp}"
  end

  all_hosts.each do | h |
    next if (h.name == @host.name && params["action"] == "destroy") || h.disabled

    # Update all the u-<host> files for every host in db (overrides comment above)
    begin
     Rails.logger.info "creating #{netgroup_dir}/u-#{h.name}"
     user_host_group_file = File.open("#{netgroup_dir}/u-#{h.name}","w")
   rescue Exception=>e
     session[:msg] += "\nError with opening file #{netgroup_dir}/u-#{h.name}: #{e}"
     session[:status] = false
     return
   end
    h.user_groups.split(/:/).each do | grp |
      user_host_group_file.puts "#{grp}"
      Rails.logger.info "Writing #{grp} to u-#{h.name}"
    end

    begin
      triple_file = File.open("#{netgroup_dir}/#{h.name}","w")
    rescue Exception=>e
      session[:msg] += "\nError with opening file: #{e}"
      session[:status] = false
      return
    end
    #triple_file.puts("#{h.name}\t\t(#{h.name},,)")
    triple_file.puts("(#{h.name},,)")
  end

  @all_host_groups.each do | hgrp |
    begin
      host_groups_file = File.open("#{netgroup_dir}/h-#{hgrp}","w")
    rescue Exception=>e
      session[:msg] += "\nError with opening host group file h-#{hgrp}: #{e}"
      session[:status] = false
      return
    end
    all_hosts = Host.where("host_groups LIKE ?", "%#{hgrp}%")
    all_hosts.push @host if @host.host_groups =~ /#{hgrp}/ && params["action"] != "destroy" && ! all_hosts.include?(@host)
    all_hosts.each do | h |
      next if (h.name == @host.name && params["action"] == "destroy") || h.disabled
      host_groups_file.puts "#{h.name}"
    end
  end
end

def generate_netgroup2
  netgroup_dir = "#{@tmp_root}/#{@synto_root}/etc/netgroups.d"
  FileUtils.mkdir_p(netgroup_dir) if (! File.exists?(netgroup_dir))
  all_hosts = Host.all
  all_hosts.push @host

  all_hosts.each do | h |
    begin
      triple_file = File.open("#{netgroup_dir}/#{h.name}","w")
      user_host_group_file = File.open("#{netgroup_dir}/u-#{h.name}","w")
    rescue Exception=>e
      session[:msg] += "\nError with opening file: #{e}"
      session[:status] = false
      return
    end
    triple_file.puts("#{h.name}\t\t(#{h.name},,)")
    h.user_groups.split(/:/).each do | grp |
      user_host_group_file.puts "#{grp} "
    end
  end

  @all_host_groups.each do | hgrp |
    begin
      host_groups_file = File.open("#{netgroup_dir}/h-#{hgrp}","w")
    rescue Exception=>e
      session[:msg] += "\nError with opening host group file h-#{hgrp}: #{e}"
      session[:status] = false
      return
    end
    all_hosts = Host.where("host_groups LIKE ?", "%#{hgrp}%")
    all_hosts.each do | h |
      host_groups_file.puts "#{h.name} "
    end
    @host.host_groups =~ /#{hgrp}/ ? (host_groups_file.puts "#{@host.name} ") : ""
  end
end


def generate_netgroup
  netgroup_dir = "#{@tmp_root}/#{@synto_root}/etc"
  FileUtils.mkdir_p(netgroup_dir) if (! File.exists?(netgroup_dir))
  netgroup_file = "#{netgroup_dir}/netgroup"
  chunk1_file = "#{@config_root}/templates/netgroup.chunk.1"
  Rails.logger.info "Copying netgroup.chunk.1 to source tree..."
  `cp #{@sync_root}/#{@synto_root}/etc/netgroup.chunk.1 #{chunk1_file}`
  netgroup = File.open(netgroup_file,"w")
  #netgroup = File.open(netgroup_file,File::TRUNC|File::RDWR)
  chunk1 = File.open(chunk1_file,"r")
  netgroup.puts chunk1.read
  netgroup.puts <<-EOM
##
## host-to-role netgroups
##


EOM

  Host.all.each do | h |
    netgroup.puts "u-#{h.name} \\"
    netgroup.print "\t\t"
    h.user_groups.split(/:/).each do | grp |
      netgroup.print "#{grp} "
    end
    netgroup.puts
  end

  netgroup.puts "u-#{@name} \\"
  netgroup.print "\t\t"
  @host.user_groups.split(/:/).each do | grp |
    netgroup.print "#{grp} "
  end
  netgroup.puts

  netgroup.puts <<-EOM
##
## host triples
##
  EOM
  Host.all.each do | h |
    netgroup.puts "#{h.name}\t(#{h.name},,)"
  end
  netgroup.puts "#{@host.name}\t(#{@host.name},,)"
  netgroup.puts <<-EOM
##
## host groups
##

  EOM

  @all_host_groups.each do | hgrp |
    netgroup.puts "#{hgrp} \\"
    all_hosts = Host.where("host_groups LIKE ?", "%#{hgrp}%")
    index = 0
    all_hosts.each do | h |
      netgroup.print "\t #{h.name} "
      if index < all_hosts.length
        netgroup.puts "\\"
      end
    end
    @host.host_groups =~ /#{hgrp}/ ? (netgroup.puts "\t #{@host.name} ") : ""
  end
  netgroup.close
end

def test_template
  template = File.read("#{@config_root}/templates/netgroup-template.erb")
  netgroup_dir = "#{@tmp_root}/#{@synto_root}/etc"
  FileUtils.mkdir_p(netgroup_dir) if (! File.exists?(netgroup_dir))

  netgroup_file = "#{netgroup_dir}/netgroup-temp"
  #netgroup = File.open(netgroup_file,File::TRUNC|File::RDWR)
  netgroup = File.open(netgroup_file,"w")
  tmpl = Template.new
  tmpl.all_host_groups = @all_host_groups
  #tmpl.osv = host.os_version
  netgroup << ERB.new(template,nil,'->').result(tmpl.template_binding)
  netgroup.close

  #@all_host_groups.each do | hgrp |
  #  puts "#{hgrp} is hgrp"
  #  netgroup.puts "#{hgrp} \\"
  #  all_hosts = Host.where("host_groups LIKE ?", "%#{hgrp}%")
  #  index = 0
  #  all_hosts.each do | h |
  #    netgroup.print "\t #{h.name} "
  #    if index < all_hosts.length
  #      netgroup.puts "\\"
  #    end
  #  end
  #  @host.host_groups =~ /#{hgrp}/ ? (netgroup.puts "\t #{@host.name} ") : ""
  #end
end

def generate_ks
  ks_root = "#{@tmp_root}/#{@synto_root}/etc/synto/netinstall/hosts.d"
  FileUtils.mkdir_p(ks_root) if (! File.exists?(ks_root))

  @location_files.keys.each do | loc |
    loc_hosts = Host.where("location = ?", loc )
    loc_hosts.push(@host) if @host.location == loc && params["action"] != "destroy"

    loc_hosts.each do | host |

      next if (host.name == @host.name && params["action"] == "destroy") || host.disabled

      if host.ks_regen || host.name == @host.name
        tmpl = Template.new

        tmpl.oe_name = ""
        tmpl.oe_ver_maj = ""
        tmpl.arch_type = ""

        if host.os_version    =~ /(^CentOS)\-(\d)\-(.*)/i
          tmpl.oe_name    = $1
          tmpl.oe_ver_maj = $2
          tmpl.arch_type  = $3
          $2 == "5" ? tmpl.ks_end = "" : tmpl.ks_end = "%end"

          template = File.read("#{@ks_config_root}/anaconda-ks-centos-template.erb")
        #elsif host.os_version =~ /^Centos/i
        #  template = File.read("#{@ks_config_root}/templates/anaconda-ks-centos-template.erb")
        elsif host.os_version =~ /^Debian/i
          template = File.read("#{@ks_config_root}/anaconda-ks-debian-template.erb")
        elsif host.os_version =~ /^(RHEL)-(\d)-(.*)/i
          tmpl.oe_name    = $1
          tmpl.oe_ver_maj = $2
          tmpl.arch_type  = $3
          $2 == "5" ? tmpl.ks_end = "" : tmpl.ks_end = "%end"
          template = File.read("#{@ks_config_root}/anaconda-ks-redhat-template.erb")
        else
          return "unknown address"
        end
        ks_dir = "#{ks_root}/#{host.name}"
        ks_file = "#{ks_root}/#{host.name}/anaconda-ks.cfg"
        Dir.mkdir(ks_dir) if (! File.exists?(ks_dir))
        ks = File.open(ks_file,"w+")

        tmpl.ipaddr = host.ipaddr
        tmpl.nameserver = host.name_server
        tmpl.boothost = host.boot_server
        tmpl.netmask = host.netmask
        tmpl.gateipaddr = host.gateway
        tmpl.hostn = host.name
        tmpl.osv = host.os_version
        tmpl.arch_class = "i686"
        tmpl.os_type = "Linux"
        tmpl.os_ver = "XX"
        tmpl.oe_ver_maj.to_i == 7 ? tmpl.os_ver = "3.10" : tmpl.os_ver = "2.6"
        #Rails.logger.info "XXXX #{tmpl.oe_ver_maj} - #{tmpl.arch_class} - #{tmpl.os_type} - #{tmpl.oe_name} - #{tmpl.arch_type} - #{tmpl.os_ver}"

        if host.os_version =~ /Centos-([6,7])|RHEL-([6,7])/i
          tmpl.fs_type_root = "ext4"
          tmpl.fs_type_boot = "ext3"
          tmpl.short_version = "#{$1}"
        elsif host.os_version =~ /Centos-([5])|RHEL-([5])/i
          tmpl.fs_type_root = "ext3"
          tmpl.fs_type_boot = "ext2"
          tmpl.short_version = "#{$1}"
        end

        if host.root_disk == ""
          tmpl.root_disk = ""
        else
          tmpl.root_disk = "--ondisk=#{host.root_disk}"
        end

        ks << ERB.new(template).result(tmpl.template_binding)
        ks.close
      end
    end
  end
end

def generate_dns
  @dns_zones = Rails.configuration.my_scope.dns_zones
  dns_dir = "#{@tmp_root}/#{@synto_root}/var/named/chroot/var/named"
  FileUtils.mkdir_p(dns_dir) if (! File.exists?(dns_dir))
  arpa_file = "#{dns_dir}/db-10.in-addr.arpa+hostmgr"
  arpa = File.open(arpa_file,"w")

  @view_loc_map.each do | view, locations|
    dns_file = "#{dns_dir}/db-newokl.com+#{view}-private-hostmgr"
    begin
      dns = File.open(dns_file,"w")
        #dns = File.open(dns_file,File::TRUNC|File::RDWR)
    rescue Exception=>e
      session[:msg] += "\nError with location file: #{e}"
      session[:status] = false
      return
    end
    locations.each do |loc|
      loc_hosts = Host.where("location = ?", loc )
      #loc_hosts.push(@host) if @host.location == loc && params["action"] != "destroy"
      loc_hosts.push(@host) if @host.location == loc && ! loc_hosts.include?(@host)
      loc_hosts.each do | host |
        next if  host.ipaddr =~ /NA/
        next if (params["action"] == "destroy"  && @host.name == host.name)
        root_name = host.name.split(/\./)[0]
        con_name = host.con_name.split(/\./)[0]

        #dns.puts "#{root_name}.unix.newokl.com.\tIN A\t#{host.ipaddr}"
        if host.disabled
          dns.printf("%-50s%-10s%s\n", "#{root_name}.unix.newokl.com.", "IN TXT", "hostmgr:inactive")
        else
          dns.printf("%-50s%-10s%s\n", "#{root_name}.unix.newokl.com.", "IN A", "#{host.ipaddr}")
        end
        #arpa.puts "#{host.ipaddr.split(/\./).reverse.join(".")}#{spacer}IN PTR\t#{root_name}.unix.newokl.com."
        arpa.printf("%-20s%-10s%s\n", "#{host.ipaddr.split(/\./).reverse[0..2].join(".")}", "IN PTR",
                    "#{root_name}.unix.newokl.com.")

        next if host.con_ipaddr =~ /NA/  || ! host.is_ipmi
      #        dns.puts "#{con_name}.newokl.com.\tIN A\t#{host.con_ipaddr}"
        dns.printf("%-50s%-10s%s\n", "#{con_name}.newokl.com.", "IN A", "#{host.con_ipaddr}")
        arpa.printf("%-20s%-10s%s\n", "#{host.con_ipaddr.split(/\./).reverse[0..2].join(".")}", "IN PTR",
                    "#{con_name}.newokl.com.")
        #arpa.puts "#{host.con_ipaddr.split(/\./).reverse.join(".")}IN PTR#{con_name}.newokl.com."
      end
    end
  end

  #Update master files serial number,  This works but Brian wants it done manually for now.
  #@dns_zones.each do | zone |
  #  Rails.logger.info "Copying zone files to source tree..."
  #  `cp /data/synto/roots/common/var/named/chroot/var/named/db-newokl.com:#{zone} #{dns_dir}`
  #  src_zone = "#{dns_dir}/db-newokl.com:#{zone}"
  #  serial = `egrep '[0-9]{9};.*serial' #{src_zone} | cut -f5 | tr -d ";" `.to_i
  #  serial_new = (serial + 1).to_s
  #  `sed -i.bak 's/#{serial}/#{serial_new}/g' #{src_zone}`
  #end

end

def generate_nagios
  #require 'erb'
  #require File.expand_path('app/models/template.rb')
  nagios_dir = "#{@tmp_root}/#{@synto_root}/etc/nagios"
  FileUtils.mkdir_p(nagios_dir) if (! File.exists?(nagios_dir))
  nagios = File.open("#{nagios_dir}/hostgroups-hostmgr.cfg",File::TRUNC|File::RDWR)

  template =   File.read("#{@config_root}/templates/hostgroups-hostmgr-template.erb")

  tmpl = Template.new
  tmpl.group_name = "h_linux_hostmgr"
  tmpl.group_alias = "all servers managed by hostmgr"
  tmpl.group_members = ""

  @hosts = Host.all
  @hosts.push @host
  index = 1

  @hosts.sort{|a,b| b.name <=> a.name }.each do | h |
    tmpl.group_members += "#{h.name}"
    index >= @hosts.size ? (tmpl.group_members += "\n") : (tmpl.group_members += ", ")
    index += 1
  end

  nagios << ERB.new(template).result(tmpl.template_binding)
  nagios.close
end

def generate_nagios2
  nagios_dir = "#{@tmp_root}/#{@synto_root}/etc/nagios"
  FileUtils.mkdir_p(nagios_dir) if (! File.exists?(nagios_dir))
  nagios = File.open("#{nagios_dir}/hostgroups-hostmgr.cfg",File::TRUNC|File::RDWR)
  nagios.print <<-EOM
define hostgroup{\n\
\thostroup_name\th_linux_hostmgr\n\
\talias\t\tall servers managed by hostmgr
  EOM

  @hosts = Host.all
  @hosts.push @host
  index = 1
  nagios.print "\tmembers\t\t"
  @hosts.sort{|a,b| b.name <=> a.name }.each do | h |
    nagios.print "#{h.name}"
    index >= @hosts.size ? (nagios.puts "\n}") : (nagios.print ", ")
    index += 1
  end
end

def generate_icinga
  location      = @host.location
  icinga_repo   = @icinga_repos[location]
  git_dir       = "etc/icinga/configs/hosts"
  host          = @host.name.gsub(/\.unix\.newokl\.com/,'')

  curr_dir = Dir.pwd
  Dir.chdir(@tmp_root)
  FileUtils.rm_r(icinga_repo) if Dir.exist?(icinga_repo)

  begin
    system("/usr/bin/git clone github.com:/okl/#{icinga_repo}.git")
  rescue Exception=>e
    session[:msg] += "\nError with git clone: #{e}"
    session[:status] = false
    return
  end

  unless File.exists?("#{@host[:name]}.cfg")  || @host.disabled
    icinga   = File.open("#{@tmp_root}/#{icinga_repo}/#{git_dir}/#{host}.cfg","w")
    template = File.read("#{@tmp_root}/#{icinga_repo}/#{git_dir}/#{location}-base.cfg.erb")

    tmpl = Template.new
    tmpl.sfo_base = host
    icinga << ERB.new(template).result(tmpl.template_binding)
    icinga.close

    begin
      Dir.chdir("#{@tmp_root}/#{icinga_repo}/#{git_dir}")

      Rails.logger.info "/usr/bin/git commit -m\"Add #{host}\" #{host}.cfg"
      ret = `/usr/bin/git add  #{host}.cfg`
      Rails.logger.info "git add return:  #{ret}"

      Rails.logger.info "/usr/bin/git commit -m\"Add #{host}\" #{host}.cfg"
      ret = `/usr/bin/git commit -m\"Add #{host}\" #{host}.cfg`
      Rails.logger.info "git commit return:  #{ret}"
      #system("/usr/bin/git push")

      Rails.logger.info "/usr/bin/git push"
      ret =`/usr/bin/git push`
      Rails.logger.info "git push return: #{ret}"

    rescue Exception=>e
      session[:msg] += "\nError with git add/commit/push: #{e}"
      session[:status] = false
    end

    Dir.chdir(curr_dir)

  end
end

def sort_column
  Host.column_names.include?(params[:sort]) ? params[:sort] : "id"
end

def sort_direction
  %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
end



