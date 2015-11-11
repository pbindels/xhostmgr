class AddSerialNumberToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :serial_number, :string
  end
end
