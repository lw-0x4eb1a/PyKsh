''' shader variable class '''

import struct
# from collections import namedtuple
from .error import *
from .pyksh import make_uniform_var

# Float = namedtuple("Float", "name, n")
# Float._id = 0
# Float._num_bits = 4

# Vec2 = namedtuple("Vec2", "name, n")
# Vec2._id = 2
# Vec2._num_bits = 8

# Vec3 = namedtuple("Vec3", "name, n")
# Vec3._id = 3
# Vec3._num_bits = 12

# Vec4 = namedtuple("Vec4", "name, n")
# Vec4._id = 4
# Vec4._num_bits = 16

# Mat4 = namedtuple("Mat4", "name, n")
# Mat4._id = 20
# Mat4._num_bits = 64

# Sampler2D = namedtuple("Sampler2D", "name, n")
# Sampler2D._id = 43
# Sampler2D._num_bits = 0

TYPES = {
	0: "Float",
	2: "Vec2",
	3: "Vec3",
	4: "Vec4",
	20: "Mat4",
	43: "Sampler2D",
}

def build_variable(name, scope, type_id, size, data_size, data_bytes):
	assert scope == 0, f"Invalid variable scope: {scope}"
	assert data_bytes == b"\x00" * data_size

	type_specifier = TYPES.get(type_id)
	assert type_specifier, f"Invalid type_id: {type_id}"
	var =  make_uniform_var(name, type_specifier, size)
	assert data_size == get_data_size(var), f"Invalid data size: {data_size} != {get_data_size(var)}"
	return var


def get_data_size(var) -> int:
	return 0 if var.n > 1 else var.num_bits

def dumps_varliable(var) -> bytes:
	dump_u32 = lambda v: struct.pack("<I", v)
	name_bytes = var.name.encode("utf-8")
	buffer = [
		dump_u32(len(name_bytes)),
		name_bytes,
		dump_u32(0),
		dump_u32(var.id),
		dump_u32(var.n),
	]
	if not var.is_sampler_2d:
		data_size = get_data_size(var)
		buffer.append(dump_u32(data_size // 4) + b"\x00" * data_size)

	return b"".join(buffer)
