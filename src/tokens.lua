local tokens = {}


tokens.TokenType = {
	END_OF_FILE = "end-of-file",
	END_OF_LINE = "end-of-line",
	IDENTIFIER  = "identifier",
	KEYWORD     = "keyword",
	PUNCTUATION = "punctuation",

	LITERAL = {
		NUMBER = "number-literal",
		STRING = "string-literal",
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


tokens.literals = tokens.TokenType.LITERAL

tokens.num = tokens.literals.NUMBER
tokens.str = tokens.literals.STRING


tokens.operators = tokens.TokenType.OPERATOR

tokens.arithmeticOperator    = tokens.operators.ARITHMETIC
tokens.assignmentOperator    = tokens.operators.ASSIGNMENT
tokens.bitwiseOperator       = tokens.operators.BITWISE
tokens.comparisonOperator    = tokens.operators.COMPARISON
tokens.logicalOperator       = tokens.operators.LOGICAL
tokens.miscellaneousOperator = tokens.operators.MISCELLANEOUS


tokens.runtimeValues = tokens.TokenType.RUNTIME

tokens.array      = tokens.runtimeValues.ARRAY
tokens.boolean    = tokens.runtimeValues.BOOLEAN
tokens.class      = tokens.runtimeValues.CLASS
tokens.dictionary = tokens.runtimeValues.DICTIONARY
tokens.enum       = tokens.runtimeValues.ENUM
tokens.module     = tokens.runtimeValues.MODULE
tokens.null       = tokens.runtimeValues.NULL
tokens.number     = tokens.runtimeValues.NUMBER
tokens.string     = tokens.runtimeValues.STRING


tokens.functions = tokens.runtimeValues.FUNCTION

tokens.nativeFunction = tokens.functions.NATIVE
tokens.userFunction   = tokens.functions.USER


function tokens.Token(type, value, class)
	return {
		type  = type,
		value = value,
		class = class,
	}
end


return tokens
