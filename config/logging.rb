require 'logger'

module SequencescapeToS2
  module Logging

    def self.logger_instance
      ::Logger.new(STDOUT)
    end

    LOGGER = logger_instance
  end
end
