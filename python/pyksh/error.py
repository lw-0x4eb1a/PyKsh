class ParseError(Exception):
	def __init__(self, message: str):
		super().__init__(message)

	def __str__(self):
		return self.message

class CompileError(Exception):
	def __init__(self, message: str):
		super().__init__(message)

	def __str__(self):
		return self.message