''' shader parser and compiler '''

import struct
import io
from .variables import *
from .error import *
from .pyksh import iter_uniforms
from pcpp.preprocessor import Preprocessor

class Shader:
	def __init__(self, *, 
		shader_name = "shader", 
		vs_name = "shader.vs", vs_content = "", 
		ps_name = "shader.ps", ps_content = "",
		uniform_list = None,
		vs_uniform_index_list = None,
		ps_uniform_index_list = None):

		self.shader_name = shader_name
		self.vs_name = vs_name
		self.vs_content = vs_content
		self.ps_name = ps_name
		self.ps_content = ps_content
		self.uniform_list = uniform_list
		self.vs_uniform_index_list = vs_uniform_index_list
		self.ps_uniform_index_list = ps_uniform_index_list
	
	@staticmethod
	def from_file(path):
		with open(path, "rb") as f:
			return Shader.load(f)

	@staticmethod
	def load(f):
		read_u32 = lambda: struct.unpack("<I", f.read(4))[0]
		read_string = lambda: f.read(read_u32()).decode("utf-8", "replace")
		
		shader_name = read_string()
		num_uniforms = read_u32()
		uniform_list = []
		for i in range(num_uniforms):
			name = read_string()
			scope = read_u32()
			type_id = read_u32()
			size = read_u32()
			if type_id != 43: # not sampler2D
				data_size = read_u32() * 4
				data_bytes = f.read(data_size)
			else:
				data_size = 0
				data_bytes = b""

			var = build_variable(name, scope, type_id, size, data_size, data_bytes)
			uniform_list.append(var)

		vs_name = read_string()
		vs_content = read_string()
		ps_name = read_string()
		ps_content = read_string()

		num_vs_uniforms = read_u32()
		vs_uniform_index_list = [read_u32() for _ in range(num_vs_uniforms)]
		num_ps_uniforms = read_u32()
		ps_uniform_index_list = [read_u32() for _ in range(num_ps_uniforms)]

		return Shader(
			shader_name = shader_name,
			vs_name = vs_name, vs_content = vs_content,
			ps_name = ps_name, ps_content = ps_content,
			uniform_list = uniform_list,
			vs_uniform_index_list = vs_uniform_index_list,
			ps_uniform_index_list = ps_uniform_index_list
		)

	def dumps(self):
		self.update_uniform_list()

		f = io.BytesIO()
		dump_u32 = lambda v: f.write(struct.pack("<I", v))
		dump_bytes = lambda b: f.write(struct.pack(f"<I{len(b)}s", len(b), b))
		dump_string = lambda s: dump_bytes(s.encode("utf-8"))

		dump_string(self.shader_name)
		dump_u32(len(self.uniform_list))
		for var in self.uniform_list:
			f.write(dumps_varliable(var))

		dump_string(self.vs_name)
		dump_string(self.vs_content)
		dump_string(self.ps_name)
		dump_string(self.ps_content)

		dump_u32(len(self.vs_uniform_index_list))
		for i in self.vs_uniform_index_list:
			dump_u32(i)
		dump_u32(len(self.ps_uniform_index_list))
		for i in self.ps_uniform_index_list:
			dump_u32(i)

		return f.getvalue()

	@staticmethod
	def extract_uniform(src: str):
		p = Preprocessor()
		p.line_directive = None
		p.parse(src)
		buffer = io.StringIO()
		p.write(buffer)
		src = buffer.getvalue()

		return iter_uniforms(src)

	def update_uniform_list(self):
		vs_uniforms = Shader.extract_uniform(self.vs_content)
		ps_uniforms = Shader.extract_uniform(self.ps_content)
		uniforms_map = {}
		for v in vs_uniforms:
			uniforms_map[v] = len(uniforms_map)
		for v in ps_uniforms:
			if v not in uniforms_map:
				uniforms_map[v] = len(uniforms_map)

		name_map = {}
		for k in uniforms_map.keys():
			if k.name in name_map:
				raise CompileError(f"Uniform variable name conflict: {k} and {name_map[k.name]}")
			else:
				name_map[k.name] = k

		vs_uniform_index_list = [uniforms_map[v] for v in vs_uniforms]
		ps_uniform_index_list = [uniforms_map[v] for v in ps_uniforms]

		uniforms_map_re = {v: k for k, v in uniforms_map.items()}
		uniform_list = []
		for i in range(len(uniforms_map_re)):
			v = uniforms_map_re[i]
			uniform_list.append(v)

		self.uniform_list = uniform_list
		self.vs_uniform_index_list = vs_uniform_index_list
		self.ps_uniform_index_list = ps_uniform_index_list
