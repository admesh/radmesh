# coding: utf-8
require File.expand_path('../lib/radmesh/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'radmesh'
  s.version     = RADMesh::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Ruby wrapper around ADMesh'
  s.description = <<-eof
    ADMesh is a library for processing triangulated solid meshes.
    Currently, ADMesh only reads the STL file format that is used
    for rapid prototyping applications, although it can write STL,
    VRML, OFF, and DXF files. Those are bindings for Ruby.
    You'll need the ADMesh C library in version 0.98.x.
  eof
  s.authors     = ['Miro Hrončok']
  s.email       = 'miro@hroncok.cz'
  s.files       = Dir.glob('{doc,lib,spec}/**/*') +
  ['README.md', 'LICENSE', 'Rakefile', 'Gemfile', __FILE__]
  s.homepage =
    'https://github.com/admesh/rubygem-admesh'
  s.platform = Gem::Platform::RUBY
  s.license = 'GPL-2.0+'
end
