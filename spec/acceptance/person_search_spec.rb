require File.dirname(__FILE__) + '/acceptance_helper'

feature "Look for a person on the contact book", %q{
  In order to find a contact rapidly on my contact book
  I want to search by first name filtering the listing
} do

  scenario "The listing has four people and I'm looking for Johnny" do
    Person.create!(:first_name => 'John', :last_name => 'Doe')
    Person.create!(:first_name => 'Johnny', :last_name => 'Baggins')
    Person.create!(:first_name => 'Sarah', :last_name => 'Jones')
    Person.create!(:first_name => 'Jessica', :last_name => 'Jones')

    visit '/people'
    save_and_open_page

    find(:css, "tr:contains('John')").should be_visible
    find(:css, "tr:contains('Johnny')").should be_visible
    find(:css, "tr:contains('Sarah')").should be_visible
    find(:css, "tr:contains('Jessica')").should be_visible

    fill_in 'Person first name', :with => 'Johnny'
    
    find(:css, "tr:contains('John')").should_not be_visible
    find(:css, "tr:contains('Johnny')").should be_visible
    find(:css, "tr:contains('Sarah')").should_not be_visible
    find(:css, "tr:contains('Jessica')").should_not be_visible
  end
end
