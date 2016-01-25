admesh
======

ADMesh is a library for processing triangulated solid meshes.
Currently, ADMesh only reads the STL file format that is used
for rapid prototyping applications, although it can write STL,
VRML, OFF, and DXF files. Those are bindings for Ruby.

You'll need the [ADMesh C library](https://github.com/admesh/admesh/releases)
in version 0.98.x.

Usage
-----

```ruby
require 'admesh'

# load an STL file
stl = ADMesh::STL.new 'file.stl'

# observe the available methods
p stl.methods

# read the stats
p stl.stats

# see how many facets are there
p stl.size

# walk the facets
stl.each_facet do |facet|
  # get the normal
  p facet[:normal]
  # walk the vertices
  facet[:vertex].each do |vertex|
    # read the coordinates
    p vertex[:x]
    p vertex[:y]
    p vertex[:z]
  end
end

# manipulate the mesh
stl.rotate! :x, 90
stl.scale! 0.5

# repair the mesh
stl.repair!

# and save it
stl.write_binary 'block2.stl'
```

You can generate the full documentation with [yard](http://yardoc.org/).