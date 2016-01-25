gem 'minitest'
require 'minitest/autorun'
require 'radmesh'

describe RADMesh::STL do
  before do
    @stl = RADMesh::STL.new 'block.stl'
    @axes = [:x, :y, :z]
  end

  describe 'block.stl' do
    it 'must have 12 facets' do
      @stl.stats[:number_of_facets].must_equal 12
    end
    it 'must have "solid  admesh" header' do
      @stl.stats[:header].must_equal 'solid  admesh'
    end
    it 'must calculate volume to 1' do
      @stl.calculate_volume!.stats[:volume].must_equal 1
    end
    it 'must have size 1 for each axis' do
      @axes.each do |axis|
        @stl.stats[:size][axis].must_equal 1
      end
    end
    it 'must have max 1 for each axis' do
      @axes.each do |axis|
        @stl.stats[:max][axis].must_equal 1
      end
    end
    it 'must have min 0 for each axis' do
      @axes.each do |axis|
        @stl.stats[:min][axis].must_equal 0
      end
    end
    it 'must be recognized as ASCII' do
      @stl.stats[:type].must_equal :ascii
    end
    it 'must be able to write as ASCII STL' do
      @stl.write_ascii '.block_ascii.stl'
      stl_ascii = RADMesh::STL.new '.block_ascii.stl'
      stl_ascii.stats[:type].must_equal :ascii
    end
    it 'must be able to write as binary STL' do
      @stl.write_binary '.block_binary.stl'
      stl_binary = RADMesh::STL.new '.block_binary.stl'
      stl_binary.stats[:type].must_equal :binary
    end
    it 'must be able to write as OBJ' do
      @stl.write_obj '.block.obj'
    end
    it 'must be able to write as OFF' do
      @stl.write_off '.block.off'
    end
    it 'must be able to write as DXF' do
      @stl.write_dxf '.block.dxf'
    end
    it 'must be able to write as VRML' do
      @stl.write_vrml '.block.vrml'
    end
    it 'must check nerby facets without blow up' do
      @stl.check_facets_nearby! 0.001
    end
    it 'must remove unconnected facets without blow up' do
      @stl.remove_unconnected_facets!
    end
    it 'must verify neighbors without blow up' do
      skip 'this is very verbose'
      @stl.verify_neighbors!
    end
    it 'must fill holes without blow up' do
      @stl.fill_holes!
    end
    it 'must fix normal directions without blow up' do
      @stl.fix_normal_directions!
    end
    it 'must fix normal values without blow up' do
      @stl.fix_normal_values!
    end
    it 'must reverse all facets correctly' do
      @stl.reverse_all_facets!
      @stl.calculate_volume!.stats[:volume].must_equal(-1)
      @stl.reverse_all_facets!
      @stl.calculate_volume!.stats[:volume].must_equal 1
    end
    it 'must translate to absolute coordinates' do
      @stl.translate! 10, 20, 30
      @stl.stats[:min][:x].must_equal 10
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must translate to absolute coordinates array' do
      @stl.translate! [0, 20, 30]
      @stl.stats[:min][:x].must_equal 0
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must translate to absolute coordinates hash' do
      @stl.translate! y: 20, z: 30
      @stl.stats[:min][:x].must_equal 0
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must translate by relative coordinates' do
      @stl.translate_relative! 0, 10, 15
      @stl.translate_relative! 0, 10, 15
      @stl.stats[:min][:x].must_equal 0
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must translate by relative coordinates array' do
      @stl.translate_relative! [0, 10, 15]
      @stl.translate_relative! [0, 10, 15]
      @stl.stats[:min][:x].must_equal 0
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must translate by relative coordinates hash' do
      @stl.translate_relative! y: 10, z: 15
      @stl.translate_relative! y: 10, z: 15
      @stl.stats[:min][:x].must_equal 0
      @stl.stats[:min][:y].must_equal 20
      @stl.stats[:min][:z].must_equal 30
    end
    it 'must scale by factor' do
      @stl.scale! 50
      @axes.each do |axis|
        @stl.stats[:size][axis].must_equal 50
      end
      @stl.scale! 10
      @axes.each do |axis|
        @stl.stats[:size][axis].must_equal 500
      end
      @stl.scale!(1.0 / 500)
      @axes.each do |axis|
        @stl.stats[:size][axis].must_equal 1
      end
    end
    it 'must scale by versor' do
      @stl.scale_versor! 1, 10, 100
      @stl.stats[:size][:x].must_equal 1
      @stl.stats[:size][:y].must_equal 10
      @stl.stats[:size][:z].must_equal 100
    end
    it 'must scale by versor as array' do
      @stl.scale_versor! [1, 10, 100]
      @stl.stats[:size][:x].must_equal 1
      @stl.stats[:size][:y].must_equal 10
      @stl.stats[:size][:z].must_equal 100
    end
    it 'must scale by versor as hash' do
      @stl.scale_versor! y: 10, z: 100
      @stl.stats[:size][:x].must_equal 1
      @stl.stats[:size][:y].must_equal 10
      @stl.stats[:size][:z].must_equal 100
    end
    it 'must rotate by each axis' do
      @axes.each_with_index do |axis, idx|
        @stl.rotate!(axis, 45)
        check_axis = @axes[(idx + 1) % 3]
        @stl.stats[:size][axis].must_be_within_epsilon 1
        @stl.stats[:size][check_axis].must_be_within_epsilon 1.414
        @stl.rotate!(axis, -45)
      end
    end
    it 'must not rotate by bad axis' do
      proc { @stl.rotate! :o, 45 }.must_raise ArgumentError
    end
    it 'must mirror by each axis pair' do
      @axes.each_with_index do |axis, idx|
        a1 =  @axes[(idx + 1) % 3]
        a2 =  @axes[(idx + 2) % 3]
        @stl.mirror! a1, a2 # two arguments
        @stl.stats[:min][axis].must_equal(-1)
        @stl.stats[:max][axis].must_equal 0
        @stl.mirror! [a1, a2] # one array argument
        @stl.stats[:min][axis].must_equal 0
        @stl.stats[:max][axis].must_equal 1
      end
    end
    it 'must not mirror by too many axes' do
      proc { @stl.mirror! :x, :y, :z }.must_raise ArgumentError
    end
    it 'must not mirror by too few axes' do
      proc { @stl.mirror! :x }.must_raise ArgumentError
    end
    it 'must not mirror by bad axis' do
      proc { @stl.mirror! :x, :o }.must_raise ArgumentError
    end
    it 'must open merge other STLs' do
      @stl.translate! 10, 10, 10
      @stl.open_merge! 'block.stl'
      @stl.calculate_volume!.stats[:volume].must_equal 2
    end
    it 'must repair without blowing up' do
      @stl.repair! verbose: false
    end
    it 'must repair with set tolerance' do
      @stl.repair! tolerance: 0.2, verbose: false
    end
    it 'must have size 12' do
      @stl.size.must_equal 12
    end
    it 'must give array of size 12' do
      @stl.to_a.size.must_equal 12
    end
    it 'must access facets on index' do
      # don't rally test extra, because it might be random rubbish
      @stl[5].merge(extra: '  ').must_equal normal: { x: 0, y: -1, z: -0 },
                                            vertex: [{ x: 1, y: 0, z: 1 },
                                                     { x: 0, y: 0, z: 0 },
                                                     { x: 1, y: 0, z: 0 }],
                                            extra: '  '
    end
    it 'must blow up when accessing facets on index out of range' do
      proc { @stl[13] }.must_raise IndexError
    end
    it 'must walk facets' do
      count = 0
      @stl.each_facet do |facet|
        facet.must_be_kind_of Hash
        count += 1
      end
      count.must_equal 12
    end
    it 'must clone properly' do
      other = @stl.clone
      idx = 0
      while idx < @stl.size
        @stl[idx].merge(extra: '  ').must_equal other[idx].merge(extra: '  ')
        idx += 1
      end
      other.scale! 10
      other.stats[:size][:z].must_equal 10
      @stl.stats[:size][:z].must_equal 1
      other.stats[:header].must_equal @stl.stats[:header]
    end
    it 'must have clone on-demand methods' do
      @stl.scale(10).stats[:size][:x].must_equal 10
      @stl.stats[:size][:x].must_equal 1

      @stl.mirror(:x, :y).stats[:min][:z].must_equal(-1)
      @stl.stats[:min][:z].must_equal 0

      @stl.translate_relative(x: 5).stats[:min][:x].must_equal 5
      @stl.stats[:min][:x].must_equal 0
    end
    it 'must have normal string representation' do
      @stl.to_s.must_equal '#<RADMesh::STL header="solid  admesh">'
    end
  end

  describe 'when opening an non-existing file' do
    it 'must blow up' do
      proc { RADMesh::STL.new 'bad_filename.stl' }.must_raise IOError
    end
  end

  describe 'when having an empty STL' do
    it 'must initialize fine' do
      RADMesh::STL.new
    end
    it 'must open merge fine' do
      stl = RADMesh::STL.new
      stl.open_merge! 'block.stl'
      stl.stats[:size][:x].must_equal 1
    end
  end
end
