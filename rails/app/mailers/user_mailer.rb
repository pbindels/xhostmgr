class UserMailer < ActionMailer::Base
  default from: "netops@onekingslane.com"

  def status_email(user,login,host,site_root)
    @log_root = Rails.configuration.my_scope.log_root
    @notify = Rails.configuration.my_scope.notification_list

    @user = user
    @login = login
    @host = host
    @site_root = site_root

    notifies=@notify.dup
    notifies.push(@user)

    mail(:to => notifies, :subject => "Host \"#{@host.name}\" creation status")
  end

  def delete_email(user,login,host,site_root)
    @log_root = Rails.configuration.my_scope.log_root
    @notify = Rails.configuration.my_scope.notification_list

    @user = user
    @login = login
    @host = host
    @site_root = site_root

    notifies=@notify.dup
    notifies.push(@user)

    mail(:to => notifies, :subject => "Host \"#{@host.name}\" Deleted!")
  end
end