


def property(function):
	import sys
	import builtins
	
	keys = 'fget', 'fset', 'fdel'
	func_locals = {'doc' : function.__doc__}
	def probe_func(frame, event, arg):
		if event == 'return':
			locals = frame.f_locals
			func_locals.update(dict((k, locals.get(k)) for k in keys))
			sys.settrace(None)
		return probe_func
	sys.settrace(probe_func)
	function()
	return builtins.property(**func_locals)