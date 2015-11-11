class AddPhysicalLocationToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :physical_location, :string
  end
end
