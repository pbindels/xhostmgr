class AddOsNameToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :os_name, :string
  end
end
