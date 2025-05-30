local tokens = {}


tokens.TokenType = {
	END_OF_FILE = "end-of-file",
	END_OF_LINE = "end-of-line",
	IDENTIFIER  = "identifier",
	KEYWORD     = "keyword",
	PUNCTUATION = "punctuation",

	LITERAL = {
		BOOLEAN        = "boolean-literal",
		FLOATING_POINT = "floating-point-literal",
		INTEGER        = "integer-literal",
		NULL           = "null-literal",
		STRING         = "string-literal",
	},

	OPERATOR = {
		ARITHMETIC    = "arithmetic-operator",
		ASSIGNMENT    = "assignment-operator",
		BITWISE       = "bitwise-operator",
		COMPARISON    = "comparison-operator",
		LOGICAL       = "logical-operator",
		MISCELLANEOUS = "miscellaneous-operator",
	},

	RUNTIME = {
		ARRAY      = "Array",
		BOOLEAN    = "Boolean",
		DICTIONARY = "Dictionary",
		NULL       = "Null",
		NUMBER     = "Number",
		STRING     = "String",

		FUNCTION = {
			NATIVE = "NativeFunction",
			USER   = "UserFunction",
		}
	}
}


tokens.eof         = tokens.TokenType.END_OF_FILE
tokens.eol         = tokens.TokenType.END_OF_LINE
tokens.identifier  = tokens.TokenType.IDENTIFIER
tokens.keyword     = tokens.TokenType.KEYWORD
tokens.punctuation = tokens.TokenType.PUNCTUATION

tokens.bool  = tokens.TokenType.LITERAL.BOOLEAN
tokens.float = tokens.TokenType.LITERAL.FLOATING_POINT
tokens.int   = tokens.TokenType.LITERAL.INTEGER
tokens.null  = tokens.TokenType.LITERAL.NULL
tokens.str   = tokens.TokenType.LITERAL.STRING

tokens.arithmeticOperator    = tokens.TokenType.OPERATOR.ARITHMETIC
tokens.assignmentOperator    = tokens.TokenType.OPERATOR.ASSIGNMENT
tokens.bitwiseOperator       = tokens.TokenType.OPERATOR.BITWISE
tokens.comparisonOperator    = tokens.TokenType.OPERATOR.COMPARISON
tokens.logicalOperator       = tokens.TokenType.OPERATOR.LOGICAL
tokens.miscellaneousOperator = tokens.TokenType.OPERATOR.MISCELLANEOUS

tokens.Array          = tokens.TokenType.RUNTIME.ARRAY
tokens.Boolean        = tokens.TokenType.RUNTIME.BOOLEAN
tokens.Dictionary     = tokens.TokenType.RUNTIME.DICTIONARY
tokens.Null           = tokens.TokenType.RUNTIME.NULL
tokens.Number         = tokens.TokenType.RUNTIME.NUMBER
tokens.String         = tokens.TokenType.RUNTIME.STRING
tokens.NativeFunction = tokens.TokenType.RUNTIME.FUNCTION.NATIVE
tokens.UserFunction   = tokens.TokenType.RUNTIME.FUNCTION.USER


function tokens.Token(type, value)
	return {
		type  = type,
		value = value
	}
end


return tokens
