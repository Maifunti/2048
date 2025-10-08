# frozen_string_literal: true

module Twenty48
  module OS
    def self.win?
      host_os = RbConfig::CONFIG['host_os']
      /mswin|msys|mingw|cygwin|bccwin|wince|emc/.match?(host_os)
    end
  end
end
