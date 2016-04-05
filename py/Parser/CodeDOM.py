
class CodeDOMObject:
	def __init__(self):
		self._parent =	None
	
	@property
	def Parent(self):
		return self._parent
	
class Statement(CodeDOMObject):
	pass

class BlockStatement(Statement):
	pass

class Expression(CodeDOMObject):
	pass

class Operator(Expression):
	pass

class UnaryOperator(Operator):
	pass

class PreUnaryOperator(UnaryOperator):
	pass

class ComplementOperator(PreUnaryOperator):
	pass

class NotOperator(PreUnaryOperator):
	pass

class NegativeOperator(PreUnaryOperator):
	pass

class PositiveOperator(PreUnaryOperator):
	pass

class IncrementOperator(PreUnaryOperator):
	pass

class DecrementOperator(PreUnaryOperator):
	pass

class PostUnaryOperator(UnaryOperator):
	pass

class PostIncrementOperator(PostUnaryOperator):
	pass

class PostDecrementOperator(PostUnaryOperator):
	pass

class BinaryOperator(Operator):
	pass

class Assignment(BinaryOperator):
	pass

class BinaryArithmeticOperator(BinaryOperator):
	pass

class AddOperator(BinaryArithmeticOperator):
	pass

class SubtractOperator(BinaryArithmeticOperator):
	pass

class MultiplyOperator(BinaryArithmeticOperator):
	pass

class DivideOperator(BinaryArithmeticOperator):
	pass

class IntegerDivideOperator(BinaryArithmeticOperator):
	pass

class ModuloOperator(BinaryArithmeticOperator):
	pass

class RemainerOperator(BinaryArithmeticOperator):
	pass

class PowerOperator(BinaryArithmeticOperator):
	pass

class BinaryBitwiseOperator(BinaryOperator):
	pass

class BitwiseAndOperator(BinaryBitwiseOperator):
	pass

class BitwiseNandOperator(BinaryBitwiseOperator):
	pass

class BitwiseOrOperator(BinaryBitwiseOperator):
	pass

class BitwiseNorOperator(BinaryBitwiseOperator):
	pass

class BitwiseXorOperator(BinaryBitwiseOperator):
	pass

class BitwiseXnorOperator(BinaryBitwiseOperator):
	pass

class BinaryShiftOperator(BinaryBitwiseOperator):
	pass

class ShiftLeftOperator(BinaryShiftOperator):
	pass

class ShiftRightOperator(BinaryShiftOperator):
	pass

class BinaryBooleanOperator(BinaryOperator):
	pass

class BooleanAndOperator(BinaryBooleanOperator):
	pass

class BooleanOrOperator(BinaryBooleanOperator):
	pass

class BooleanNandOperator(BinaryBooleanOperator):
	pass

class BooleanNorOperator(BinaryBooleanOperator):
	pass

class BooleanXorOperator(BinaryBooleanOperator):
	pass

class BooleanXnorOperator(BinaryBooleanOperator):
	pass

class BooleanIsOperator(BinaryBooleanOperator):
	pass

class BooleanIsNotOperator(BinaryBooleanOperator):
	pass

class RelationalOperator(BinaryBooleanOperator):
	pass

class RelationalEqualOperator(RelationalOperator):
	pass

class RelationalUnequalOperator(RelationalOperator):
	pass

class RelationalGreaterThanOperator(RelationalOperator):
	pass

class RelationalGreaterThanEqualOperator(RelationalOperator):
	pass

class RelationalLessThanOperator(RelationalOperator):
	pass

class RelationalLessThanEqualOperator(RelationalOperator):
	pass

class TernaryOperator(Operator):
	pass

class ConditionalOperator(Operator):
	pass
	
class SymbolicReference(Expression):
	pass

class TypeReferenceBase(SymbolicReference):
	pass

class VariableReference(SymbolicReference):
	pass

class NamespaceReference(SymbolicReference):
	pass

class Literal(Expression):
	pass

class Namespace(CodeDOMObject):
	pass

class RootNamespace(Namespace):
	pass

class NamespaceTypeDirectory:
	pass

class NamespaceTypeGroup:
	pass

class NamedCodeObjectDirectory:
	pass

class NamedCodeObjectGroup:
	pass

class IBlock:
	pass

class INamedCodeObject:
	pass

class IParameters:
	pass

class ITypeDeclaration:
	pass
	