require 'cadmesh'

# High level wrapper around ADMesh
module ADMesh
  # STL file
  class STL
    attr_accessor :stl_ptr
    attr_accessor :stl_value
    attr_accessor :exact
    attr_accessor :shared
    private :stl_ptr
    private :stl_value
    private :exact
    private :shared

    def initialize(path)
      @stl_ptr = FFI::MemoryPointer.new CADMesh::STLFile, 1
      @stl_value = CADMesh::STLFile.new @stl_ptr
      CADMesh.stl_open(@stl_ptr, path)
      error_control_proc(IOError, "Could not open #{path}").call
      ObjectSpace.define_finalizer self, self.class.finalize(@stl_ptr)
      @exact = false
      @shared = false
    end

    def error?
      CADMesh.stl_get_error(@stl_ptr) == 1
    end

    def clear_error!
      CADMesh.stl_clear_error(@stl_ptr)
      self
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

    def stats
      @stl_value[:stats].to_hash
    end

    def calculate_volume!
      CADMesh.stl_calculate_volume(@stl_ptr)
      self
    end

    def write_ascii(path, label = 'admesh')
      CADMesh.stl_write_ascii(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def write_binary(path, label = 'admesh')
      CADMesh.stl_write_binary(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def write_obj(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_obj(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def write_off(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_off(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def write_dxf(path, label = 'admesh')
      CADMesh.stl_write_dxf(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def write_vrml(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_vrml(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    def check_facets_exact!
      CADMesh.stl_check_facets_exact(@stl_ptr)
      @exact = true
      self
    end

    def generate_shared_vertices!
      check_facets_exact! unless @exact
      CADMesh.stl_generate_shared_vertices(@stl_ptr)
      @shared = true
      self
    end
  end
end
