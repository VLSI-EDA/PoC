



class Exit(object):
	from sys import exit

	@classmethod
	def versionCheck(cls, version):
		from sys import version_info
		
		if (version_info < version):
			print("ERROR: Used Python interpreter is to old: %s" % version_info)
			print("Minimal required Python version is %s" % (".".join(version)))
			exit(1)

	@classmethod
	def ThisIsNoLibraryFile(cls, message):
		print("=" * 80)
		print("{: ^80s}".format(message))
		print("=" * 80)
		print()
		print("This is no library file!")
		exit(1)
	
	@classmethod
	def printException(cls, ex):
		from traceback import print_tb
		
		print("FATAL: %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print()
		exit(1)
	
	@classmethod
	def printNotImplementedException(cls, ex):
		print("ERROR: %s" % ex.message)
		print()
		exit(1)
	
	@classmethod
	def printPoCException(cls, ex):
		print("ERROR: %s" % ex.message)
		print()
		exit(1)
	
	@classmethod
	def printPoCPlatformNotSupportedException(cls, ex):
		print("ERROR: Unknown platform '%s'" % ex.message)
		print()
		exit(1)
	
	def printPoCEnvironmentException(cls, ex):
		print("ERROR: %s" % ex.message)
		print()
		print("Please run this script with it's provided wrapper or manually load the required environment before executing this script.")
		exit(1)
	
	def printPoCNotConfiguredException(cls, ex):
		print("ERROR: %s" % ex.message)
		print()
		print("Please run './poc --configure' in PoC root directory.")
		exit(1)
	