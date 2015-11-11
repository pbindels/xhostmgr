class AddConMacAddrToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :con_macaddr, :string
  end
end
