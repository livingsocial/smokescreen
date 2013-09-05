require 'rake/testtask'

namespace :test do
  namespace :smokescreen do
    
    #####
    # Rake is so weird, but to define a task all code inside the task is evaluated at definition time
    # This has lead to splitting out the methods, so that when defined they should really do nothing,
    # but when invoked they should run and output info.
    #
    # I am sure this means there is a better way to do this, but I don't know it
    ####
    def functionals_critical(test_changed_files, t)
      t.libs << "test"
      t.verbose = true
      if !test_changed_files.empty?
        t.test_files = test_changed_files
      else
        t.test_files = []
      end
    end

    def critical_test_files
      Smokescreen.critical_tests
    end

    desc 'runs most critical functional tests'
    Rake::TestTask.new("critical:functionals") do |t|
      functionals_critical(critical_test_files, t)
    end

    # this won't work until your capistrano supports fetching the currently deployed git SHA on production
    def changed_files_since_deploy
      if File.exists?("log/latest-REVISION-syntaxcheck")
        revision = File.read("log/latest-REVISION-syntaxcheck").chomp

        `git whatchanged #{revision}..HEAD`.split("\n").select{|l| l =~ /^\:/}.collect {|l| l.split("\t")[1]}.sort.uniq
      else
        puts "log/latest-REVISION-syntaxcheck not found. run 'cap fetch_currently_deployed_version' to get it"
        []
      end
    end

    # file changes detected by git diff
    def currently_changed_files
      `git status --porcelain`.split("\n").map{ |file| file.split.last }
    end

    # file changes detected by git show
    def previously_changed_files
      `git show --pretty="format:" --name-only`.split("\n")
    end

    # based on a list of files changes try to detect functional tests we should likely run
    # include test files that were directly modified
    def functionals_changed(test_changed_files, t)
      changed_controllers = []
      changed_functional_tests = []
      changed_view_directories = Set.new
      test_changed_files.each do |file|
        controller_match = file.match(/app\/controllers\/(.*).rb/)
        if controller_match
          changed_controllers << controller_match[1]
        end

        view_match = file.match(/app\/views\/(.*)\/.+\.erb/)
        if view_match
          changed_view_directories << view_match[1]
        end

        functional_test_match = file.match(/test\/functional\/(.*).rb/)
        if functional_test_match
          changed_functional_tests << functional_test_match[1]
        end
      end

      test_files = FileList['test/functional/**/*_test.rb'].select{|file| changed_controllers.any?{|controller| file.match(/test\/functional\/#{controller}_test.rb/) }} +
        FileList['test/functional/**/*_test.rb'].select{|file| changed_view_directories.any?{|view_directory| file.match(/test\/functional\/#{view_directory}_controller_test.rb/) }} +
        FileList['test/functional/**/*_test.rb'].select{|file|
        (changed_functional_tests.any?{|functional_test| file.match(/test\/functional\/#{functional_test}.rb/) } ||
         test_changed_files.any?{|changed_file| file==changed_file })
      }

      test_files = test_files.uniq
      test_files = test_files.reject{ |f| Smokescreen.critical_tests.include?(f) }

      t.libs << "test"
      t.verbose = true
      if !test_files.empty?
        t.test_files = test_files
      else
        t.test_files = []
      end
    end

   # run tests against any functional test file, that has been modified
    def functionals_changed_tests(test_changed_files, t)
      test_changed_files = test_changed_files.split("\n") if test_changed_files.is_a?(String)
      test_files = FileList['test/functional/**/*_test.rb'].select{|file| test_changed_files.any?{|changed_file| file==changed_file }}
      test_files = test_files.uniq
      test_files = test_files.reject{ |f| Smokescreen.critical_tests.include?(f) }

      t.libs << "test"
      t.verbose = true
      if !test_files.empty?
        t.test_files = test_files
      else
        t.test_files = []
      end
    end

    # based on a list of files changes try to detect unit tests we should likely run.
    # include test files that were directly modified
    def units_changed(test_changed_files, t)
      changed_models = []
      test_changed_files.each do |file|
        matched = file.match(/app\/models\/(.*).rb/)
        if matched
          changed_models << matched[1]
        end
      end
      test_files = FileList['test/unit/*_test.rb'].select{|file| 
        (changed_models.any?{|model| file.match(/test\/unit\/#{model}_test.rb/) } ||
         test_changed_files.any?{|changed_file| file==changed_file })
      }
      test_files = test_files.uniq

      t.libs << "test"
      t.verbose = true
      if !test_files.empty?
        t.test_files = test_files
      else
        t.test_files = []
      end
    end

    # run tests against any unit test file, that has been modified
    def units_changed_tests(test_changed_files, t)
      test_changed_files = test_changed_files.split("\n") if test_changed_files.is_a?(String)
      test_files = FileList['test/unit/*_test.rb'].select{|file| test_changed_files.any?{|changed_file| file==changed_file }}
      test_files = test_files.uniq

      t.libs << "test"
      t.verbose = true
      if !test_files.empty?
        t.test_files = test_files
      else
        t.test_files = []
      end
    end

    namespace :deploy do
      desc 'run most important tests as well as tests for files changed since the last deploy'
      task :all do
        Rake::Task["test:smokescreen:critical:functionals"].invoke
        Rake::Task["test:smokescreen:deploy:changed"].invoke
      end
      
      desc 'run tests related to files changed since last deploy'
      task :changed do
        Rake::Task["test:smokescreen:deploy:functionals"].invoke
        Rake::Task["test:smokescreen:deploy:units"].invoke
      end
      
      Rake::TestTask.new("functionals") do |t|
        functionals_changed(changed_files_since_deploy, t)
      end
      
      Rake::TestTask.new("units") do |t|
        units_changed(changed_files_since_deploy, t)
      end
    end

    namespace :previous do
      desc 'run most important tests as well as tests for previously changed files (last commit, git show)'
      task :all do
        Rake::Task["test:smokescreen:critical:functionals"].invoke
        Rake::Task["test:smokescreen:previous:changed"].invoke
      end

      desc 'run tests related to previously changed files (last commit, git show)'
      task :changed do
        Rake::Task["test:smokescreen:previous:functionals"].invoke
        Rake::Task["test:smokescreen:previous:units"].invoke
      end

      desc 'run previously changed test files (last commit, git show)'
      task :changed_tests do
        Rake::Task["test:smokescreen:previous:functionals:changed_tests"].invoke
        Rake::Task["test:smokescreen:previous:units:changed_tests"].invoke
      end

      Rake::TestTask.new("functionals") do |t|
        functionals_changed(previously_changed_files, t)
      end

      Rake::TestTask.new("functionals:changed_tests") do |t|
        functionals_changed_tests(previously_changed_files, t)
      end
      
      Rake::TestTask.new("units") do |t|
        units_changed(previously_changed_files, t)
      end
      
      Rake::TestTask.new("units:changed_tests") do |t|
        units_changed_tests(previously_changed_files, t)
      end
    end

    namespace :current do
      desc 'run most important tests as well as tests for currently changed files (git diff)'
      task :all do
        Rake::Task["test:smokescreen:critical:functionals"].invoke
        Rake::Task["test:smokescreen:current:changed"].invoke
      end

      desc 'run tests related to currently changed files (git diff)'
      task :changed do
        Rake::Task["test:smokescreen:current:functionals"].invoke
        Rake::Task["test:smokescreen:current:units"].invoke
      end

      desc 'run currently changed test files (git diff)'
      task :changed_tests do
        Rake::Task["test:smokescreen:current:functionals:changed_tests"].invoke
        Rake::Task["test:smokescreen:current:units:changed_tests"].invoke
        puts @results
      end

      Rake::TestTask.new("functionals") do |t|
        functionals_changed(currently_changed_files, t)
      end
      
      Rake::TestTask.new("functionals:changed_tests") do |t|
        functionals_changed_tests(currently_changed_files, t)
      end
      
      Rake::TestTask.new("units") do |t|
        units_changed(currently_changed_files, t)
      end

      Rake::TestTask.new("units:changed_tests") do |t|
        units_changed_tests(currently_changed_files, t)
      end

    end

    namespace :recent do
      desc 'run most important tests as well as recently effected tests (git diff + git show)'
      task :all do
        Rake::Task["test:smokescreen:critical:functionals"].invoke
        Rake::Task["test:smokescreen:recent:changed"].invoke
      end

      desc 'run tests for currently changed files (git diff)'
      task :changed do
        Rake::Task["test:smokescreen:recent:functionals"].invoke
        Rake::Task["test:smokescreen:recent:units"].invoke
      end

      desc 'run recently changed test files (current and previous commit test files)'
      task :changed_tests do
        Rake::Task["test:smokescreen:recent:functionals:changed_tests"].invoke
        Rake::Task["test:smokescreen:recent:units:changed_tests"].invoke
      end

      Rake::TestTask.new("functionals") do |t|
        functionals_changed((previously_changed_files + currently_changed_files).uniq, t)
      end
      
      Rake::TestTask.new("functionals:changed_tests") do |t|
        functionals_changed_tests((previously_changed_files + currently_changed_files).uniq, t)
      end
      
      Rake::TestTask.new("units") do |t|
        units_changed((previously_changed_files + currently_changed_files).uniq, t)
      end
      
      Rake::TestTask.new("units:changed_tests") do |t|
        units_changed_tests((previously_changed_files + currently_changed_files).uniq, t)
      end

    end

  end
end
