'''
This example demonstrates how to iterate over all uniforms in a GLSL source code.
Note that only uniforms used are listed. (see test.vs)
'''

import pyksh

for v in pyksh.iter_uniforms(open('test.ps').read()):
    print(v)

# []
pyksh.iter_uniforms("uniform float a; uniform vec3 b; uniform mat4 c; uniform sampler2D d;")
# AST parsing error
pyksh.iter_uniforms("uniform float a; uniform vec3 b; unifrm matk; void fn(){pq+'.a;c0}")