class Template
  attr_accessor :ipaddr, :boothost, :gateipaddr, :hostn, :sanipaddr, :osv, :group_name, :group_members, :group_alias,
                :nameserver, :netmask, :root_disk, :fs_type_root, :fs_type_boot, :short_version, :oe_name, :arch_type,
                :arch_class, :oe_ver_maj, :arch_type, :os_type, :os_ver, :ks_end
  # @return [Object]
  def template_binding
    binding
  end
end