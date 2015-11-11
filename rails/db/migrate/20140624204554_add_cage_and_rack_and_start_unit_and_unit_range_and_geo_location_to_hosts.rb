class AddCageAndRackAndStartUnitAndUnitRangeAndGeoLocationToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :cage, :integer
    add_column :hosts, :rack, :integer
    add_column :hosts, :start_unit, :integer
    add_column :hosts, :unit_range, :integer
    add_column :hosts, :geo_location, :string
  end
end
