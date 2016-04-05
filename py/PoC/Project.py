
from Base.Exceptions	import *
from Base.Project			import Project as BaseProject	#, ProjectFile

class Project(BaseProject):
	def __init__(self, name):
		super().__init__(name)

#class PoCProjectFile(ProjectFile):
#	def __init__(self, file):
#		ProjectFile.__init__(self, file)

