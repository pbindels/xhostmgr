class AddConNameToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :con_name, :string
  end
end
