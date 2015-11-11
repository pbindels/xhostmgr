class AddRootDiskToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :root_disk, :string
  end
end
