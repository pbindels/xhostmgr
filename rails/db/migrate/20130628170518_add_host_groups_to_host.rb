class AddHostGroupsToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :host_groups, :string
  end
end
