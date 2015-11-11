class AddEsxHostToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :esx_host, :string
  end
end
