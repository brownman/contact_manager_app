require 'spec_helper'

describe "people/new.html.erb" do
  before(:each) do
    assign(:person, stub_model(Person,
      :new_record? => true,
      :first_name => "MyString",
      :last_name => "MyString",
      :phone_number => "MyString"
    ))
  end

  it "renders new person form" do
    render

    rendered.should have_selector("form", :action => people_path, :method => "post") do |form|
      form.should have_selector("input#person_first_name", :name => "person[first_name]")
      form.should have_selector("input#person_last_name", :name => "person[last_name]")
      form.should have_selector("input#person_phone_number", :name => "person[phone_number]")
    end
  end
end
