class Template
  attr_accessor :all_host_groups, :base
  # @return [Object]
  def template_binding
    binding
  end
end
