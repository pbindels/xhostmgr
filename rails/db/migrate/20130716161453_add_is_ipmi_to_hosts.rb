class AddIsIpmiToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :is_ipmi, :boolean
  end
end
