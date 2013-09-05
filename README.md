# Smokescreen

Quickly run critical tests on your app, recently changed tests, or tests related to recent changed files

## Installation

Add this line to your application's Gemfile:

    gem 'smokescreen'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smokescreen
    

## Usage

Setting up smokescreen is fairly easy, include the gem in your `Gemfile`, and then require it in your primary `Rakefile` or in any of your `lib/tasks/other_rakefiles`.

	#in Gemfile
    group :development, :test do
      gem 'smokescreen'
    end

	#in a Rakefile
    require 'smokescreen'
    
	#below require in rake file
    Smokescreen.configure(:critical_tests => ["test/functional/purchases_controller_test.rb", "test/functional/important_controller_test.rb"])
    
After you require smokescreen make sure to configure the critical tests. Just pass in an array of tests that you want to be be considered part of the critical set of tests. 
    
### After configuring Smokescreen

You can view all the tasks together running `bundle exec rake -T smoke`, as you can tell there are four main groupings of tests current, deploy, previous, and recent. 


	rake test:smokescreen:critical:functionals                # Run tests for critical:functionals
	rake test:smokescreen:current:all                         # run most important tests as well as tests for current...
	rake test:smokescreen:current:changed                     # run tests related to currently changed files (git diff)
	rake test:smokescreen:current:changed_tests               # run currently changed test files (git diff)
	rake test:smokescreen:current:functionals                 # Run tests for functionals
	rake test:smokescreen:current:functionals:changed_tests   # Run tests for functionals:changed_tests
	rake test:smokescreen:current:units                       # Run tests for units
	rake test:smokescreen:current:units:changed_tests         # Run tests for units:changed_tests
	rake test:smokescreen:deploy:all                          # run most important tests as well as tests for files c...
	rake test:smokescreen:deploy:changed                      # run tests related to files changed since last deploy
	rake test:smokescreen:deploy:functionals                  # Run tests for functionals
	rake test:smokescreen:deploy:units                        # Run tests for units
	rake test:smokescreen:previous:all                        # run most important tests as well as tests for previou...
	rake test:smokescreen:previous:changed                    # run tests related to previously changed files (last c...
	rake test:smokescreen:previous:changed_tests              # run previously changed test files (last commit, git s...
	rake test:smokescreen:previous:functionals                # Run tests for functionals
	rake test:smokescreen:previous:functionals:changed_tests  # Run tests for functionals:changed_tests
	rake test:smokescreen:previous:units                      # Run tests for units
	rake test:smokescreen:previous:units:changed_tests        # Run tests for units:changed_tests
	rake test:smokescreen:recent:all                          # run most important tests as well as recently effected...
	rake test:smokescreen:recent:changed                      # run tests for currently changed files (git diff)
	rake test:smokescreen:recent:changed_tests                # run recently changed test files (current and previous...
	rake test:smokescreen:recent:functionals                  # Run tests for functionals
	rake test:smokescreen:recent:functionals:changed_tests    # Run tests for functionals:changed_tests
	rake test:smokescreen:recent:units                        # Run tests for units
	rake test:smokescreen:recent:units:changed_tests          # Run tests for units:changed_tests


### Running Smokescreen

The most common task I run is `rake test:smokescreen:recent:all`, as it is the most comprehensive. That task runs the critical tests, test files related to currently change files (as found by git diff), and test files related to recently changed files (as found by git show). It is easy to target more specifically if you choose.

I also find running `rake test:smokescreen:previous:changed_tests` or `rake test:smokescreen:previous:all` handy when doing code review on another developers cherry-picked commit. Making sure the tests don't have one of the "it works on my machine" bugs.

Smokescreen has only been used on a small set of projects, and doesn't currently support anything other than `test:unit`. I know now that it is extracted out that I plan to add it to some other projects and hopefully it will be easy to make some improvements to the tool. I already know there could be some great improvements to the process of matching up likely related test files to recent changes. Adding support to run any recently failing tests from CI would also be another great feature.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
