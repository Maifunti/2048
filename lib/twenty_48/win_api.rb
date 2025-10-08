# frozen_string_literal: true

require 'fiddle/types'
require 'fiddle/import'

module Twenty48
  # @see https://docs.microsoft.com/en-us/windows/console/setconsolemode
  class WinAPi
    def enable_virtual_terminal_processing
      success, @old_mode = get_mode
      return unless success
      new_mode = @old_mode | Kernel32::VIRTUAL_TERMINAL_PROCESSING
      Kernel32::SetConsoleMode(stdout_handle, new_mode).nonzero?
    end

    def restore
      Kernel32::SetConsoleMode(stdout_handle, @old_mode).nonzero? if @old_mode
    end

    private

    def get_mode
      mode = [0].pack('L')
      success = Kernel32::GetConsoleMode(stdout_handle, mode)
      if success.nonzero?
        [true, mode.unpack('L').first]
      else
        [false]
      end
    end

    def stdout_handle
      Kernel32.GetStdHandle(Kernel32::STD_OUTPUT_HANDLE)
    end

    module Kernel32
      extend Fiddle::Importer
      dlload 'kernel32'
      include Fiddle::Win32Types

      STD_OUTPUT_HANDLE = -11
      VIRTUAL_TERMINAL_PROCESSING = 0x0004

      extern 'HANDLE GetStdHandle(DWORD)'
      extern 'DWORD SetConsoleMode(HANDLE, DWORD)'
      extern 'DWORD GetConsoleMode(HANDLE, PDWORD)'
    end
  end
end
