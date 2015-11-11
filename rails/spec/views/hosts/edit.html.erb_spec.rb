require 'spec_helper'

describe "hosts/edit" do
  before(:each) do
    @host = assign(:host, stub_model(Host,
      :name => "MyString",
      :ipaddr => "MyString",
      :location => "MyString",
      :macaddr => "MyString",
      :groups => "MyString",
      :hostrole => "MyString"
    ))
  end

  it "renders the edit host form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", host_path(@host), "post" do
      assert_select "input#host_name[name=?]", "host[name]"
      assert_select "input#host_ipaddr[name=?]", "host[ipaddr]"
      assert_select "input#host_location[name=?]", "host[location]"
      assert_select "input#host_macaddr[name=?]", "host[macaddr]"
      assert_select "input#host_groups[name=?]", "host[groups]"
      assert_select "input#host_hostrole[name=?]", "host[hostrole]"
    end
  end
end
