'''
This example demonstrates how to parse a *.ksh file using this package.
'''

from pyksh import Shader
s = Shader.from_file("anim.ksh")
print(f"shader_name: {s.shader_name}")
print()
print(f"{s.vs_name}\n{s.vs_content}")
print()
print(f"{s.ps_name}\n{s.ps_content}")
print()

with open(s.vs_name, "w") as f:
    f.write(s.vs_content)
with open(s.ps_name, "w") as f:
    f.write(s.ps_content)