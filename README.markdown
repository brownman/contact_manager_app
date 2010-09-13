Steak + Javascript + Factories
==============================

Some days ago, I had a hard time trying to make [Steak](http://github.com/cavalle/steak) play nicely with javascript pages and content on database. This project is a demo app and a tutorial on how achieve this efficiently. Through this page I explain how to configure Steak to use a javascript environment only when needed and to choose a faster way when it doesn't, step by step. If you just need the code, jump straight to end of the page.


Steak? What's that?
-------------------

I'm not going to argue why tests are necessary. Fortunately, we reached a point where even those who not practice it agree they are important. There are many types of tests, but here we are concerned only with the Steak specialty: acceptance tests.

As they say, "Steak is like Cucumber but in plain Ruby." It is a thin layer on top of RSpec to make acceptance tests sound better. You can just add Capybara and write acceptance tests for web applications in no time. It is really easy and way faster. But things can get complicated when you deal with more variables, like factories and pages with javascript. Cucumber users faced these problems too and they came up with interesting workarounds. Let's steal these and use them with Steak!


Building the application
------------------------

To show the problem, we're going to build a simple application: a dumb contact manager (with Rails 3). It has a `Person` model, with just first and last name and a phone number.

    $ rails new contact_manager

But before we generate anything, let's first add RSpec and Steak on the project and install them. Rails 3 is new and some gems are still adapting to it, so we'll grab them directly from the source.

    # Gemfile
    group :development, :test do
      gem 'rspec', :git => 'http://github.com/rspec/rspec.git'
      gem 'rspec-rails', :git => 'http://github.com/rspec/rspec-rails.git'
      gem 'steak', :git => 'http://github.com/cavalle/steak.git'
      gem 'capybara', :git => 'http://github.com/jnicklas/capybara.git'
    end
    
    $ bundle install
    $ rails generate rspec:install
    $ rails generate steak:install

Now to the action. The easiest way to start off is generating a scaffold:

    $ rails generate scaffold person first_name:string last_name:string phone_number:string
    $ rake db:migrate

Nice. Suddenly we have a fully functional contact book, but, as we know we have many contacts, we need some way to search them. It would be great if this search was also fast, so we're going to use javascript to filter the listing as we type the contact name (I bet you cannot be faster than that, hum). It may sound complicated, but in fact it's simple: just add a input to enter the contact name and a piece of javascript code (sorry for the bloated Prototype code; I'm a jQuery guy).

    # Add this between the <h1> and <table> on app/views/people/index.html
    <fieldset>
      <legend>Search</legend>
      <%= label_tag :person_first_name %>
      <%= text_field_tag :person_first_name %>
    </fieldset>
    
    # Add this to public/javascripts/application.js
    document.observe('dom:loaded', function() {
      $('person_first_name').observe('keyup', function() {
        var value = this.value;
        $$('TABLE TR:not(:first)').each(function(el) {
          var name = el.childElements('TD')[0].innerHTML;
          if(name.match(value)) {
            el.show();
          } else {
            el.hide();
          }
        });    
      });
    });

And yay! We have a *real-time* search now. Go there, add some people and test it. The thing really works! And our toy application is built. Now, we *just* have to test it. (Yes, we're not practicing TDD here. Just here!)


The first test
--------------

There are many things to be tested, but now we're concerned only with acceptance tests. First, we're going to test if we can add a person.
    
    $ rails generate steak:spec person_create
    
    # spec/acceptance/person_create_spec.rb
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

We use Steak to generate the test for us and then we fill it with a basic scenario. Steak copies the feature header from Cucumber and adds some syntax sugar with `scenario` (equivalent to `it` from RSpec); the rest is plain Capybara. Run `rake spec:acceptance` and watch the test pass.

Testing the search
------------------

Now, let's test the cool search we've built.

    $ rails generate steak:spec person_search
    
    # spec/acceptance/person_search_spec.rb
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

Again, we use Steak to generate the boilerplate code. In this test, we add some people to the contact book (this is equivalent to use a factory, but this example is very simple and doesn't need it), then we make sure they all are showed on the initial listing and finally checks that only Johnny remains visible when his name is typed on the search box. We run `rake spec:acceptance` again, but this time the test fails: John, Sarah and Jessica remain on the page even when we are looking only for Johnny. How come? We know the script is working!

The problem is with [rack-test](http://github.com/brynary/rack-test). Capybara has many testing drivers and by default it uses rack-test, a fast and reliable API to test rack applications. The problem is rack-test just looks at the HTML code and doesn't run any javascript. So, we need to choose another driver; one that can run javascript. There are some options (look at [Capybara page](http://github.com/jnicklas/capybara)), but here we'll use the most popular one: [Selenium/Webdriver](http://github.com/rainux/selenium-webdriver). It runs the page within an actual browser (Firefox by default) and therefore can do (almost) everything an user can do. To set it up, add it to the `Gemfile` and change the driver on the acceptance helper.

    # Gemfile
    group :development, :test do
      #...
      gem 'selenium-webdriver'
      gem 'launchy'
    end
    
    # spec/acceptance/acceptance_helper.rb
    #...
    Capybara.default_driver = :selenium

Run the test again and you'll see the Rails server running and a Firefox window opening. I really recommend you to use the Firefox 4 (even the beta version), because it starts much faster. But wait, the test still fails! It seems Capybara cannot find Johnny on the page. Let's investigate it by seeing how the page looks on the browser (that's why Lauchy is there).

    # spec/acceptance/person_search_spec.rb
    # Add this line below visit '/people'
    save_and_open_page
  
The page is showed and we see why Johnny cannot be found: the listing contains just John. But that's not possible! We added four people right before visiting the page! Well, this time the problem is with transactional fixtures. To speed up the tests, Rails wraps each test on a database transaction by default. When the test finishes, the transaction is cancelled, so the fixtures are not messed up and the database is instantly ready for the next test. The problem is that two processes cannot share a transaction, so the server cannot see that the contact book has four people (they will be there only when the transaction is committed, what never happens). To make the test work, we'll have to disable transactional fixtures (and yes, this will slow down tests, but currently there's no another way to make this work).

    # spec/spec_helper.rb
    config.use_transactional_fixtures = false
    
Phew. Finally we can see the test passing.

NOTE: Some people will argue that, since this is an acceptance test, people must be created by visiting the pages and filling up the form, one by one. I agree this looks more like BDD, but there is a pragmatic part of me that prefers to set it up straight on the database because (1) it is much faster and (2) it does not cause the search to fail when the creation feature is failing.


Marking javascript tests
------------------------

Okay, the search test is right, but now the creation test is also running with Selenium, even though it doesn't use javascript. That's not good. Selenium is nice, but it is much slower than rack-test. It would be nice if we could mark the tests that need javascript and run only those with Webdriver. In fact, that is exactly what [Cucumber users do with tags](http://github.com/jnicklas/capybara/blob/master/lib/capybara/cucumber.rb). We can take advantage of [RSpec metadata](http://gist.github.com/448487) to do the same. So, let's indicate that the search uses javascript:

    # spec/acceptance/person_create_spec.rb
    scenario "The listing has four people and I'm looking for John", :js => true do

Then, before each test we have to check if it uses javascript and change the Capybara driver if it does. 

    # spec/acceptance/acceptance_helper.rb
    RSpec.configure do |config|
      config.before(:each) do        
        Capybara.current_driver = :selenium if example.metadata[:js]
      end

      config.after(:each) do
        Capybara.use_default_driver if example.metadata[:js]
      end
    end

Now Selenium is used only with javascript tests and we can erase that `Capybara.default_driver = :selenium`.


Clearing the database
---------------------

We're almost done. Before we finish, let's see the page that `save_and_open_page` generated again. There are two Johns on the listing, although we created just one on the search test. Strange. But do you remember we are creating another John on the create test? Wow, since we don't use transactional fixtures anymore, all the things we insert on the database remains there, becoming garbage at the end of each test. That is unacceptable; tests must be isolated.

On this specific case, there were no problems and if we really wanted to be isolated, we could just call `Person.delete_all` at the beginning of each test. But you can see this is a bad idea on anything bigger than that. More one gem to the rescue: [database_cleaner](http://github.com/bmabey/database_cleaner). So, that hooks we did above become a little more complex:

    # Gemfile
    group :development, :test do
      #...
      gem 'database_cleaner', :git => 'http://github.com/bmabey/database_cleaner.git'
    end

    # spec/support/javascript.rb
    RSpec.configure do |config|
      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with :truncation
      end

      config.before(:each) do
        if example.metadata[:js]
          Capybara.current_driver = :selenium
          DatabaseCleaner.strategy = :truncation
        else
          DatabaseCleaner.strategy = :transaction
          DatabaseCleaner.start
        end
      end

      config.after(:each) do
        Capybara.use_default_driver if example.metadata[:js]
        DatabaseCleaner.clean
      end
    end
    
We choose the `transaction` strategy by default and change to `truncate` if the test requires javascript: it is the best of both worlds. And, as we have a good piece of code now, it is better to move it to the file `spec/support/javascript.rb`. RSpec requires all the files on the `support` directory automatically.

Demo App and Compatibility
--------------------------

If you're lazy and doesn't want to follow the tutorial, just download this app and see the specs running (some view specs are failing, but it's a bug on RSpec: they were generated on the scaffold). The code was tested with Rails 3.0.0 on Ruby 1.9.2 and 1.8.7.


Summary
-------

So, to test pages that use javascript and database with Steak, you just have to do three steps:  
1. Add `gem 'selenium-webdriver'` to the Gemfile (if you are using Steak, you already have the others, right?).  
2. Add the file [`spec/support/javascript.rb`](http://github.com/lailsonbm/contact_manager_app/blob/master/spec/support/javascript.rb).  
3. Mark all scenarios that use javascript with `:js => true`.  
Not that bad, hum?
