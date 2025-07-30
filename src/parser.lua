local ast       = require("src.ast")
local tablex    = require("dependencies.tablex")
local tokenizer = require("src.tokenizer")
local tokens    = require("src.tokens")

local parser = {}

local newlines
local program


local function shift(tokenizedCode)
	local value = tablex.shift(tokenizedCode)

	if value.type == tokens.eol and tokenizedCode[1].type ~= tokens.eof then
		tablex.push(newlines, "")
	end

	return value
end


function parser.parseStatement(tokenizedCode)
	local start = #newlines

	local export = false

	if tokenizedCode[1].value == "export" then
		shift(tokenizedCode)

		if
			tokenizedCode[1].value ~= "class"
			and tokenizedCode[1].value ~= "enum"
			and tokenizedCode[1].value ~= "func"
			and tokenizedCode[1].value ~= "let" and tokenizedCode[1].value ~= "var"
		then
			print("error while parsing exported statement at line " .. start .. ": exported object must be a variable")
			os.exit()
		end

		export = true
	end

	local token = tokenizedCode[1]

	if token.value == "break" then
		shift(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing break statement at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift(tokenizedCode)

		return ast.Node(start, ast.Break)
	elseif token.value == "class" then
		return {
			parser.parseClassDefinition(tokenizedCode),
			export,
		}
	elseif token.value == "continue" then
		shift(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing continue statementat line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift(tokenizedCode)

		return ast.Node(start, ast.Continue)
	elseif token.value == "enum" then
		return {
			parser.parseEnum(tokenizedCode),
			export,
		}
	elseif token.value == "func" then
		shift(tokenizedCode)

		local func = parser.parseFunction(tokenizedCode, start)

		if func.value.name == nil then
			print("error while parsing function definition at line " .. start .. ": expected identifier while parsing name, got '(' instead")
			os.exit()
		end

		return {
			func,
			export,
		}
	elseif token.value == "let" or token.value == "var" then
		return {
			parser.parseVariableDeclaration(tokenizedCode),
			export,
		}
	elseif token.value == "if" then
		return parser.parseIfStatement(tokenizedCode)
	elseif token.value == "for" or token.value == "while" then
		return parser.parseLoop(tokenizedCode)
	elseif token.value == "return" then
		shift(tokenizedCode)

		local value = parser.parseExpression(tokenizedCode)

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing return statement at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift(tokenizedCode)

		return ast.Node(
			start,
			ast.Return,
			value
		)
	elseif token.value == "switch" then
		return parser.parseSwitchStatement(tokenizedCode)
	end

	return parser.parseVariableAssignment(tokenizedCode)
end


function parser.parseClassDefinition(tokenizedCode)
	local start = #newlines

	shift(tokenizedCode)

	local name = shift(tokenizedCode)

	if name.type ~= tokens.identifier then
		print(
			"error while parsing class definition at line " .. start
			.. ": expected identifier while parsing name, got '"
			.. name.type
			.. "' instead"
		)

		os.exit()
	end

	local inherited

	if tokenizedCode[1].value == ":" then
		shift(tokenizedCode)

		inherited = parser.parseExpression(tokenizedCode)

		if inherited.type ~= ast.Identifier then
			print(
				"error while parsing class definition at line " .. start
				.. ": expected identifier while parsing inherited class, got "
				.. string.lower(string.sub(inherited.type, 1, 1)) .. string.sub(inherited.type, 2, #inherited.type)
				.. " instead"
			)

			os.exit()
		end
	elseif tokenizedCode[1].value ~= "{" then
		print(
			"error while parsing class definition at line " .. start
			.. ": expected '{' or ':', got '"
			.. tokenizedCode[1].value
			.. "' instead"
		)

		os.exit()
	end

	local token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing class definition at line " .. start
			.. ": expected '{' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		local statement = parser.parseStatement(tokenizedCode)

		if statement ~= nil and #statement == 2 then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(body, statement)
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing class definition at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return ast.Node(
		start,
		ast.ClassDefinition,
		{
			name      = name.value,
			body      = body,
			inherited = inherited,
		}
	)
end


function parser.parseEnum(tokenizedCode)
	local start = #newlines

	shift(tokenizedCode)

	local name = parser.parseExpression(tokenizedCode)

	if name.type ~= ast.Identifier then
		print(
			"error while parsing enum at line " .. start
			.. ": expected identifier while parsing name, got '"
			.. string.sub(string.lower(name.type), 1, 1) .. string.sub(name.type, 2, #name.type)
			.. "' instead"
		)

		os.exit()
	end

	local token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing enum at line " .. start
			.. ": expected '{' while parsing cases, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local cases = {}

	if tokenizedCode[1].value ~= "}" then
		local case = shift(tokenizedCode)

		if case.type ~= tokens.identifier then
			print(
				"error while parsing enum at line " .. start
				.. ": expected identifier while parsing cases, got "
				.. string.sub(string.lower(case.type), 1, 1) .. string.sub(case.type, 2, #case.type)
				.. " instead"
			)

			os.exit()
		end

		if tokenizedCode[1].value == "(" then
			shift(tokenizedCode)

			case.value = {
				name       = case.value,
				parameters = {parser.parseTypeAnnotation(tokenizedCode)},
			}

			while tokenizedCode[1].value == "," do
				shift(tokenizedCode)

				tablex.push(case.value.parameters, parser.parseTypeAnnotation(tokenizedCode))
			end

			token = shift(tokenizedCode)
		end

		tablex.push(cases, case)

		while tokenizedCode[1].value == "," do
			shift(tokenizedCode)

			while tokenizedCode[1].type == tokens.eol do
				shift(tokenizedCode)
			end

			if tokenizedCode[1].value == "}" then
				break
			end

			case = shift(tokenizedCode)

			if case.type ~= tokens.identifier then
				print(
					"error while parsing enum at line " .. start
					.. ": expected identifier while parsing body, got "
					.. string.sub(string.lower(case.type), 1, 1) .. string.sub(case.type, 2, #case.type)
					.. " instead"
				)

				os.exit()
			end

			if tokenizedCode[1].value == "(" then
				shift(tokenizedCode)

				case.value = {
					name       = case.value,
					parameters = {parser.parseTypeAnnotation(tokenizedCode)},
				}

				while tokenizedCode[1].value == "," do
					shift(tokenizedCode)

					tablex.push(case.value.parameters, parser.parseTypeAnnotation(tokenizedCode))
				end

				token = shift(tokenizedCode)

				if token.value ~= ")" then
					print(
						"error while parsing enum at line " .. start
						.. ": expected ')', got '"
						.. token.value
						.. "' instead"
					)

					os.exit()
				end
			end

			tablex.push(cases, case)
		end
	end

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing enum at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return ast.Node(
		start,
		ast.Enum,
		{
			name = name.value,
			body = cases,
		}
	)
end


function parser.parseFunction(tokenizedCode, start)
	if tokenizedCode[1].type ~= tokens.identifier and tokenizedCode[1].value ~= "(" then
		print(
			"error while parsing function definition at line " .. start
			.. ": expected identifier or '(', got '"
			.. tokenizedCode[1].value
			.. "' instead"
		)

		os.exit()
	end

	local name

	if tokenizedCode[1].type == tokens.identifier then
		name = shift(tokenizedCode).value
	end

	local token = shift(tokenizedCode)

	if token.value ~= "(" then
		print(
			"error while parsing function at line " .. start
			.. ": expected '(' while parsing parameters, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local parameters = {}

	if tokenizedCode[1].value ~= ")" then
		local parameter = parser.parseExpression(tokenizedCode, true)

		if parameter.type ~= ast.Identifier then
			print(
				"error while parsing function call at line " .. start
				.. ": expected identifier while parsing parameters, got "
				.. string.sub(string.lower(parameter.type), 1, 1) .. string.sub(parameter.type, 2, #parameter.type)
				.. " instead"
			)

			os.exit()
		end

		local types = {}

		if tokenizedCode[1].value == ":" then
			shift(tokenizedCode)

			types = parser.parseTypeAnnotation(tokenizedCode)
		end

		tablex.push(
			parameters,
			{
				name  = parameter.value,
				types = types,
			}
		)

		while tokenizedCode[1].value == "," do
			shift(tokenizedCode)

			parameter = parser.parseExpression(tokenizedCode, true)

			if parameter.type ~= ast.Identifier then
				print(
					"error while parsing function call at line " .. start
					.. ": expected identifier while parsing parameters, got "
					.. string.lower(string.sub(parameter.type, 1, 1)) .. string.sub(parameter.type, 2, #parameter.type)
					.. " instead"
				)

				os.exit()
			end

			types = {}

			if tokenizedCode[1].value == ":" then
				shift(tokenizedCode)

				types = parser.parseTypeAnnotation(tokenizedCode)
			end

			tablex.push(
				parameters,
				{
					name  = parameter.value,
					types = types,
				}
			)
		end
	end

	token = shift(tokenizedCode)

	if token.value ~= ")" then
		print(
			"error while parsing function call at line " .. start
			.. ": expected ')' while parsing parameters, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local types = {}

	if tokenizedCode[1].value == ":" then
		shift(tokenizedCode)

		types = parser.parseTypeAnnotation(tokenizedCode)
	end

	token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing function definition at line " .. start
			.. ": expected '{' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		local statement = parser.parseStatement(tokenizedCode)

		if statement ~= nil and #statement == 2 then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(body, statement)
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing function definition at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return ast.Node(
		start,
		ast.Function,
		{
			name       = name,
			parameters = parameters,
			types      = types,
			body       = body,
		}
	)
end


function parser.parseIfStatement(tokenizedCode)
	local start = #newlines

	local keyword = shift(tokenizedCode).value

	if keyword ~= "else" and tokenizedCode[1].value == "{" then
		print(
			"error while parsing " .. keyword .. " statement at line " .. start
			.. ": expected expression while parsing condition, got '"
			.. tokenizedCode[1].value
			.. "' instead"
		)
		os.exit()
	end

	local condition

	if keyword == "elseif" or keyword == "if" then
		condition = parser.parseExpression(tokenizedCode)
	end

	local token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing " .. keyword .. " statement at line " .. start
			.. ": expected '{' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		local statement = parser.parseStatement(tokenizedCode)

		if statement ~= nil and #statement == 2 then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(body, statement)
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing " .. keyword .. " statement at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local statement = ast.Node(
		start,
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
	local start = #newlines

	local keyword = shift(tokenizedCode).value

	if tokenizedCode[1].value == "{" then
		print("error while parsing" .. keyword .. " loop at line " .. start .. ": expected expression, got block instead")
		os.exit()
	end

	local expression = parser.parseExpression(tokenizedCode)

	if keyword == "for" then
		if expression.type ~= ast.Identifier then
			print(
				"error while parsing for loop at line " .. start
				.. ": expected identifier while parsing iterator variable declaration, got "
				.. expression.type
				.. " instead"
			)

			os.exit()
		end

		local token = shift(tokenizedCode)

		if token.value ~= "in" then
			print(
				"error while parsing " .. keyword .. " loop at line " .. start
				.. ": expected 'in', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		expression = ast.Node(
			start,
			ast.BinaryExpression,
			{
				left     = expression,
				operator = token,
				right    = parser.parseExpression(tokenizedCode),
			}
		)
	end

	local token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing " .. keyword .. " loop at line " .. start
			.. ": expected '{' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		local statement = parser.parseStatement(tokenizedCode)

		if statement ~= nil and #statement == 2 then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(body, statement)
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing " .. keyword .. " loop at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return ast.Node(
		start,
		ast.Loop,
		{
			keyword    = keyword,
			body       = body,
			expression = expression,
		}
	)
end


function parser.parseSwitchStatement(tokenizedCode)
	local start = #newlines

	shift(tokenizedCode)

	local value = parser.parseExpression(tokenizedCode)

	local token = shift(tokenizedCode)

	if token.value ~= "{" then
		print(
			"error while parsing switch statement at line " .. start
			.. ": expected '{' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local cases = {}

	while tokenizedCode[1].value == "case" do
		shift(tokenizedCode)

		local case = {
			values = {
				parser.parseExpression(tokenizedCode),
			},
		}

		while tokenizedCode[1].value == "," do
			shift(tokenizedCode)

			tablex.push(case.values, parser.parseExpression(tokenizedCode))
		end

		token = shift(tokenizedCode)

		if token.value ~= ":" then
			print(
				"error while parsing switch statement at line " .. start
				.. ": expected ':' while parsing case body, got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		local body = {}

		while
			tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}"
			and tokenizedCode[1].value ~= "case" and tokenizedCode[1].value ~= "default"
		do
			local statement = parser.parseStatement(tokenizedCode)

			if statement ~= nil and #statement == 2 then
				export    = statement[2]
				statement = statement[1]

				if export then
					tablex.push(program.value.exports, statement)
				end
			end

			tablex.push(body, statement)
		end

		case.body = body
		tablex.push(cases, case)
	end

	if #cases == 0 then
		print("error while parsing switch statement at line " .. start .. ": expected at least 1 case while parsing body, got 0 instead")
		os.exit()
	end

	local default = {}

	if tokenizedCode[1].value == "default" then
		shift(tokenizedCode)

		token = shift(tokenizedCode)

		if token.value ~= ":" then
			print(
				"error while parsing switch statement at line " .. start
				.. ": expected ':' while parsing case body, got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
			local statement = parser.parseStatement(tokenizedCode)

			if statement ~= nil and #statement == 2 then
				export    = statement[2]
				statement = statement[1]

				if export then
					tablex.push(program.value.exports, statement)
				end
			end

			tablex.push(default, statement)
		end
	end

	if #default == 0 then
		default = nil
	end

	token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing switch statement at line " .. start
			.. ": expected '}' while parsing body, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return ast.Node(
		start,
		ast.SwitchStatement,
		{
			value   = value,
			cases   = cases,
			default = default,
		}
	)
end


function parser.parseVariableAssignment(tokenizedCode)
	local left = parser.parseExpression(tokenizedCode)

	if tokenizedCode[1].type == tokens.assignmentOperator then
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseExpression(tokenizedCode)

		local token = shift(tokenizedCode)

		if token.type ~= tokens.eol and token.value ~= ";" then
			print(
				"error while parsing variable assignment at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		left = ast.Node(
			start,
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


function parser.parseVariableDeclaration(tokenizedCode)
	local start = #newlines

	local constant = shift(tokenizedCode).value == "let"

	local name = shift(tokenizedCode)

	if name.type ~= tokens.identifier then
		print(
			"error while parsing variable declaration at line " .. start
			.. ": expected identifier while parsing name, got "
			.. name.type
			.. " instead"
		)

		os.exit()
	end

	local types

	if tokenizedCode[1].value == ":" then
		shift(tokenizedCode)

		types = parser.parseTypeAnnotation(tokenizedCode)
	end

	local token = shift(tokenizedCode)

	if token.type == tokens.eol or token.value == ";" then
		if constant then
			print(
				"error while parsing variable declaration at line " .. start
				.. ": expected expression while parsing value, got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		if tokenizedCode[1].value == ";" then
			token = shift(tokenizedCode)

			while tokenizedCode[1].type == tokens.eol do
				shift(tokenizedCode)
			end
		end

		return ast.Node(
			start,
			ast.VariableDeclaration,
			{
				name     = name.value,
				constant = constant,
				types    = types,
			}
		)
	elseif token.value ~= "=" then
		print(
			"error while parsing variable declaration at line " .. start
			.. ": expected '\\n', ';', or '=', got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	local declaration = ast.Node(
		start,
		ast.VariableDeclaration,
		{
			name     = name.value,
			constant = constant,
			types    = types,
			value    = parser.parseExpression(tokenizedCode),
		}
	)

	if token.value ~= ";" then
		token = shift(tokenizedCode)

		if token.type ~= tokens.eol and token.value ~= ";" then
			print(
				"error while parsing variable declaration at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end
	end

	return declaration
end


function parser.parseTypeAnnotation(tokenizedCode)
	local start = #newlines

	local identifier = shift(tokenizedCode)

	if identifier.type ~= tokens.identifier and identifier.type ~= tokens.keyword then
		print(
			"error while parsing type annotation at line " .. start
			.. ": expected identifier, got "
			.. identifier.type
			.. " instead"
		)

		os.exit()
	end

	local types = {identifier.value}

	if identifier.value == "Array" then
		types = {
			{},
		}

		if tokenizedCode[1].value == "[" then
			shift(tokenizedCode)

			for _, v in ipairs(parser.parseTypeAnnotation(tokenizedCode)) do
				tablex.push(types[1], v)
			end

			local token = shift(tokenizedCode)

			if token.value ~= "]" then
				print(
					"error while parsing type annotation at line " .. start
					.. ": expected ']', got '"
					.. token.value
					.. "' instead"
				)

				os.exit()
			end
		end
	elseif identifier.value == "Dictionary" then
		types = {
			{
				keys = {},
				values = {},
			},
		}

		if tokenizedCode[1].value == "{" then
			shift(tokenizedCode)

			for _, v in ipairs(parser.parseTypeAnnotation(tokenizedCode)) do
				tablex.push(types[1].keys, v)
			end

			local token = shift(tokenizedCode)

			if token.value ~= ":" then
				print(
					"error while parsing type annotation at line " .. start
					.. ": expected ':', got '"
					.. token.value
					.. "' instead"
				)

				os.exit()
			end

			for _, v in ipairs(parser.parseTypeAnnotation(tokenizedCode)) do
				tablex.push(types[1].values, v)
			end

			token = shift(tokenizedCode)

			if token.value ~= "}" then
				print(
					"error while parsing type annotation at line " .. start
					.. ": expected '}', got '"
					.. token.value
					.. "' instead"
				)

				os.exit()
			end
		end
	elseif identifier.value == "any" then
		return {}
	end

	while tokenizedCode[1].value == "|" do
		shift(tokenizedCode)

		for _, v in ipairs(parser.parseTypeAnnotation(tokenizedCode)) do
			tablex.push(types, v)
		end
	end

	return types
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
			tablex.push(newlines, "")
		end
	end

	return parser.parseTernaryExpression(tokenizedCode)
end


function parser.parseTernaryExpression(tokenizedCode)
	local condition = parser.parseLogicalExpression(tokenizedCode)

	while tokenizedCode[1].value == "?" do
		local start = #newlines

		shift(tokenizedCode)

		local left = parser.parseLogicalExpression(tokenizedCode)

		local token = shift(tokenizedCode)

		if token.value ~= ":" then
			print(
				"error while parsing ternary expression at line " .. start
				.. ": expected ':', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		local right = parser.parseLogicalExpression(tokenizedCode)

		condition = ast.Node(
			start,
			ast.TernaryExpression,
			{
				condition = condition,
				left      = left,
				right     = right,
			}
		)
	end

	return condition
end


function parser.parseLogicalExpression(tokenizedCode)
	local left = parser.parseBitwiseExpression(tokenizedCode)

	while tokenizedCode[1].value == "&&" or tokenizedCode[1].value == "||" do
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseBitwiseExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseInequalExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseEqualExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseShiftExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseAdditiveExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseMultiplicativeExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseExponentialExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		local operator = shift(tokenizedCode).value
		local right    = parser.parseMemberExpression(tokenizedCode)

		left = ast.Node(
			start,
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
		local start = #newlines

		shift(tokenizedCode)

		local right = parser.parsePrimaryExpression(tokenizedCode)

		left = ast.Node(
			start,
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
	local start = #newlines

	local token = shift(tokenizedCode)

	if token.value == "func" then
		local func = parser.parseFunction(tokenizedCode, start)

		if func.name ~= nil then
			print(
				"error while parsing anonymous function at line " .. start
				.. ": expected '(' while parsing parameters, got '"
				.. func.name
				.. "' instead"
			)

			os.exit()
		end

		return func
	elseif token.value == "(" then
		local value = parser.parseExpression(tokenizedCode, true)

		token = shift(tokenizedCode)

		if token.value ~= ")" then
			print(
				"error while parsing parenthesized expression at line " .. start
				.. ": expected ')', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		return value
	elseif token.value == "[" then
		return ast.Node(
			start,
			ast.Array,
			parser.parseArray(tokenizedCode)
		)
	elseif token.value == "{" then
		return ast.Node(
			start,
			ast.Dictionary,
			parser.parseDictionary(tokenizedCode)
		)
	elseif token.value == "-" or token.value == "~" or token.value == "!" then
		local value = parser.parsePrimaryExpression(tokenizedCode)

		return ast.Node(
			start,
			ast.UnaryExpression,
			{
				operator = token.value,
				value    = value,
			}
		)
	elseif token.type == tokens.str then
		return ast.Node(
			start,
			ast.String,
			token.value
		)
	elseif token.type == tokens.identifier then
		local expression = ast.Node(
			start,
			ast.Identifier,
			token.value
		)

		if tokenizedCode[1].value == "(" then
			while tokenizedCode[1].value == "(" do
				expression = ast.Node(
					start,
					ast.FunctionCall,
					{
						call      = expression,
						arguments = parser.parseArguments(tokenizedCode),
					}
				)
			end
		end

		while tokenizedCode[1].value == "[" do
			shift(tokenizedCode)

			local right = parser.parseExpression(tokenizedCode, true)

			token = shift(tokenizedCode)

			if token.value ~= "]" then
				print(
					"error while parsing index expression at line " .. start
					.. ": expected ']', got '"
					.. token.value
					.. "' instead"
				)

				os.exit()
			end

			expression = ast.Node(
				start,
				ast.IndexExpression,
				{
					left  = expression,
					right = right,
				}
			)
		end

		return expression
	elseif token.type == tokens.float or token.type == tokens.int then
		return ast.Node(
			start,
			ast.Number,
			token.value
		)
	elseif token.value == ";" then
		return parser.parseStatement(tokenizedCode)
	elseif token.type ~= tokens.eol then
		print(
			"error while parsing expression at line " .. start
			.. ": expected 'func', '(', '[', '{', unary operator, string, identifier, or number; got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end
end


function parser.parseArguments(tokenizedCode)
	local start = #newlines

	local token = shift(tokenizedCode)

	if token.value ~= "(" then
		print(
			"error while parsing function call at line " .. start
			.. ": expected '(' while parsing arguments, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local arguments = {}

	if tokenizedCode[1].value ~= ")" then
		tablex.push(arguments, parser.parseExpression(tokenizedCode, true))

		while tokenizedCode[1].value == "," do
			shift(tokenizedCode)

			tablex.push(arguments, parser.parseExpression(tokenizedCode, true))
		end
	end

	token = shift(tokenizedCode)

	if token.value ~= ")" then
		print(
			"error while parsing function call at line " .. start
			.. ": expected ')' while parsing arguments, got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return arguments
end


function parser.parseArray(tokenizedCode)
	local start = #newlines

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local values = {}

	if tokenizedCode[1].value ~= "]" then
		tablex.push(values, parser.parseExpression(tokenizedCode, true))

		while tokenizedCode[1].value == "," do
			shift(tokenizedCode)

			if tokenizedCode[1].value == "]" then
				break
			end

			tablex.push(values, parser.parseExpression(tokenizedCode, true))
		end
	end

	local token = shift(tokenizedCode)

	if token.value ~= "]" then
		print(
			"error while parsing array at line " .. start
			.. ": expected ']', got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return values
end


function parser.parseDictionary(tokenizedCode)
	local start = #newlines

	while tokenizedCode[1].type == tokens.eol do
		shift(tokenizedCode)
	end

	local values = {}

	if tokenizedCode[1].value ~= "}" then
		local key = parser.parseExpression(tokenizedCode, true)

		local token = shift(tokenizedCode)

		if token.value ~= ":" then
			print(
				"error while parsing dictionary at line " .. start
				.. ": expected ':', got '"
				.. token.value
				.. "' instead"
			)

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
			shift(tokenizedCode)

			if tokenizedCode[1].value == "}" then
				break
			end

			key = parser.parseExpression(tokenizedCode, true)

			token = shift(tokenizedCode)

			if token.value ~= ":" then
				print(
					"error while parsing dictionary at line " .. start
					.. ": expected ':', got '"
					.. token.value
					.. "' instead"
				)

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

	local token = shift(tokenizedCode)

	if token.value ~= "}" then
		print(
			"error while parsing dictionary at line " .. start
			.. ": expected '}', got '"
			.. token.value
			.. "' instead"
		)

		os.exit()
	end

	return values
end


function parser.parse(sourceCode)
	local tokenizedCode = tokenizer.tokenize(sourceCode)

	newlines = {""}

	program = ast.Node(
		0,
		ast.Program,
		{
			body    = {},
			exports = {},
		}
	)

	while tokenizedCode[1].type ~= tokens.eof do
		local statement = parser.parseStatement(tokenizedCode)

		if statement ~= nil and #statement == 2 then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(program.value.body, statement)
	end

	return program
end


return parser
