class AddHostTypeToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :host_type, :string
  end
end
