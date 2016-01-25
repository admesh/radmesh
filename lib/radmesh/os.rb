module RADMesh
  # helper module for determining an operating system
  # @!visibility private
  module OS
    # @!visibility private
    class << self
      def is?(what)
        what.match(RbConfig::CONFIG['host_os'])
      end
      alias is is?

      # @!visibility private
      def to_s
        RbConfig::CONFIG['host_os']
      end
    end

    module_function

    def linux?
      OS.is?(/linux|cygwin/)
    end

    def mac?
      OS.is?(/mac|darwin/)
    end

    def windows?
      OS.is?(/mswin|win|mingw/)
    end
  end
end
