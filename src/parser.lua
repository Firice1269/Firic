local ast       = require("src.ast")
local tablex    = require("dependencies.tablex")
local tokenizer = require("src.tokenizer")
local tokens    = require("src.tokens")

local parser = {}


function parser.parseStatement(tokenizedCode)
	local token = tokenizedCode[1]

	if token.value == "break" then
		tablex.shift(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print("ERROR: Unexpected token inside break statement (expected newline or semicolon): " .. tablex.repr(tokenizedCode[1]))
			os.exit()
		end

		tablex.shift(tokenizedCode)

		return ast.Node(ast.Break)
	elseif token.value == "continue" then
		tablex.shift(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print("ERROR: Unexpected token inside continue statement (expected newline or semicolon): " .. tablex.repr(tokenizedCode[1]))
			os.exit()
		end

		tablex.shift(tokenizedCode)

		return ast.Node(ast.Continue)
	elseif token.value == "func" then
		tablex.shift(tokenizedCode)

		local func = parser.parseFunction(tokenizedCode)

		if func.value.name == nil then
			print("ERROR: Unexpected name of function (expected non-nil value): " .. func.value.name)
			os.exit()
		end

		return func
	elseif token.value == "let" or token.value == "var" then
		return parser.parseVariableDeclaration(tokenizedCode, false)
	elseif token.value == "if" then
		return parser.parseIfStatement(tokenizedCode)
	elseif token.value == "for" or token.value == "while" then
		return parser.parseLoop(tokenizedCode)
	elseif token.value == "return" then
		tablex.shift(tokenizedCode)

		local value = parser.parseExpression(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print("ERROR: Unexpected token inside return statement (expected newline or semicolon): " .. tablex.repr(tokenizedCode[1]))
			os.exit()
		end

		tablex.shift(tokenizedCode)

		return ast.Node(
			ast.Return,
			value
		)
	end

	return parser.parseExpression(tokenizedCode)
end


function parser.parseFunction(tokenizedCode)
	if tokenizedCode[1].type ~= tokens.identifier and tokenizedCode[1].value ~= "(" then
		print("ERROR: Unexpected token inside function (expected identifier or open parenthesis): " .. tablex.repr(tokenizedCode[1]))
		os.exit()
	end

	local name

	if tokenizedCode[1].type == tokens.identifier then
		name = tablex.shift(tokenizedCode).value
	end

	local arguments  = parser.parseArguments(tokenizedCode)

	local parameters = {}

	for _, v in ipairs(arguments) do
		if v.type ~= ast.Identifier then
			print("ERROR: Unexpected parameter inside function (expected identifier): " .. tablex.repr(v))
			os.exit()
		end

		tablex.push(parameters, v.value)
	end

	while tokenizedCode[1].type == tokens.eol do
		tablex.shift(tokenizedCode)
	end

	local token = tablex.shift(tokenizedCode)

	if token.value ~= "{" then
		print("ERROR: Unexpected token inside function (expected open brace): " .. tablex.repr(token))
		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		tablex.push(body, parser.parseStatement(tokenizedCode))
	end

	token = tablex.shift(tokenizedCode)

	if token.value ~= "}" then
		print("ERROR: Unexpected token inside function (expected closed brace): " .. tablex.repr(token))
		os.exit()
	end

	return ast.Node(
		ast.Function,
		{
			name       = name,
			parameters = parameters,
			body       = body,
		}
	)
end


function parser.parseIfStatement(tokenizedCode)
	local keyword = tablex.shift(tokenizedCode).value

	local condition

	if keyword == "elseif" or keyword == "if" then
		condition = parser.parseExpression(tokenizedCode)
	end

	while tokenizedCode[1].type == tokens.eol do
		tablex.shift(tokenizedCode)
	end

	local token = tablex.shift(tokenizedCode)

	if token.value ~= "{" then
		print("ERROR: Unexpected token inside " .. keyword .. " statement initiation (expected open brace): " .. tablex.repr(token))
		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		tablex.push(body, parser.parseStatement(tokenizedCode))
	end

	token = tablex.shift(tokenizedCode)

	if token.value ~= "}" then
		print("ERROR: Unexpected token inside " .. keyword .. " statement (expected closed brace): " .. tablex.repr(token))
		os.exit()
	end

	while tokenizedCode[1].type == tokens.eol do
		tablex.shift(tokenizedCode)
	end

	local statement = ast.Node(
		ast.IfStatement,
		{
			keyword   = keyword,
			body      = body,
			condition = condition,
		}
	)

	if tokenizedCode[1].value == "else" or tokenizedCode[1].value == "elseif" then
		tablex.push(statement.value, parser.parseIfStatement(tokenizedCode))
	end

	return statement
end


function parser.parseLoop(tokenizedCode)
	local keyword    = tablex.shift(tokenizedCode).value
	local expression = parser.parseExpression(tokenizedCode)

	if keyword == "for" then
		if expression.type ~= ast.Identifier then
			print("ERROR: Unexpected token inside for loop initiation (expected identifier): " .. expression.type)
			os.exit()
		end

		local token = tablex.shift(tokenizedCode)

		if token.value ~= "in" then
			print("ERROR: Unexpected token inside for loop initiation (expected 'in' keyword): " .. tablex.repr(token))
			os.exit()
		end

		expression = ast.Node(
			ast.BinaryExpression,
			{
				left     = expression,
				operator = token,
				right    = parser.parseExpression(tokenizedCode),
			}
		)
	end

	local token = tablex.shift(tokenizedCode)

	if token.value ~= "{" then
		print("ERROR: Unexpected token inside " .. keyword .. " loop initiation (expected open brace): " .. tablex.repr(token))
		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		tablex.push(body, parser.parseStatement(tokenizedCode))
	end

	token = tablex.shift(tokenizedCode)

	if token.value ~= "}" then
		print("ERROR: Unexpected token inside " .. keyword .. " loop (expected closed brace): " .. tablex.repr(token))
		os.exit()
	end

	return ast.Node(
		ast.Loop,
		{
			keyword    = keyword,
			body       = body,
			expression = expression,
		}
	)
end


function parser.parseVariableDeclaration(tokenizedCode, brackets)
	local constant = tablex.shift(tokenizedCode).value == "let"

	local identifier = tablex.shift(tokenizedCode)

	if identifier.type ~= tokens.identifier then
		print("ERROR: Unexpected token inside variable declaration (expected identifier): " .. tablex.repr(identifier))
		os.exit()
	end

	local token = tablex.shift(tokenizedCode)

	if (token.type == tokens.eol and not brackets) or tokenizedCode[1].value == ";" then
		if constant then
			print("ERROR: Unexpected token inside variable declaration (expected equals): " .. tablex.repr(token))
			os.exit()
		end

		if tokenizedCode[1].value == ";" then
			token = tablex.shift(tokenizedCode)

			while tokenizedCode[1].type == tokens.eol do
				tablex.shift(tokenizedCode)
			end
		end

		return ast.Node(
			ast.VariableDeclaration,
			{
				name     = identifier.value,
				constant = constant,
				value    = ast.Node(ast.Identifier, "null")
			}
		)
	elseif token.value ~= "=" then
		print("ERROR: Unexpected token inside variable declaration (expected equals, newline, or semicolon): " .. tablex.repr(token))
		os.exit()
	end

	local declaration = ast.Node(
		ast.VariableDeclaration,
		{
			name     = identifier.value,
			constant = constant,
			value    = parser.parseExpression(tokenizedCode, brackets),
		}
	)

	if token.value ~= ";" then
		token = tablex.shift(tokenizedCode)

		if not (token.type == tokens.eol and not brackets) and token.value ~= ";" then
			print("ERROR: Unexpected token inside variable declaration (expected newline or semicolon): " .. tablex.repr(token))
			os.exit()
		end
	end

	return declaration
end


function parser.parseExpression(tokenizedCode, brackets)
	brackets = brackets or false

	if brackets then
		local bracketCount = 1
		local indices      = {}

		for i, v in ipairs(tokenizedCode) do
			if v.type == tokens.eol then
				tablex.push(indices, i)
			elseif v.value == "(" or v.value == "[" or v.value == "{" then
				bracketCount = bracketCount + 1
			elseif v.value == ")" or v.value == "]" or v.value == "}" then
				bracketCount = bracketCount - 1
			end

			if bracketCount == 0 then
				break
			end
		end

		for i, v in ipairs(indices) do
			table.remove(tokenizedCode, v - i + 1)
		end
	end

	return parser.parseVariableAssignment(tokenizedCode, brackets)
end


function parser.parseVariableAssignment(tokenizedCode, brackets)
	local left = parser.parseLogicalExpression(tokenizedCode)

	if tokenizedCode[1].type == tokens.assignmentOperator then
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseExpression(tokenizedCode, brackets)

		local token = tablex.shift(tokenizedCode)

		if not (token.type == tokens.eol and not brackets) and token.value ~= ";" then
			print("ERROR: Unexpected token inside variable assignment (expected newline or semicolon): " .. tablex.repr(token))
			os.exit()
		end

		left = ast.Node(
			ast.VariableAssignment,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseLogicalExpression(tokenizedCode)
	local left = parser.parseBitwiseExpression(tokenizedCode)

	while tokenizedCode[1].value == "&&" or tokenizedCode[1].value == "||" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseBitwiseExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseBitwiseExpression(tokenizedCode)
	local left = parser.parseInequalExpression(tokenizedCode)

	while tokenizedCode[1].value == "&" or tokenizedCode[1].value == "|" or tokenizedCode[1].value == "^" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseInequalExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseInequalExpression(tokenizedCode)
	local left = parser.parseEqualExpression(tokenizedCode)

	while
		tokenizedCode[1].value == "<"
		or tokenizedCode[1].value == "<="
		or tokenizedCode[1].value == ">"
		or tokenizedCode[1].value == ">="
	do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseEqualExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseEqualExpression(tokenizedCode)
	local left = parser.parseShiftExpression(tokenizedCode)

	while tokenizedCode[1].value == "==" or tokenizedCode[1].value == "!=" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseShiftExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseShiftExpression(tokenizedCode)
	local left = parser.parseAdditiveExpression(tokenizedCode)

	while tokenizedCode[1].value == "<<" or tokenizedCode[1].value == ">>" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseAdditiveExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseAdditiveExpression(tokenizedCode)
	local left = parser.parseMultiplicativeExpression(tokenizedCode)

	while tokenizedCode[1].value == "+" or tokenizedCode[1].value == "-" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseMultiplicativeExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseMultiplicativeExpression(tokenizedCode)
	local left = parser.parseExponentialExpression(tokenizedCode)

	while tokenizedCode[1].value == "*" or tokenizedCode[1].value == "/" or tokenizedCode[1].value == "%" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseExponentialExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseExponentialExpression(tokenizedCode)
	local left = parser.parseMemberExpression(tokenizedCode)

	while tokenizedCode[1].value == "**" or tokenizedCode[1].value == "//" do
		local operator = tablex.shift(tokenizedCode).value
		local right    = parser.parseMemberExpression(tokenizedCode)

		left = ast.Node(
			ast.BinaryExpression,
			{
				left     = left,
				operator = operator,
				right    = right,
			}
		)
	end

	return left
end


function parser.parseMemberExpression(tokenizedCode)
	local left = parser.parsePrimaryExpression(tokenizedCode)

	while tokenizedCode[1].value == "." do
		tablex.shift(tokenizedCode)

		local right = parser.parsePrimaryExpression(tokenizedCode)

		left = ast.Node(
			ast.MemberExpression,
			{
				left  = left,
				right = right,
			}
		)
	end

	return left
end


function parser.parsePrimaryExpression(tokenizedCode)
	local token = tablex.shift(tokenizedCode)

	if token.value == "func" then
		local func = parser.parseFunction(tokenizedCode)

		if func.name ~= nil then
			print("ERROR: Unexpected name of function (expected nil value): " .. func.name)
			os.exit()
		end

		return func
	elseif token.value == "(" then
		local value = parser.parseExpression(tokenizedCode)

		token = tablex.shift(tokenizedCode)

		if token.value ~= ")" then
			print("ERROR: Unexpected token inside parentheses (expected closing parenthesis): " .. tablex.repr(token))
			os.exit()
		end

		return value
	elseif token.value == "[" then
		return ast.Node(
			ast.Array,
			parser.parseArray(tokenizedCode)
		)
	elseif token.value == "{" then
		return ast.Node(
			ast.Dictionary,
			parser.parseDictionary(tokenizedCode)
		)
	elseif token.value == "-" or token.value == "~" or token.value == "!" then
		local value = parser.parseExpression(tokenizedCode)

		return ast.Node(
			ast.UnaryExpression,
			{
				operator = token.value,
				value    = value,
			}
		)
	elseif token.type == tokens.str then
		return ast.Node(ast.String, token.value)
	elseif token.type == tokens.identifier then
		local expression = ast.Node(ast.Identifier, token.value)

		if tokenizedCode[1].value == "(" then
			while tokenizedCode[1].value == "(" do
				expression = ast.Node(
					ast.FunctionCall,
					{
						call      = expression,
						arguments = parser.parseArguments(tokenizedCode),
					}
				)
			end

			if tokenizedCode[1].value == ";" then
				tablex.shift(tokenizedCode)
				return expression
			end
		end

		while tokenizedCode[1].value == "[" do
			tablex.shift(tokenizedCode)

			local right = parser.parseExpression(tokenizedCode, true)

			token = tablex.shift(tokenizedCode)

			if token.value ~= "]" then
				print("ERROR: Unexpected token inside index expression (expected closed bracket): " .. tablex.repr(token))
				os.exit()
			end

			expression = ast.Node(
				ast.IndexExpression,
				{
					left  = expression,
					right = right,
				}
			)
		end

		return expression
	elseif token.type == tokens.float or token.type == tokens.int then
		return ast.Node(ast.Number, token.value)
	elseif token.type ~= tokens.eol then
		print("ERROR: Unexpected token: " .. tablex.repr(token))
		os.exit()
	end
end


function parser.parseArguments(tokenizedCode)
	local token = tablex.shift(tokenizedCode)

	if token.value ~= "(" then
		print("ERROR: Unexpected token inside function call (expected open parenthesis): " .. tablex.repr(token))
		os.exit()
	end

	local arguments = {}

	if tokenizedCode[1].value ~= ")" then
		tablex.push(arguments, parser.parseExpression(tokenizedCode, true))

		while tokenizedCode[1].value == "," do
			tablex.shift(tokenizedCode)

			tablex.push(arguments, parser.parseExpression(tokenizedCode, true))
		end
	end

	token = tablex.shift(tokenizedCode)

	if token.value ~= ")" then
		print("ERROR: Unexpected token inside function call (expected closed parenthesis): " .. tablex.repr(token))
		os.exit()
	end

	return arguments
end


function parser.parseArray(tokenizedCode)
	local values = {}

	if tokenizedCode[1].value ~= "]" then
		tablex.push(values, parser.parseExpression(tokenizedCode, true))

		while tokenizedCode[1].value == "," do
			tablex.shift(tokenizedCode)

			if tokenizedCode[1].value == "]" then
				break
			end

			tablex.push(values, parser.parseExpression(tokenizedCode, true))
		end
	end

	local token = tablex.shift(tokenizedCode)

	if token.value ~= "]" then
		print("ERROR: Unexpected token inside array (expected closed bracket): " .. tablex.repr(token))
		os.exit()
	end

	return values
end


function parser.parseDictionary(tokenizedCode)
	local values = {}

	if tokenizedCode[1].value ~= "}" then
		local key = parser.parseExpression(tokenizedCode, true)

		local token = tablex.shift(tokenizedCode)

		if token.value ~= ":" then
			print("ERROR: Unexpected token inside dictionary (expected colon): " .. tablex.repr(token))
			os.exit()
		end

		tablex.push(
			values,
			{
				key   = key,
				value = parser.parseExpression(tokenizedCode, true),
			}
		)

		while tokenizedCode[1].value == "," do
			tablex.shift(tokenizedCode)

			if tokenizedCode[1].value == "}" then
				break
			end

			key = parser.parseExpression(tokenizedCode, true)

			token = tablex.shift(tokenizedCode)

			if token.value ~= ":" then
				print("ERROR: Unexpected token inside dictionary (expected colon): " .. tablex.repr(token))
				os.exit()
			end

			tablex.push(
				values,
				{
					key   = key,
					value = parser.parseExpression(tokenizedCode, true),
				}
			)
		end
	end

	local token = tablex.shift(tokenizedCode)

	if token.value ~= "}" then
		print("ERROR: Unexpected token inside dictionary (expected closed brace): " .. tablex.repr(token))
		os.exit()
	end

	return values
end


function parser.parse(sourceCode)
	local tokenizedCode = tokenizer.tokenize(sourceCode)

	local program = ast.Node(ast.Program)

	while tokenizedCode[1].type ~= tokens.eof do
		local statement = parser.parseStatement(tokenizedCode)
		tablex.push(program.value, statement)
	end

	return program
end


return parser
