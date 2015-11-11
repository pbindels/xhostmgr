class AddDisabledToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :disabled, :boolean
  end
end
