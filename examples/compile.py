'''
This example demonstrates how to compile *.vs and *.ps into *.ksh file.
'''

from pyksh import Shader

s = Shader(
  shader_name = "anim",
  vs_name = "anim.vs",
  ps_name = "anim.ps",
  vs_content = open("anim.vs").read(),
  ps_content = open("anim.ps").read(),
)

with open("anim_out.ksh", "wb") as f:
  f.write(s.dumps())