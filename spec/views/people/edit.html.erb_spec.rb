require 'spec_helper'

describe "people/edit.html.erb" do
  before(:each) do
    @person = assign(:person, stub_model(Person,
      :new_record? => false,
      :first_name => "MyString",
      :last_name => "MyString",
      :phone_number => "MyString"
    ))
  end

  it "renders the edit person form" do
    render

    rendered.should have_selector("form", :action => person_path(@person), :method => "post") do |form|
      form.should have_selector("input#person_first_name", :name => "person[first_name]")
      form.should have_selector("input#person_last_name", :name => "person[last_name]")
      form.should have_selector("input#person_phone_number", :name => "person[phone_number]")
    end
  end
end
