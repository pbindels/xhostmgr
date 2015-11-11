class AddProductToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :product, :string
  end
end
