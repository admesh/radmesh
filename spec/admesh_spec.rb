require 'minitest/autorun'
require 'admesh'

describe ADMesh::STL do
  describe 'when opening an existing file' do
    it 'must initialize correctly' do
      ADMesh::STL.new 'block.stl'
    end
  end

  describe 'when opening an non-existing file' do
    it 'must blow up' do
      proc { ADMesh::STL.new 'bad_filename.stl' }.must_raise IOError
    end
  end
end
