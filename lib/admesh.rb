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
      fail IOError, "Could not open #{path}" if error?
      ObjectSpace.define_finalizer self, self.class.finalize(@stl_ptr)
    end

    def error?
      @stl_value[:error] == 1
    end

    def self.finalize(ptr)
      proc { CADMesh.stl_close(ptr) }
    end
  end
end
