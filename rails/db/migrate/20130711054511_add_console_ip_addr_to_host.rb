class AddConsoleIpAddrToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :con_ipaddr, :string
  end
end
