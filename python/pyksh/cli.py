import argparse
import os
import time
from .shader import Shader

def cli():
	parser = argparse.ArgumentParser(prog = "pyksh", description="pyksh - ksh compiler in Python")
	parser.add_argument("file1", type=str, help="input file 1")
	parser.add_argument("file2", type=str, help="input file 2", default=None, nargs="?")
	parser.add_argument("-o", "--output", type=str, help="output file", required=False)
	parser.add_argument("-w", "--watch", action="store_true", help="watch input file changes", required=False)
	parser.add_argument("-d", "--decompile", action="store_true", help="decompile ksh to vs and ps")

	args = parser.parse_args()
	file1 = args.file1
	file2 = args.file2
	output = args.output
	decompile = args.decompile
	watch = args.watch

	if decompile:
		if not os.path.exists(file1):
			print(f"File not exists: {file1}")
			return 1
		fullpath = os.path.abspath(file1)
		dirname = os.path.dirname(fullpath)
		shader = Shader.from_file(file1)
		vs = os.path.join(dirname, shader.vs_name)
		ps = os.path.join(dirname, shader.ps_name)
		with open(vs, "w") as f:
			f.write(shader.vs_content)
			print("write: ", vs)
		with open(ps, "w") as f:
			f.write(shader.ps_content)
			print("write: ", ps)
	
		return 0
	
	mt = [0, 0]
	while True:
		for path in [file1, file2]:
			if not os.path.exists(path):
				print(f"File not exists: {path}")
				return 1

		vs, ps = None, None
		if file1.endswith(".vs"):
			vs = file1
		elif file1.endswith(".ps"):
			ps = file1
		else:
			print(f"Invalid file extension: {file1}")

		if file2.endswith(".vs"):
			vs = file2
		elif file2.endswith(".ps"):
			ps = file2
		else:
			print(f"Invalid file extension: {file2}")

		if vs is None:
			print("Vertex shader(.vs) not found")
			return 1
		if ps is None:
			print("Pixel shader(.ps) not found")
			return 1

		shader = Shader()
		shader.vs_content = open(vs).read()
		shader.ps_content = open(ps).read()
		shader.update_uniform_list()
		b = shader.dumps()
		with open(output, "wb") as f:
			f.write(b)

		if not watch:
			return 0
		
		while time.sleep(0.5) or True:
			try:
				new_mt = [os.path.getmtime(file1), os.path.getmtime(file2)]
			except:
				continue
				
			if new_mt[0] != mt[0] or new_mt[1] != mt[1]:
				mt = new_mt
				fmttime = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(max(mt)))
				print("File changed, recompiling... [" + fmttime + "]")
				break