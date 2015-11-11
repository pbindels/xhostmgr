class AddSyntoToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :synto, :boolean
  end
end
