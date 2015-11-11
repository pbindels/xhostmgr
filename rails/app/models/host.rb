class Host < ActiveRecord::Base
  attr_accessible :host_groups, :user_groups, :hostrole, :ipaddr, :location, :macaddr, :name, :product, :environment,
                  :con_ipaddr, :con_macaddr, :con_name, :os_version, :serial_number, :is_ipmi, :name_server,
                  :boot_server, :gateway, :netmask, :ks_regen, :root_disk, :manual_host, :synto, :physical_location,
                  :cage, :esx_host, :rack, :geo_location, :start_unit, :unit_range, :host_type, :redhat_license,
                  :disabled, :ks_end

  validates :name, presence: true, uniqueness: true
  validates :os_version, presence: true
  validates :ipaddr, presence: true, uniqueness: true
  validates :macaddr, presence: true, uniqueness: true, unless: :existing_host?
  validates :con_ipaddr, presence: true, uniqueness: true, if: :ipmi?
  validates :con_macaddr, presence: true, uniqueness: true, if: :ipmi?
  validates :con_name, presence: true,  unless: :ipmi?
  validates :serial_number, uniqueness: true
  validates :host_groups, presence: true
  validates :user_groups, presence: true

  def existing_host?
    macaddr =~ /^NA/
  end

  def ipmi?
    is_ipmi
  end

end
