class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :current_user
  before_filter :get_configs
  before_filter :check_action
  after_filter  :count_sync_files
  #before_filter :git_auth

  helper_method :current_user

  #def git_auth
  #  Rails.logger.info("--git_auth check: Access token for github is already set!")
  #  if session[:tok] == nil
  #    session[:tok] = ""
  #    redirect_to root_path
  #  end
  #end

  private
  def count_sync_files

  end
  private
  def check_action
    if params[:action] == "new"  && ! @admins.include?(@current_user)
       redirect_to hosts_url, status: :found, notice: "*** User \"#{@current_user}\" does not have permissions to Add or Edit a host!  Please see NetOps ***"
      end
  end

  private
  def get_configs
    @qdeploy_services       = Rails.configuration.my_scope.qdeploy_services
    @all_host_groups        = Rails.configuration.my_scope.host_groups
    #@all_user_groups    = Rails.configuration.my_scope.user_groups
    @all_locations          = Rails.configuration.my_scope.all_locations
    @location_files         = Rails.configuration.my_scope.locations
    @ip_location_map        = Rails.configuration.my_scope.ip_location_map
    @location_region_map    = Rails.configuration.my_scope.location_region_map
    @all_host_roles         = Role.all.map{ |c| c.name}
    @all_products           = Product.all.map{ |c| c.name}
    @all_esx                = Host.all.select{ |c| c.name =~ /esx/i}
    @all_environments       = Rails.configuration.my_scope.environments
    @log_root               = Rails.configuration.my_scope.log_root
    @latest_os              = Rails.configuration.my_scope.latest_os
    @all_os_versions        = Rails.configuration.my_scope.os_versions
    @all_boot_hosts         = Rails.configuration.my_scope.boot_hosts
    @icinga_repos           = Rails.configuration.my_scope.icinga_repos

    @synto_root             = Rails.configuration.my_scope.synto_root
    @hostmgr_root           = Rails.configuration.my_scope.hostmgr_root
    @tmp_root               = Rails.configuration.my_scope.tmp_root
    @archive_root           = Rails.configuration.my_scope.archive_root
    @sync_root              = Rails.configuration.my_scope.sync_root
    @live_root              = Rails.configuration.my_scope.live_root
    @config_root            = Rails.configuration.my_scope.config_root
    @ks_config_root         = Rails.configuration.my_scope.ks_config_root
    @rails_root             = Rails.configuration.my_scope.rails_root
    @site_root              = Rails.configuration.my_scope.site_root

    @ip_gate_map            = Rails.configuration.my_scope.ip_gate_map
    @net_masks              = Rails.configuration.my_scope.net_masks
    @name_servers           = Rails.configuration.my_scope.name_servers
    @dns_zones              = Rails.configuration.my_scope.dns_zones
    @dns_maps               = Rails.configuration.my_scope.dns_maps
    @view_loc_map           = Rails.configuration.my_scope.view_loc_map
    @all_user_groups        = get_all_user_groups
    @admins                 = Rails.configuration.my_scope.admins
  end

  def get_all_user_groups
    cwd = Dir.pwd
    Dir.chdir("#{@sync_root}/#{@synto_root}/etc/netgroups.d")
    groups = `ls | grep u- | grep -v \\\.com`.split(/\n/)
    Dir.chdir(cwd)
    return groups
  end

  private
  def current_user
    Rails.logger.error request.env['HTTP_REMOTE_USER']
    Rails.logger.error request.env['REMOTE_USER']
    @current_user ||=  if !request.env['HTTP_REMOTE_USER'].blank?
                         request.env['HTTP_REMOTE_USER']
                       elsif !request.env['REMOTE_USER'].blank?
                         request.env['REMOTE_USER']
                       else
                         nil
                       end
    @current_user = "admin"  if Rails.env.development?
    #@current_user = "tttt"
    puts "----------------#{@current_user} is current user"
    if @current_user.nil?
      render nothing: true,  :status => :unauthorized
      return
    end
  end
end
