require 'cadmesh'

# High level wrapper around ADMesh
module ADMesh
  # STL file
  class STL
    attr_accessor :stl_ptr
    attr_accessor :stl_value
    private :stl_ptr
    private :stl_value

    def initialize(path)
      @stl_ptr = FFI::MemoryPointer.new CADMesh::STLFile, 1
      @stl_value = CADMesh::STLFile.new @stl_ptr
      CADMesh.stl_open(@stl_ptr, path)
      error_control_proc(IOError, "Could not open #{path}").call
      ObjectSpace.define_finalizer self, self.class.finalize(@stl_ptr)
    end

    def error?
      CADMesh.stl_get_error(@stl_ptr) == 1
    end

    def clear_error!
      CADMesh.stl_clear_error(@stl_ptr)
    end

    def error_control_proc(exception, message)
      proc do
        if error?
          clear_error!
          fail exception, message
        end
      end
    end

    def self.finalize(ptr)
      proc { CADMesh.stl_close(ptr) }
    end
  end
end
