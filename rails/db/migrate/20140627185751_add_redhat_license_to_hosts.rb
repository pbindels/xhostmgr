class AddRedhatLicenseToHosts < ActiveRecord::Migration
  def change
    add_column :hosts, :redhat_license, :string
  end
end
