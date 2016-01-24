require 'ffi'

# Low level wrapper around C admesh library
module CADMesh
  extend FFI::Library
  ffi_lib 'admesh.so.1.0.0'

  # for JRuby
  begin
    CharArray = FFI::StructLayout::CharArray
    InlineArray = FFI::Struct::InlineArray
  rescue NameError
    CharArray = FFI::StructLayout::CharArrayProxy
    InlineArray = FFI::StructLayout::ArrayProxy
  end

  enum :STLType, [:binary, :ascii, :inmemory]

  # FFI::Struct that has to_hash
  class HashableStruct < FFI::Struct
    def to_hash
      hash = {}
      members.each do |key|
        hash[key] = self.class.value_to_value(self[key])
      end
      hash
    end

    def self.value_to_value(value)
      return value.to_s if value.class == CharArray
      return value.to_a.map(&:to_hash) if value.class == InlineArray
      return value.to_hash if value.class <= HashableStruct
      value
    end
  end

  # stl_vertex struct
  class STLVertex < HashableStruct
    layout :x, :float,
           :y, :float,
           :z, :float
  end

  # stl_normal struct
  class STLNormal < HashableStruct
    layout :x, :float,
           :y, :float,
           :z, :float
  end

  # stl_facet struct
  class STLFacet < HashableStruct
    layout :normal, STLNormal,
           :vertex, [STLVertex, 3],
           :extra, [:char, 2]
  end

  # stl_stats struct
  class STLStats < HashableStruct
    layout :header, [:char, 81],
           :type, :STLType,
           :number_of_facets, :int,
           :max, STLVertex,
           :min, STLVertex,
           :size, STLVertex,
           :bounding_diameter, :float,
           :shortest_edge, :float,
           :volume, :float,
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
  class STLFile < HashableStruct
    layout :fp, :pointer,
           :facet_start, STLFacet.ptr,
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
  attach_function :stl_stats_out, [:pointer, :pointer, :string], :void
  attach_function :stl_print_edges, [:pointer, :pointer], :void
  attach_function :stl_print_neighbors, [:pointer, :string], :void
  attach_function :stl_put_little_int, [:pointer, :int], :void
  attach_function :stl_put_little_float, [:pointer, :float], :void
  attach_function :stl_write_ascii, [:pointer, :string, :string], :void
  attach_function :stl_write_binary, [:pointer, :string, :string], :void
  attach_function :stl_write_binary_block, [:pointer, :pointer], :void
  attach_function :stl_check_facets_exact, [:pointer], :void
  attach_function :stl_check_facets_nearby, [:pointer, :float], :void
  attach_function :stl_remove_unconnected_facets, [:pointer], :void
  attach_function :stl_write_vertex, [:pointer, :int, :int], :void
  attach_function :stl_write_facet, [:pointer, :string, :int], :void
  attach_function :stl_write_neighbor, [:pointer, :int], :void
  attach_function :stl_write_quad_object, [:pointer, :string], :void
  attach_function :stl_verify_neighbors, [:pointer], :void
  attach_function :stl_fill_holes, [:pointer], :void
  attach_function :stl_fix_normal_directions, [:pointer], :void
  attach_function :stl_fix_normal_values, [:pointer], :void
  attach_function :stl_reverse_all_facets, [:pointer], :void
  attach_function :stl_translate, [:pointer, :float, :float, :float], :void
  attach_function :stl_translate_relative, [:pointer, :float,
                                            :float, :float], :void
  attach_function :stl_scale_versor, [:pointer, :pointer], :void
  attach_function :stl_scale, [:pointer, :float], :void
  attach_function :stl_rotate_x, [:pointer, :float], :void
  attach_function :stl_rotate_y, [:pointer, :float], :void
  attach_function :stl_rotate_z, [:pointer, :float], :void
  attach_function :stl_mirror_xy, [:pointer], :void
  attach_function :stl_mirror_yz, [:pointer], :void
  attach_function :stl_mirror_xz, [:pointer], :void
  attach_function :stl_open_merge, [:pointer, :string], :void
  attach_function :stl_invalidate_shared_vertices, [:pointer], :void
  attach_function :stl_generate_shared_vertices, [:pointer], :void
  attach_function :stl_write_obj, [:pointer, :string], :void
  attach_function :stl_write_off, [:pointer, :string], :void
  attach_function :stl_write_dxf, [:pointer, :string, :string], :void
  attach_function :stl_write_vrml, [:pointer, :string], :void
  attach_function :stl_calculate_normal, [:pointer, :pointer], :void
  attach_function :stl_normalize_vector, [:pointer], :void
  attach_function :stl_calculate_volume, [:pointer], :void

  attach_function :stl_repair, [:pointer, :int, :int, :int,
                                :float, :int, :float, :int,
                                :int, :int, :int, :int, :int,
                                :int, :int], :void

  attach_function :stl_initialize, [:pointer], :void
  attach_function :stl_count_facets, [:pointer, :string], :void
  attach_function :stl_allocate, [:pointer], :void
  attach_function :stl_read, [:pointer, :int, :int], :void
  attach_function :stl_reallocate, [:pointer], :void
  attach_function :stl_add_facet, [:pointer, :pointer], :void
  attach_function :stl_get_size, [:pointer], :void

  attach_function :stl_clear_error, [:pointer], :void
  attach_function :stl_get_error, [:pointer], :int
end
