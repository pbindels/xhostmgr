class AddEnvironmentToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :environment, :string
  end
end
