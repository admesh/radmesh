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
    protected :stl_ptr, :stl_value
    private :exact, :shared

    def initialize(path = nil)
      @stl_ptr = FFI::MemoryPointer.new CADMesh::STLFile, 1
      @stl_value = CADMesh::STLFile.new @stl_ptr
      init if path.nil?
      open path unless path.nil?
      ObjectSpace.define_finalizer self, self.class.finalize(@stl_ptr)
      @exact = false
      @shared = false
    end

    def init
      CADMesh.stl_initialize(@stl_ptr)
      error_control_proc(NoMemoryError, 'Could not initialize').call
    end

    def open(path)
      CADMesh.stl_open(@stl_ptr, path)
      error_control_proc(IOError, "Could not open #{path}").call
    end

    private :init, :open

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
      hash = { x: 0, y: 0, z: 0 }.merge(arg)
      [hash[:x], hash[:y], hash[:z]]
    rescue
      begin
        [arg.x, arg.y, arg.z]
      rescue
        [arg[0], arg[1], arg[2]]
      end
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

    def self.default_repair_opts
      { fixall: true, exact: false, tolerance: 0, increment: 0,
        nearby: false, iterations: 2, remove_unconnected: false,
        fill_holes: false, normal_directions: false,
        normal_values: false, reverse_all: false, verbose: true }
    end

    def self.exact?(o)
      o[:exact] || o[:fixall] || o[:nearby] || o[:remove_unconnected] ||
        o[:fill_holes] || o[:normal_directions]
    end

    def self.bools_to_ints(a)
      a.each_with_index do |value, idx|
        a[idx] = 1 if value.class == TrueClass
        a[idx] = 0 if value.class == FalseClass
      end
      a
    end

    def self.opts_to_int_array(o)
      bools_to_ints([o[:fixall], o[:exact], o[:tolerance] != 0, o[:tolerance],
                     o[:increment] != 0, o[:increment], o[:nearby],
                     o[:iterations], o[:remove_unconnected], o[:fill_holes],
                     o[:normal_directions], o[:normal_values], o[:reverse_all],
                     o[:verbose]])
    end

    def repair!(opts = {})
      opts = self.class.default_repair_opts.merge(opts)
      CADMesh.stl_repair(@stl_ptr, *self.class.opts_to_int_array(opts))
      error_control_proc(RuntimeError,
                         'something went wrong during repair').call
      @exact = true if self.class.exact? opts
      self
    end

    def size
      @stl_value[:stats][:number_of_facets]
    end

    def [](idx)
      fail IndexError,
           "index #{idx} outside of STL bounds: 0..#{size - 1}" if idx >= size
      ptr = @stl_value[:facet_start].to_ptr + (idx * CADMesh::STLFacet.size)
      value = CADMesh::STLFacet.new ptr
      value.to_hash
    end

    def each_facet
      return to_enum(:each_facet) unless block_given?
      idx = 0
      while idx < size
        yield self[idx]
        idx += 1
      end
    end

    def to_a
      each_facet.to_a
    end

    def self.copy_bulk(src, dest, len)
      LibC.memcpy(dest, src, len)
    end

    def clone_facets!(c)
      self.class.copy_bulk(@stl_value[:facet_start].to_ptr,
                           c.stl_value[:facet_start].to_ptr,
                           size * CADMesh::STLFacet.size)
      c
    end

    def clone_neighbors!(c)
      self.class.copy_bulk(@stl_value[:neighbors_start],
                           c.stl_value[:neighbors_start],
                           size * CADMesh::STLNeighbors.size)
      c
    end

    def clone_props!(c)
      [:fp, :M, :error].each do |key|
        c.stl_value[key] = @stl_value[key]
      end
      c
    end

    def clone_stats!(c)
      self.class.copy_bulk(@stl_value[:stats].to_ptr,
                           c.stl_value[:stats].to_ptr,
                           CADMesh::STLStats.size)
      c
    end

    private :clone_facets!, :clone_neighbors!, :clone_props!, :clone_stats!

    def clone
      c = clone_props! self.class.new
      clone_stats! c
      CADMesh.stl_reallocate(c.stl_ptr)
      clone_facets! c
      clone_neighbors! c
      c.error_control_proc(NoMemoryError, 'could not clone').call
      c
    end

    # take (almost) all ! methods and create their clone on-demand copies
    instance_methods.each do |method|
      next unless method.to_s[-1] == '!'
      next if method == :!
      next if method == :clear_error!
      newmethod = proc do |*args|
        c = clone
        c.send(method, *args)
      end
      define_method(method.to_s.chomp('!').to_sym, newmethod)
    end
  end
end
