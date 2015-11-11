class AddBootServerAndNameServerAndGatewayAndNetmaskToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :name_server, :string
    add_column :hosts, :boot_server, :string
    add_column :hosts, :gateway, :string
    add_column :hosts, :netmask, :string
  end
end
