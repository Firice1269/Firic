local ast = {}


ast.NodeType = {
	PROGRAM = "Program",

	EXPRESSION = {
		BINARY  = "BinaryExpression",
		CALL    = "CallExpression",
		INDEX   = "IndexExpression",
		MEMBER  = "MemberExpression",
		TERNARY = "TernaryExpression",
		UNARY   = "UnaryExpression",
	},

	LITERAL = {
		ARRAY      = "Array",
		DICTIONARY = "Dictionary",
		FUNCTION   = "Function",
		IDENTIFIER = "Identifier",
		NUMBER     = "Number",
		STRING     = "String",
	},

	STATEMENT = {
		BREAK    = "Break",
		CLASS    = "ClassDefinition",
		CONTINUE = "Continue",
		ENUM     = "Enum",
		LOOP     = "Loop",
		IF       = "IfStatement",
		RETURN   = "Return",
		SWITCH   = "SwitchStatement",

		VARIABLE = {
			ASSIGNMENT  = "VariableAssignment",
			DECLARATION = "VariableDeclaration",
		},
	},
}


ast.Program = ast.NodeType.PROGRAM


ast.expressions = ast.NodeType.EXPRESSION

ast.BinaryExpression  = ast.expressions.BINARY
ast.FunctionCall      = ast.expressions.CALL
ast.IndexExpression   = ast.expressions.INDEX
ast.MemberExpression  = ast.expressions.MEMBER
ast.TernaryExpression = ast.expressions.TERNARY
ast.UnaryExpression   = ast.expressions.UNARY


ast.literals = ast.NodeType.LITERAL

ast.Array      = ast.literals.ARRAY
ast.Dictionary = ast.literals.DICTIONARY
ast.Function   = ast.literals.FUNCTION
ast.Identifier = ast.literals.IDENTIFIER
ast.Number     = ast.literals.NUMBER
ast.String     = ast.literals.STRING


ast.statements = ast.NodeType.STATEMENT

ast.Break               = ast.statements.BREAK
ast.ClassDefinition     = ast.statements.CLASS
ast.Continue            = ast.statements.CONTINUE
ast.Enum                = ast.statements.ENUM
ast.Loop                = ast.statements.LOOP
ast.IfStatement         = ast.statements.IF
ast.Return              = ast.statements.RETURN
ast.SwitchStatement     = ast.statements.SWITCH
ast.VariableAssignment  = ast.statements.VARIABLE.ASSIGNMENT
ast.VariableDeclaration = ast.statements.VARIABLE.DECLARATION


function ast.Node(start, type, value)
	value = value or {}

	return {
		start = start,
		type  = type,
		value = value,
	}
end


return ast
