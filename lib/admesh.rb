require 'cadmesh'
require 'ffi'

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

    def check_facets_nearby!(tolerance)
      CADMesh.stl_check_facets_nearby(@stl_ptr, tolerance)
      self
    end

    def remove_unconnected_facets!
      CADMesh.stl_remove_unconnected_facets(@stl_ptr)
      self
    end

    def verify_neighbors!
      CADMesh.stl_verify_neighbors(@stl_ptr)
      self
    end

    def fill_holes!
      CADMesh.stl_fill_holes(@stl_ptr)
      self
    end

    def fix_normal_directions!
      CADMesh.stl_fix_normal_directions(@stl_ptr)
      self
    end

    def fix_normal_values!
      CADMesh.stl_fix_normal_values(@stl_ptr)
      self
    end

    def reverse_all_facets!
      CADMesh.stl_reverse_all_facets(@stl_ptr)
      self
    end

    def generate_shared_vertices!
      check_facets_exact! unless @exact
      CADMesh.stl_generate_shared_vertices(@stl_ptr)
      @shared = true
      self
    end

    def self.to_vec(arg)
      begin
        vec = [arg[:x], arg[:y], arg[:z]]
      rescue
        begin
          vec = [arg.x, arg.y, arg.z]
        rescue
          vec = [arg[0], arg[1], arg[2]]
        end
      end
      vec
    end

    def self.vector_probe(args)
      if args.size == 3
        vec = args
      elsif args.size == 1
        vec = to_vec(args[0])
      else
        fail ArgumentError,
             "wrong number of arguments (#{args.size} for 1 or 3)"
      end
      vec
    end

    def translate!(*args)
      vec = self.class.vector_probe args
      CADMesh.stl_translate(@stl_ptr, vec[0], vec[1], vec[2])
      self
    end

    def translate_relative!(*args)
      vec = self.class.vector_probe args
      CADMesh.stl_translate_relative(@stl_ptr, vec[0], vec[1], vec[2])
      self
    end

    def scale!(factor)
      CADMesh.stl_scale(@stl_ptr, factor)
      self
    end

    def scale_versor!(*args)
      vec = self.class.vector_probe args
      FFI::MemoryPointer.new(:float, 3) do |p|
        p.write_array_of_float(vec)
        CADMesh.stl_scale_versor(@stl_ptr, p)
      end
      self
    end

    def rotate_x!(angle)
      CADMesh.stl_rotate_x(@stl_ptr, angle)
      self
    end

    def rotate_y!(angle)
      CADMesh.stl_rotate_y(@stl_ptr, angle)
      self
    end

    def rotate_z!(angle)
      CADMesh.stl_rotate_z(@stl_ptr, angle)
      self
    end

    def rotate!(axis, angle)
      send("rotate_#{axis}!", angle)
    rescue
      raise ArgumentError, "invalid axis #{axis}"
    end

    def mirror_xy!
      CADMesh.stl_mirror_xy(@stl_ptr)
      self
    end

    def mirror_yz!
      CADMesh.stl_mirror_yz(@stl_ptr)
      self
    end

    def mirror_xz!
      CADMesh.stl_mirror_xz(@stl_ptr)
      self
    end

    def mirror!(*args)
      args = args[0] if args.size == 1
      fail ArgumentError,
           "wrong number of arguments (#{args.size} for 2)" if args.size != 2
      args.sort!
      begin
        send("mirror_#{args[0]}#{args[1]}!")
      rescue
        raise ArgumentError, "invalid axis pair #{args[0]}#{args[1]}"
      end
    end

    def open_merge!(path)
      CADMesh.stl_open_merge(@stl_ptr, path)
      error_control_proc(IOError, "Could not open #{path}").call
      self
    end
  end
end
