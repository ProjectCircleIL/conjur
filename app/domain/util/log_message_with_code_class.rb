# frozen_string_literal: true

require 'util/log_message_class'

# A factory for creating a LogMessage with a code prefix
#
module Util
  class LogMessageWithCodeClass
    def self.new(msg:, code:)
      LogMessageClass.new("#{code} #{msg}")
    end
  end
end
