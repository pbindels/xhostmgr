require 'spec_helper'

describe "hosts/show" do
  before(:each) do
    @host = assign(:host, stub_model(Host,
      :name => "Name",
      :ipaddr => "Ipaddr",
      :location => "Location",
      :macaddr => "Macaddr",
      :groups => "Groups",
      :hostrole => "Hostrole"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Ipaddr/)
    rendered.should match(/Location/)
    rendered.should match(/Macaddr/)
    rendered.should match(/Groups/)
    rendered.should match(/Hostrole/)
  end
end
