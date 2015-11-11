class CreateHosts < ActiveRecord::Migration
  def change
    create_table :hosts do |t|
      t.string :name
      t.string :ipaddr
      t.string :location
      t.string :macaddr
      t.string :groups
      t.string :hostrole

      t.timestamps
    end
  end
end
