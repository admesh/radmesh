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
      @stl.calculate_volume!
      @stl.stats[:volume].must_equal 1
    end
    it 'must be recognized as ASCII' do
      @stl.stats[:type].must_equal :ascii
    end
  end

  describe 'when opening an non-existing file' do
    it 'must blow up' do
      proc { ADMesh::STL.new 'bad_filename.stl' }.must_raise IOError
    end
  end
end
