require 'ffi'

# High level wrapper around ADMesh
module ADMesh
  # Low level wrapper around C admesh library
  module CADMesh
    extend FFI::Library
    ffi_lib 'admesh'

    enum :STLType, [:binary, :ascii, :inmemory]

    # stl_vertex struct
    class STLVertex < FFI::Struct
      layout :x, :float,
             :y, :float,
             :z, :float
    end

    # stl_stats struct
    class STLStats < FFI::Struct
      layout :header, [:char, 81],
             :type, :STLType,
             :number_of_facets, :int,
             :max, STLVertex,
             :min, STLVertex,
             :size, STLVertex,
             :bounding_diameter, :float,
             :shortest_edge, :float,
             :volume, :float,
             #:surface_area, :float,
             :number_of_blocks, :uint,
             :connected_edges, :int,
             :connected_facets_1_edge, :int,
             :connected_facets_2_edge, :int,
             :connected_facets_3_edge, :int,
             :facets_w_1_bad_edge, :int,
             :facets_w_2_bad_edge, :int,
             :facets_w_3_bad_edge, :int,
             :original_num_facets, :int,
             :edges_fixed, :int,
             :degenerate_facets, :int,
             :facets_removed, :int,
             :facets_added, :int,
             :facets_reversed, :int,
             :backwards_edges, :int,
             :normals_fixed, :int,
             :number_of_parts, :int,
             :malloced, :int,
             :freed, :int,
             :facets_malloced, :int,
             :collisions, :int,
             :shared_vertices, :int,
             :shared_malloced, :int
    end

    # stl_file struct
    class STLFile < FFI::Struct
      layout :fp, :pointer,
             :facet_start, :pointer,
             :edge_start, :pointer,
             :heads, :pointer,
             :tail, :pointer,
             :M, :int,
             :neighbors_start, :pointer,
             :v_indices, :pointer,
             :v_shared, :pointer,
             :stats, STLStats,
             :error, :char
    end

    attach_function :stl_open, [:pointer, :string], :void
    attach_function :stl_close, [:pointer], :void
  end

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
