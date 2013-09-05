require "smokescreen/version"

module Smokescreen
  @@critical_tests = []

  def self.configure(options = {})
    @@critical_tests = options.fetch(:critical_tests){[]}
    require "smokescreen/tasks"
  end
  
  def self.critical_tests
    @@critical_tests
  end

end
