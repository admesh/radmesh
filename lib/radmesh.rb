require 'radmesh/version'
require 'cadmesh'
require 'ffi'

# @!macro [new] returnself
#   @return [STL] returns itself

# @!macro [new] nobang
#   @note There is also the same method without ! working as expected.
#         It is not in this reference guide, because it is automatically
#         generated.

# High level wrapper around ADMesh
module RADMesh
  # Class representing an STL file.
  # It has factes and stats.
  class STL
    protected

    attr_accessor :stl_ptr
    attr_accessor :stl_value

    private

    attr_accessor :exact
    attr_accessor :shared

    public

    # @param path [String] path to the STL file to load (optional)
    # @raise [IOError] when ADMesh cannot load the file
    # @raise [NoMemoryError] when ADMesh cannot allocate empty STL struct
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

    # Checks if there is an error flag on internal ADMesh's STL structure
    #
    # @return [Boolean] whether there is and error flag
    def error?
      CADMesh.stl_get_error(@stl_ptr) == 1
    end

    # Clear the error flag on internal ADMesh's STL structure
    #
    # Only use this, if you know what you are doing.
    #
    # @macro returnself
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

    protected :error_control_proc

    # @!visibility private
    def self.finalize(ptr)
      proc { CADMesh.stl_close(ptr) }
    end

    # Get the statistics about the STL file
    #
    # @return [Hash] statistics
    def stats
      @stl_value[:stats].to_hash
    end

    # Calculate volume and save it to the stats
    #
    # @macro nobang
    # @macro returnself
    def calculate_volume!
      CADMesh.stl_calculate_volume(@stl_ptr)
      self
    end

    # Save the contents of the instance to an ASCII STL file
    #
    # @param path [String] path for the output file
    # @param label [String] label used internally in the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_ascii(path, label = 'admesh')
      CADMesh.stl_write_ascii(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Save the contents of the instance to a binary STL file
    #
    # @param path [String] path for the output file
    # @param label [String] label used internally in the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_binary(path, label = 'admesh')
      CADMesh.stl_write_binary(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Save the contents of the instance to an OBJ file
    #
    # @param path [String] path for the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_obj(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_obj(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Save the contents of the instance to an OFF file
    #
    # @param path [String] path for the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_off(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_off(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Save the contents of the instance to a DXF file
    #
    # @param path [String] path for the output file
    # @param label [String] label used internally in the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_dxf(path, label = 'admesh')
      CADMesh.stl_write_dxf(@stl_ptr, path, label)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Save the contents of the instance to a VRML file
    #
    # @param path [String] path for the output file
    # @macro returnself
    # @raise [IOError] when ADMesh cannot save the file
    def write_vrml(path)
      generate_shared_vertices! unless @shared
      CADMesh.stl_write_vrml(@stl_ptr, path)
      error_control_proc(IOError, "Could not write to #{path}").call
      self
    end

    # Check each facet of the mesh for its 3 neighbors.
    #
    # Since each facet is a triangle, there should be exactly 3
    # neighboring facets for every facet in the mesh. Since the
    # mesh defines a solid, there should be no unconnected edges
    # in the mesh. When this option is specified, the 3 neighbors
    # of every facet are searched for and, if found, the neighbors
    # are added to an internal list that keeps track of the neighbors
    # of each facet. A facet is only considered a neighbor if two of
    # its vertices EXACTLY match two of the vertices of another facet.
    # That means that there must be 0 difference between the x, y, and
    # z coordinates of the two vertices of the first facet and the two
    # vertices of the second facet.
    #
    # Degenerate facets (facets with two or more vertices equal to each
    # other) are removed during the exact check. No other changes are
    # made to the mesh.
    #
    # @macro returnself
    # @macro nobang
    def check_facets_exact!
      CADMesh.stl_check_facets_exact(@stl_ptr)
      @exact = true
      self
    end

    # Checks each unconnected facet of the mesh for facets that are
    # almost connected but not quite.
    #
    # Due to round-off errors and other
    # factors, it is common for a mesh to have facets with neighbors that
    # are very close but don't match exactly. Often, this difference is
    # only in the 8th decimal place of the vertices, but these facets will
    # not show up as neighbors during the exact check. This option finds
    # these nearby neighbors and it changes their vertices so that they
    # match exactly. {#check_facets_exact!} should always be called before
    # the nearby check,
    # so only facets that remain unconnected after the exact check are
    # candidates for the nearby check.
    #
    # @param tolerance [Float] the distance that is searched for the neighboring
    #                          facet
    # @macro returnself
    # @macro nobang
    def check_facets_nearby!(tolerance)
      CADMesh.stl_check_facets_nearby(@stl_ptr, tolerance)
      self
    end

    # Removes facets that have 0 neighbors.
    #
    # You should probably call {#check_facets_nearby!} before
    # to get better results.
    #
    # @macro returnself
    # @macro nobang
    def remove_unconnected_facets!
      CADMesh.stl_remove_unconnected_facets(@stl_ptr)
      self
    end

    # @todo Check what does this actually do :)
    #
    # @macro returnself
    # @macro nobang
    def verify_neighbors!
      CADMesh.stl_verify_neighbors(@stl_ptr)
      self
    end

    # Fill holes in the mesh by adding facets.
    #
    # This should be called after
    # {#check_facets_exact!} and {#check_facets_nearby!}.
    # If there are still unconnected facets, then facets will be added to the
    # mesh, connecting the unconnected facets, until all of the holes have
    # been filled. This is guaranteed to completely fix all unconnected facets.
    # However, the resulting mesh may or may not be what the user expects.
    #
    # @macro returnself
    # @macro nobang
    def fill_holes!
      CADMesh.stl_fill_holes(@stl_ptr)
      self
    end

    # Check and fix if necessary the directions of the facets.
    #
    # This only deals with whether the vertices of all the facets are oriented
    # clockwise or counterclockwise, it doesn't check or modify the value of
    # the normal vector. Every facet should have its vertices defined in a
    # counterclockwise order when looked at from the outside of the part.
    # This option will orient all of the vertices so that they are all facing
    # in the same direction. However, it it possible that this option will make
    # all of the facets facet inwards instead of outwards. The algorithm tries
    # to get a clue of which direction is inside and outside by checking the
    # value of the normal vector so the chance is very good that the resulting
    # mesh will be correct. However, it doesn't explicitly check to find which
    # direction is inside and which is outside.
    #
    # @macro returnself
    # @macro nobang
    def fix_normal_directions!
      CADMesh.stl_fix_normal_directions(@stl_ptr)
      self
    end

    # Checks and fixes if necessary the normal vectors of every facet.
    #
    # The normal vector will point outward for a counterclockwise facet.
    # The length of the normal vector will be 1.
    #
    # @macro returnself
    # @macro nobang
    def fix_normal_values!
      CADMesh.stl_fix_normal_values(@stl_ptr)
      self
    end

    # Reverses the directions of all of the facets and normals.
    #
    # If {#fix_normal_directions!} ended up making all of the facets facing
    # inwards instead of outwards, then this method can be used to reverse
    # all of the facets
    #
    # @macro returnself
    # @macro nobang
    def reverse_all_facets!
      CADMesh.stl_reverse_all_facets(@stl_ptr)
      self
    end

    # Generates shared vertices.
    #
    # Those are needed for some of the output formats.
    # No need to call this manually.
    #
    # @macro returnself
    # @macro nobang
    def generate_shared_vertices!
      check_facets_exact! unless @exact
      CADMesh.stl_generate_shared_vertices(@stl_ptr)
      @shared = true
      self
    end

    # @!visibility private
    def self.to_vec(arg, default = 0)
      hash = { x: default, y: default, z: default }.merge(arg)
      [hash[:x], hash[:y], hash[:z]]
    rescue
      begin
        [arg.x, arg.y, arg.z]
      rescue
        [arg[0], arg[1], arg[2]]
      end
    end

    # @!visibility private
    def self.vector_probe(args, default = 0)
      if args.size == 3
        vec = args
      elsif args.size == 1
        vec = to_vec(args[0], default)
      else
        fail ArgumentError,
             "wrong number of arguments (#{args.size} for 1 or 3)"
      end
      vec
    end

    # Translate the mesh to the position x,y,z.
    #
    # This moves the minimum x, y, and z values
    # of the mesh to the specified position.
    #
    # @param args [Array<Float>] 3 items array with coordinates
    # @param args [Float, Float, Float] 3 floats with coordinates
    # @param args [Object] object responding to .x, .y and .z
    # @param args [Hash] hash with :x, :y and :z (some can be omitted
    #                    to use 0 as default)
    # @macro returnself
    # @macro nobang
    # @raise [ArgumentError] when the arguments cannot be parsed
    def translate!(*args)
      vec = self.class.vector_probe args
      CADMesh.stl_translate(@stl_ptr, vec[0], vec[1], vec[2])
      self
    end

    # Translate the mesh by a vector x,y,z.
    #
    # This moves the mesh relatively to it's current position.
    #
    # @param args [Array<Float>] 3 items array with coordinates
    # @param args [Float, Float, Float] 3 floats with coordinates
    # @param args [Object] object responding to .x, .y and .z
    # @param args [Hash] hash with :x, :y and :z (some can be omitted
    #                    to use 0 as default)
    # @macro returnself
    # @macro nobang
    # @raise [ArgumentError] when the arguments cannot be parsed
    def translate_relative!(*args)
      vec = self.class.vector_probe args
      CADMesh.stl_translate_relative(@stl_ptr, vec[0], vec[1], vec[2])
      self
    end

    # Scale the mesh by the given factor.
    #
    # This multiplies all of the coordinates by the specified number.
    # This method could be used to change the "units" (there are no units
    # explicitly specified in an STL file) of the mesh. For example,
    # to change a part from inches to millimeters, just use factor 25.4.
    #
    # @param factor [Float] scale factor
    # @macro returnself
    # @macro nobang
    def scale!(factor)
      CADMesh.stl_scale(@stl_ptr, factor)
      self
    end

    # Scale the mesh by the given versor.
    #
    # This scales the mesh in different dimensions.
    #
    # @param args [Array<Float>] 3 items array with scale factors
    # @param args [Float, Float, Float] 3 floats with scale factors
    # @param args [Object] object responding to .x, .y and .z
    # @param args [Hash] hash with :x, :y and :z (some can be omitted
    #                    to use 1 as default)
    # @macro returnself
    # @macro nobang
    # @raise [ArgumentError] when the arguments cannot be parsed
    def scale_versor!(*args)
      vec = self.class.vector_probe args, 1
      FFI::MemoryPointer.new(:float, 3) do |p|
        p.write_array_of_float(vec)
        CADMesh.stl_scale_versor(@stl_ptr, p)
      end
      self
    end

    # Rotate the entire mesh about the X axis by the given number of degrees.
    #
    # @!macro [new] rotate
    #   The rotation is counter-clockwise about the axis as
    #   seen by looking along the positive axis towards the origin.
    #
    # @param angle [Float] angle in degrees
    # @macro returnself
    # @macro nobang
    def rotate_x!(angle)
      CADMesh.stl_rotate_x(@stl_ptr, angle)
      self
    end

    # Rotate the entire mesh about the Y axis by the given number of degrees.
    #
    # @macro rotate
    #
    # @param angle [Float] angle in degrees
    # @macro returnself
    # @macro nobang
    def rotate_y!(angle)
      CADMesh.stl_rotate_y(@stl_ptr, angle)
      self
    end

    # Rotate the entire mesh about the Z axis by the given number of degrees.
    #
    # @macro rotate
    #
    # @param angle [Float] angle in degrees
    # @macro returnself
    # @macro nobang
    def rotate_z!(angle)
      CADMesh.stl_rotate_z(@stl_ptr, angle)
      self
    end

    # Rotate the entire mesh about the given axis
    # by the given number of degrees.
    #
    # @macro rotate
    #
    # @param axis [Symbol] :x, :y or :z
    # @param angle [Float] angle in degrees
    # @macro returnself
    # @macro nobang
    # @raise [ArgumentError] when the axis is invalid
    def rotate!(axis, angle)
      send("rotate_#{axis}!", angle)
    rescue
      raise ArgumentError, "invalid axis #{axis}"
    end

    # Mirror the mesh about the XY plane.
    #
    # @!macro [new] mirror
    #   Mirroring involves reversing the sign of all of the coordinates in a
    #   particular axis. For example, to mirror a mesh about the XY plane,
    #   the signs of all of the Z coordinates in the mesh are reversed.
    #
    # @macro returnself
    # @macro nobang
    def mirror_xy!
      CADMesh.stl_mirror_xy(@stl_ptr)
      self
    end

    # Mirror the mesh about the YZ plane.
    #
    # @macro mirror
    #
    # @macro returnself
    # @macro nobang
    def mirror_yz!
      CADMesh.stl_mirror_yz(@stl_ptr)
      self
    end

    # Mirror the mesh about the XZ plane.
    #
    # @macro mirror
    #
    # @macro returnself
    # @macro nobang
    def mirror_xz!
      CADMesh.stl_mirror_xz(@stl_ptr)
      self
    end

    # Mirror the mesh about the specified plane.
    #
    # @macro mirror
    #
    # @param args [Array<Symbol>] array with 2 axis symbols
    # @param args [Symbol, Symbol] 2 axis symbols (such as :z and :x)
    # @macro returnself
    # @macro nobang
    # @raise [ArgumentError] when the plane is invalid or
    #                        the arguments could not be parsed
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

    # Merge the specified file with self.
    #
    # No translation is done, so if, for example, a file was merged with itself,
    # the resulting file would end up with two meshes exactly the same,
    # occupying exactly the same space. So generally, translations need to be
    # done to the files to be merged so that when the two meshes are merged
    # into one, the two resulting parts are properly spaced. If you know the
    # nature of the parts to be merged, it is possible to "nest" one part
    # inside the other. Note, however, that no warnings will be given if one
    # part intersects with the other.
    #
    # It is possible to place one part against another, with no space in
    # between, but you will still end up with two separately defined parts.
    # If such a mesh was made on a rapid-prototyping machine, the result
    # would depend on the nature of the machine. Machines that use a
    # photopolymer would produce a single solid part because the two parts
    # would be "bonded" during the build process. Machines that use a cutting
    # process would yield two or more parts.
    #
    # @param path [String] path to the file to merge
    # @macro returnself
    # @macro nobang
    # @raise [IOError] when the file cannot be read/parsed
    #                  (makes the object unsafe!)
    # @note Due to some limitations in the C ADMesh library, when the exception
    #       occurs it is no longer safe to touch the object. If you are not
    #       sure the file is readable and parsable, check before, or use the
    #       method without ! and throw the object away when necessary.
    def open_merge!(path)
      CADMesh.stl_open_merge(@stl_ptr, path)
      error_control_proc(IOError, "Could not open #{path}").call
      self
    end

    # @!visibility private
    def self.default_repair_opts
      { fixall: true, exact: false, tolerance: 0, increment: 0,
        nearby: false, iterations: 2, remove_unconnected: false,
        fill_holes: false, normal_directions: false,
        normal_values: false, reverse_all: false, verbose: true }
    end

    # @!visibility private
    def self.exact?(o)
      o[:exact] || o[:fixall] || o[:nearby] || o[:remove_unconnected] ||
        o[:fill_holes] || o[:normal_directions]
    end

    # @!visibility private
    def self.bools_to_ints(a)
      a.each_with_index do |value, idx|
        a[idx] = 1 if value.class == TrueClass
        a[idx] = 0 if value.class == FalseClass
      end
      a
    end

    # @!visibility private
    def self.opts_to_int_array(o)
      bools_to_ints([o[:fixall], o[:exact], o[:tolerance] != 0, o[:tolerance],
                     o[:increment] != 0, o[:increment], o[:nearby],
                     o[:iterations], o[:remove_unconnected], o[:fill_holes],
                     o[:normal_directions], o[:normal_values], o[:reverse_all],
                     o[:verbose]])
    end

    # Complex repair of the mesh.
    #
    # Does various repairing procedures on the mesh depending on the options.
    #
    # @param opts [Hash] hash with options:
    #   * *fixall* (true) - run all the fixes and ignore other flags
    #   * *exact* (false) - run {#check_facets_exact!}
    #   * *tolerance* (0) - set the tolerance level for {#check_facets_nearby!}
    #   * *increment* (0) - increment level of tolerance for each step
    #   * *nearby* (false) - run {#check_facets_nearby!}
    #   * *iterations* (2) - {#check_facets_nearby!} steps count
    #   * *remove_unconnected* (false) - run {#remove_unconnected_facets!}
    #   * *fill_holes* (false) - run {#fill_holes!}
    #   * *normal_directions* (false) - run {#fix_normal_directions!}
    #   * *normal_values* (false) - run {#fix_normal_values!}
    #   * *reverse_all* (false) - run {#reverse_all_facets!}
    #   * *verbose* (false) - be verbose to stout
    # @macro returnself
    # @macro nobang
    # @raise [RuntimeError] when something went wrong internaly
    def repair!(opts = {})
      opts = self.class.default_repair_opts.merge(opts)
      CADMesh.stl_repair(@stl_ptr, *self.class.opts_to_int_array(opts))
      error_control_proc(RuntimeError,
                         'something went wrong during repair').call
      @exact = true if self.class.exact? opts
      self
    end

    # Get the number of facets
    #
    # @return [Fixnum] number of facets
    def size
      @stl_value[:stats][:number_of_facets]
    end

    # Get a facet of given index
    #
    # @return [Hash] hash with the facet data
    def [](idx)
      fail IndexError,
           "index #{idx} outside of STL bounds: 0..#{size - 1}" if idx >= size
      ptr = @stl_value[:facet_start].to_ptr + (idx * CADMesh::STLFacet.size)
      value = CADMesh::STLFacet.new ptr
      value.to_hash
    end

    # get an enumerator for each facet
    #
    # @return [Enumerator]
    def each_facet
      return to_enum(:each_facet) unless block_given?
      idx = 0
      while idx < size
        yield self[idx]
        idx += 1
      end
    end

    # Get an array of facets
    #
    # @return [Array<Hash>]
    def to_a
      each_facet.to_a
    end

    # Get a String representation of STL
    #
    # @return [String]
    def to_s
      "#<RADMesh::STL header=\"#{stats[:header]}\">"
    end

    # @!visibility private
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

    # Crete a deep copy of the object
    #
    # @return [STL] deep copy of the object
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
