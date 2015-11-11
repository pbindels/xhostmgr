class ChangeGroupsColumnToUserGroupsColumn < ActiveRecord::Migration
  def up
    rename_column :hosts, :groups, :user_groups
  end

  def down
    rename_column :hosts, :user_groups, :groups
  end
end
