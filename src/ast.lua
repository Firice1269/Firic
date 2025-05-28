local ast = {}


ast.NodeType = {
	PROGRAM = "Program",

	EXPRESSION = {
		BINARY     = "BinaryExpression",
		CALL       = "FunctionCall",
		INDEX      = "IndexExpression",
		UNARY      = "UnaryExpression",
	},

	LITERAL = {
		ARRAY      = "Array",
		DICTIONARY = "Dictionary",
		IDENTIFIER = "Identifier",
		NUMBER     = "Number",
		STRING     = "String",
	},

	STATEMENT = {
		BREAK      = "Break",
		CONTINUE   = "Continue",
		FUNCTION   = "FunctionDefinition",
		LOOP       = "Loop",
		IF         = "IfStatement",
		IMPORT     = "Import",
		RETURN     = "Return",

		VARIABLE = {
			ASSIGNMENT  = "VariableAssignment",
			DECLARATION = "VariableDeclaration",
		},
	},
}


ast.Program = ast.NodeType.PROGRAM

ast.BinaryExpression = ast.NodeType.EXPRESSION.BINARY
ast.FunctionCall     = ast.NodeType.EXPRESSION.CALL
ast.IndexExpression  = ast.NodeType.EXPRESSION.INDEX
ast.UnaryExpression  = ast.NodeType.EXPRESSION.UNARY

ast.Array      = ast.NodeType.LITERAL.ARRAY
ast.Dictionary = ast.NodeType.LITERAL.DICTIONARY
ast.Identifier = ast.NodeType.LITERAL.IDENTIFIER
ast.Number     = ast.NodeType.LITERAL.NUMBER
ast.String     = ast.NodeType.LITERAL.STRING

ast.Break               = ast.NodeType.STATEMENT.BREAK
ast.Continue            = ast.NodeType.STATEMENT.CONTINUE
ast.FunctionDefinition  = ast.NodeType.STATEMENT.FUNCTION
ast.Loop                = ast.NodeType.STATEMENT.LOOP
ast.IfStatement         = ast.NodeType.STATEMENT.IF
ast.Import              = ast.NodeType.STATEMENT.IMPORT
ast.Return              = ast.NodeType.STATEMENT.RETURN
ast.VariableAssignment  = ast.NodeType.STATEMENT.VARIABLE.ASSIGNMENT
ast.VariableDeclaration = ast.NodeType.STATEMENT.VARIABLE.DECLARATION


function ast.Node(type, value)
	value = value or {}

	return {
		type = type,
		value = value,
	}
end


return ast
