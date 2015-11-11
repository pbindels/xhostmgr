class ChangeOsNameToOsVersion < ActiveRecord::Migration
  def up
    rename_column :hosts, :os_name, :os_version
  end

  def down
    rename_column :hosts, :os_version, :os_name
  end
end
