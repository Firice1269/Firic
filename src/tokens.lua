local tokens = {}


tokens.TokenType = {
	END_OF_FILE = "end-of-file",
	END_OF_LINE = "end-of-line",
	IDENTIFIER  = "identifier",
	KEYWORD     = "keyword",
	PUNCTUATION = "punctuation",

	LITERAL = {
		FLOATING_POINT = "floating-point-literal",
		INTEGER        = "integer-literal",
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
		ARRAY      = "array",
		BOOLEAN    = "bool",
		CLASS      = "class",
		DICTIONARY = "dictionary",
		ENUM       = "enum",
		MODULE     = "module",
		NULL       = "null",
		NUMBER     = "num",
		STRING     = "str",

		FUNCTION = {
			NATIVE = "native-function",
			USER   = "user-function",
		},
	},
}


tokens.eof         = tokens.TokenType.END_OF_FILE
tokens.eol         = tokens.TokenType.END_OF_LINE
tokens.identifier  = tokens.TokenType.IDENTIFIER
tokens.keyword     = tokens.TokenType.KEYWORD
tokens.punctuation = tokens.TokenType.PUNCTUATION

tokens.float = tokens.TokenType.LITERAL.FLOATING_POINT
tokens.int   = tokens.TokenType.LITERAL.INTEGER
tokens.str   = tokens.TokenType.LITERAL.STRING

tokens.arithmeticOperator    = tokens.TokenType.OPERATOR.ARITHMETIC
tokens.assignmentOperator    = tokens.TokenType.OPERATOR.ASSIGNMENT
tokens.bitwiseOperator       = tokens.TokenType.OPERATOR.BITWISE
tokens.comparisonOperator    = tokens.TokenType.OPERATOR.COMPARISON
tokens.logicalOperator       = tokens.TokenType.OPERATOR.LOGICAL
tokens.miscellaneousOperator = tokens.TokenType.OPERATOR.MISCELLANEOUS

tokens.array          = tokens.TokenType.RUNTIME.ARRAY
tokens.boolean        = tokens.TokenType.RUNTIME.BOOLEAN
tokens.class          = tokens.TokenType.RUNTIME.CLASS
tokens.dictionary     = tokens.TokenType.RUNTIME.DICTIONARY
tokens.enum           = tokens.TokenType.RUNTIME.ENUM
tokens.module         = tokens.TokenType.RUNTIME.MODULE
tokens.null           = tokens.TokenType.RUNTIME.NULL
tokens.number         = tokens.TokenType.RUNTIME.NUMBER
tokens.string         = tokens.TokenType.RUNTIME.STRING
tokens.nativeFunction = tokens.TokenType.RUNTIME.FUNCTION.NATIVE
tokens.userFunction   = tokens.TokenType.RUNTIME.FUNCTION.USER


function tokens.Token(type, value, class)
	return {
		type  = type,
		value = value,
		class = class,
	}
end


return tokens
