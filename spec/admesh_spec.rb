require 'minitest/autorun'
require 'admesh'

describe ADMesh::STL do
  before do
    @stl = ADMesh::STL.new 'block.stl'
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
      [:x, :y, :z].each do |axis|
        @stl.stats[:size][axis].must_equal 1
      end
    end
    it 'must have max 1 for each axis' do
      [:x, :y, :z].each do |axis|
        @stl.stats[:max][axis].must_equal 1
      end
    end
    it 'must have min 0 for each axis' do
      [:x, :y, :z].each do |axis|
        @stl.stats[:min][axis].must_equal 0
      end
    end
    it 'must be recognized as ASCII' do
      @stl.stats[:type].must_equal :ascii
    end
    it 'must be able to write as ASCII STL' do
      @stl.write_ascii '.block_ascii.stl'
      stl_ascii = ADMesh::STL.new '.block_ascii.stl'
      stl_ascii.stats[:type].must_equal :ascii
    end
    it 'must be able to write as binary STL' do
      @stl.write_binary '.block_binary.stl'
      stl_binary = ADMesh::STL.new '.block_binary.stl'
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
  end

  describe 'when opening an non-existing file' do
    it 'must blow up' do
      proc { ADMesh::STL.new 'bad_filename.stl' }.must_raise IOError
    end
  end
end
