require 'acceptance/acceptance_helper'


feature "Add a person to the contact book", %q{
  In order to add a person to my contact book
  I want to register a new person
} do

  scenario "Happy path" do
    visit '/people/new'

    fill_in 'First name', :with => 'John'
    fill_in 'Last name', :with => 'Doe'
    fill_in 'Phone number', :with => '(314) 142-9182'
    click_button 'Create Person'

    current_path.should match %r{/people/\d+}
  end
end
