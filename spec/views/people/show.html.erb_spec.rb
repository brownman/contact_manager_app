require 'spec_helper'

describe "people/show.html.erb" do
  before(:each) do
    @person = assign(:person, stub_model(Person,
      :first_name => "First Name",
      :last_name => "Last Name",
      :phone_number => "Phone Number"
    ))
  end

  it "renders attributes in <p>" do
    render
    rendered.should contain("First Name".to_s)
    rendered.should contain("Last Name".to_s)
    rendered.should contain("Phone Number".to_s)
  end
end
