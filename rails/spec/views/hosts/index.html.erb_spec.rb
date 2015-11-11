require 'spec_helper'

describe "hosts/index" do
  before(:each) do
    assign(:hosts, [
      stub_model(Host,
        :name => "Name",
        :ipaddr => "Ipaddr",
        :location => "Location",
        :macaddr => "Macaddr",
        :groups => "Groups",
        :hostrole => "Hostrole"
      ),
      stub_model(Host,
        :name => "Name",
        :ipaddr => "Ipaddr",
        :location => "Location",
        :macaddr => "Macaddr",
        :groups => "Groups",
        :hostrole => "Hostrole"
      )
    ])
  end

  it "renders a list of hosts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Ipaddr".to_s, :count => 2
    assert_select "tr>td", :text => "Location".to_s, :count => 2
    assert_select "tr>td", :text => "Macaddr".to_s, :count => 2
    assert_select "tr>td", :text => "Groups".to_s, :count => 2
    assert_select "tr>td", :text => "Hostrole".to_s, :count => 2
  end
end
