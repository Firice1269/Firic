local ast = {}


ast.NodeType = {
	PROGRAM = "Program",

	EXPRESSION = {
		BINARY  = "BinaryExpression",
		CALL    = "FunctionCall",
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
		CONTINUE = "Continue",
		LOOP     = "Loop",
		IF       = "IfStatement",
		IMPORT   = "Import",
		RETURN   = "Return",

		VARIABLE = {
			ASSIGNMENT  = "VariableAssignment",
			DECLARATION = "VariableDeclaration",
		},
	},
}


ast.Program = ast.NodeType.PROGRAM

ast.BinaryExpression  = ast.NodeType.EXPRESSION.BINARY
ast.FunctionCall      = ast.NodeType.EXPRESSION.CALL
ast.IndexExpression   = ast.NodeType.EXPRESSION.INDEX
ast.MemberExpression  = ast.NodeType.EXPRESSION.MEMBER
ast.TernaryExpression = ast.NodeType.EXPRESSION.TERNARY
ast.UnaryExpression   = ast.NodeType.EXPRESSION.UNARY

ast.Array      = ast.NodeType.LITERAL.ARRAY
ast.Dictionary = ast.NodeType.LITERAL.DICTIONARY
ast.Function   = ast.NodeType.LITERAL.FUNCTION
ast.Identifier = ast.NodeType.LITERAL.IDENTIFIER
ast.Number     = ast.NodeType.LITERAL.NUMBER
ast.String     = ast.NodeType.LITERAL.STRING

ast.Break               = ast.NodeType.STATEMENT.BREAK
ast.Continue            = ast.NodeType.STATEMENT.CONTINUE
ast.Loop                = ast.NodeType.STATEMENT.LOOP
ast.IfStatement         = ast.NodeType.STATEMENT.IF
ast.Import              = ast.NodeType.STATEMENT.IMPORT
ast.Return              = ast.NodeType.STATEMENT.RETURN
ast.VariableAssignment  = ast.NodeType.STATEMENT.VARIABLE.ASSIGNMENT
ast.VariableDeclaration = ast.NodeType.STATEMENT.VARIABLE.DECLARATION


function ast.Node(start, type, value)
	value = value or {}

	return {
		start = start,
		type  = type,
		value = value,
	}
end


return ast
