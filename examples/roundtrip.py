'''
This example parses all *.ksh files in the `shaders` directory and compile them back.
'''

from pathlib import Path
from pyksh import Shader

for path in Path("shaders").glob("*.ksh"):
	print("Loading: ", path.name)
	s = Shader.load(open(path, "rb"))
	print(f"\tname: {s.shader_name}")
	print(f"\tvs: {s.vs_name} ({len(s.vs_content)} bytes)")
	print(f"\tps: {s.ps_name} ({len(s.ps_content)} bytes)")

	b = s.dumps()
	assert b == open(path, "rb").read(), "Roundtrip failed in " + path.name

print("\nRoundtrip successful")
