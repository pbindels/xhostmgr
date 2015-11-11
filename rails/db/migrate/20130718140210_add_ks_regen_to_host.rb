class AddKsRegenToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :ks_regen, :boolean
  end
end
