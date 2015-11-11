class Role < ActiveRecord::Base
  attr_accessible :name
  validates_format_of :name,  :with =>  /[a-z0-9]+/  ,:message => "Lowercase characters only (/[a-z0-9])/"
end
