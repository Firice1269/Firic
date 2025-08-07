local ast       = require("src.ast")
local tablex    = require("dependencies.tablex")
local tokenizer = require("src.tokenizer")
local tokens    = require("src.tokens")

local parser = {}

local newlines
local program
local tokenizedCode


local function shift()
	local value = tablex.shift(tokenizedCode)

	if value.type == tokens.eol and tokenizedCode[1].type ~= tokens.eof then
		tablex.push(newlines, "")
	end

	return value
end


function parser.parseStatement()
	local start = #newlines

	local export = false

	if tokenizedCode[1].value == "export" then
		shift()

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

	if token.value == "{" then
		return parser.parseBlockStatement()
	elseif token.value == "break" then
		shift()

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing break statement at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift()

		return ast.Node(start, ast.Break)
	elseif token.value == "class" then
		return {
			parser.parseClassDefinition(),
			export,
		}
	elseif token.value == "continue" then
		shift()

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing continue statementat line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift()

		return ast.Node(start, ast.Continue)
	elseif token.value == "enum" then
		return {
			parser.parseEnum(),
			export,
		}
	elseif token.value == "func" then
		shift()

		local func = parser.parseFunction(start)

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
			parser.parseVariableDeclaration(),
			export,
		}
	elseif token.value == "if" then
		return parser.parseIfStatement()
	elseif token.value == "for" or token.value == "while" then
		return parser.parseLoop()
	elseif token.value == "return" then
		shift()

		local value = parser.parseExpression()

		if tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].value ~= ";" then
			print(
				"error while parsing return statement at line " .. start
				.. ": expected '\\n' or ';', got '"
				.. tokenizedCode[1].value
				.. "' instead"
			)

			os.exit()
		end

		shift()

		return ast.Node(
			start,
			ast.Return,
			value
		)
	elseif token.value == "switch" then
		return parser.parseSwitchStatement()
	end

	return parser.parseVariableAssignment()
end


function parser.parseBlockStatement()
	local start = #newlines

	shift()

	local body = {}

	while tokenizedCode[1].type ~= tokens.eof and tokenizedCode[1].value ~= "}" do
		local statement = parser.parseStatement()

		if statement ~= nil and #statement == 2 and type(statement[2]) == "boolean" then
			export    = statement[2]
			statement = statement[1]

			if export then
				tablex.push(program.value.exports, statement)
			end
		end

		tablex.push(body, statement)
	end

	local token = shift()

	if token.value ~= "}" then
		print("error while parsing block at line " .. start .. ": expected '}', got '" .. token.value .. "' instead")
		os.exit()
	end

	return body
end


function parser.parseClassDefinition()
	local start = #newlines

	shift()

	local name = shift()

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
		shift()

		inherited = parser.parseExpression()

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

	return ast.Node(
		start,
		ast.ClassDefinition,
		{
			name      = name.value,
			body      = parser.parseBlockStatement(),
			inherited = inherited,
		}
	)
end


function parser.parseEnum()
	local start = #newlines

	shift()

	local name = parser.parseExpression()

	if name.type ~= ast.Identifier then
		print(
			"error while parsing enum at line " .. start
			.. ": expected identifier while parsing name, got '"
			.. string.sub(string.lower(name.type), 1, 1) .. string.sub(name.type, 2, #name.type)
			.. "' instead"
		)

		os.exit()
	end

	local token = shift()

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
		shift()
	end

	local cases = {}

	if tokenizedCode[1].value ~= "}" then
		local case = shift()

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
			shift()

			case.value = {
				name       = case.value,
				parameters = {parser.parseTypeAnnotation()},
			}

			while tokenizedCode[1].value == "," do
				shift()

				tablex.push(case.value.parameters, parser.parseTypeAnnotation())
			end

			token = shift()
		end

		tablex.push(cases, case)

		while tokenizedCode[1].value == "," do
			shift()

			while tokenizedCode[1].type == tokens.eol do
				shift()
			end

			if tokenizedCode[1].value == "}" then
				break
			end

			case = shift()

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
				shift()

				case.value = {
					name       = case.value,
					parameters = {parser.parseTypeAnnotation()},
				}

				while tokenizedCode[1].value == "," do
					shift()

					tablex.push(case.value.parameters, parser.parseTypeAnnotation())
				end

				token = shift()

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
		shift()
	end

	token = shift()

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


function parser.parseFunction(start)
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
		name = shift().value
	end

	local token = shift()

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
		shift()
	end

	local parameters = {}

	if tokenizedCode[1].value ~= ")" then
		local parameter = parser.parseExpression(true)

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
			shift()

			types = parser.parseTypeAnnotation()
		end

		tablex.push(
			parameters,
			{
				name  = parameter.value,
				types = types,
			}
		)

		while tokenizedCode[1].value == "," do
			shift()

			parameter = parser.parseExpression(true)

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
				shift()

				types = parser.parseTypeAnnotation()
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

	token = shift()

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
		shift()

		types = parser.parseTypeAnnotation()
	end

	return ast.Node(
		start,
		ast.Function,
		{
			name       = name,
			parameters = parameters,
			types      = types,
			body       = parser.parseBlockStatement(),
		}
	)
end


function parser.parseIfStatement()
	local start = #newlines

	local keyword = shift().value

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
		condition = parser.parseExpression()
	end

	local statement = ast.Node(
		start,
		ast.IfStatement,
		{
			keyword   = keyword,
			body      = parser.parseBlockStatement(),
			condition = condition,
		}
	)

	if tokenizedCode[1].value == "else" or tokenizedCode[1].value == "elseif" then
		tablex.push(statement.value, parser.parseIfStatement())
	end

	return statement
end


function parser.parseLoop()
	local start = #newlines

	local keyword = shift().value

	if tokenizedCode[1].value == "{" then
		print("error while parsing" .. keyword .. " loop at line " .. start .. ": expected expression, got block instead")
		os.exit()
	end

	local expression = parser.parseExpression()

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

		local token = shift()

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
				right    = parser.parseExpression(),
			}
		)
	end

	return ast.Node(
		start,
		ast.Loop,
		{
			keyword    = keyword,
			body       = parser.parseBlockStatement(),
			expression = expression,
		}
	)
end


function parser.parseSwitchStatement()
	local start = #newlines

	shift()

	local value = parser.parseExpression()

	local token = shift()

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
		shift()
	end

	local cases = {}

	while tokenizedCode[1].value == "case" do
		shift()

		local case = {
			values = {
				parser.parseExpression(),
			},
		}

		while tokenizedCode[1].value == "," do
			shift()

			tablex.push(case.values, parser.parseExpression())
		end

		token = shift()

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
			local statement = parser.parseStatement()

			if statement ~= nil and #statement == 2 and type(statement[2]) == "boolean" then
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
		shift()

		token = shift()

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
			local statement = parser.parseStatement()

			if statement ~= nil and #statement == 2 and type(statement[2]) == "boolean" then
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

	token = shift()

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


function parser.parseVariableAssignment()
	local left = parser.parseExpression()

	if tokenizedCode[1].type == tokens.assignmentOperator then
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseExpression()

		local token = shift()

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


function parser.parseVariableDeclaration()
	local start = #newlines

	local constant = shift().value == "let"

	local name = shift()

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
		shift()

		types = parser.parseTypeAnnotation()
	end

	local token = shift()

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
			token = shift()

			while tokenizedCode[1].type == tokens.eol do
				shift()
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
			value    = parser.parseExpression(),
		}
	)

	if token.value ~= ";" then
		token = shift()

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


function parser.parseTypeAnnotation()
	local start = #newlines

	local identifier = shift()

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
			shift()

			for _, v in ipairs(parser.parseTypeAnnotation()) do
				tablex.push(types[1], v)
			end

			local token = shift()

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
			shift()

			for _, v in ipairs(parser.parseTypeAnnotation()) do
				tablex.push(types[1].keys, v)
			end

			local token = shift()

			if token.value ~= ":" then
				print(
					"error while parsing type annotation at line " .. start
					.. ": expected ':', got '"
					.. token.value
					.. "' instead"
				)

				os.exit()
			end

			for _, v in ipairs(parser.parseTypeAnnotation()) do
				tablex.push(types[1].values, v)
			end

			token = shift()

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
		shift()

		for _, v in ipairs(parser.parseTypeAnnotation()) do
			tablex.push(types, v)
		end
	end

	return types
end


function parser.parseExpression(brackets)
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

	local expression = parser.parseTernaryExpression()

	if expression ~= nil and tokenizedCode[1].type == tokens.str then
		if
			ast.expressions[
				string.upper(
					string.gsub(expression.type, "Expression", "")
				)
			] ~= nil
			or expression.type == ast.Identifier or expression.type == ast.Number
			and tokenizedCode[1].type == tokens.str
		then
			expression = ast.Node(
				expression.start,
				ast.BinaryExpression,
				{
					left     = expression,
					operator = "+",
					right    = parser.parsePrimaryExpression()
				}
			)
		end
	end

	return expression
end


function parser.parseTernaryExpression()
	local condition = parser.parseLogicalExpression()

	while tokenizedCode[1].value == "?" do
		local start = #newlines

		shift()

		local left = parser.parseLogicalExpression()

		local token = shift()

		if token.value ~= ":" then
			print(
				"error while parsing ternary expression at line " .. start
				.. ": expected ':', got '"
				.. token.value
				.. "' instead"
			)

			os.exit()
		end

		local right = parser.parseLogicalExpression()

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


function parser.parseLogicalExpression()
	local left = parser.parseBitwiseExpression()

	while tokenizedCode[1].value == "&&" or tokenizedCode[1].value == "||" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseBitwiseExpression()

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


function parser.parseBitwiseExpression()
	local left = parser.parseInequalExpression()

	while tokenizedCode[1].value == "&" or tokenizedCode[1].value == "|" or tokenizedCode[1].value == "^" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseInequalExpression()

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


function parser.parseInequalExpression()
	local left = parser.parseEqualExpression()

	while
		tokenizedCode[1].value == "<"
		or tokenizedCode[1].value == "<="
		or tokenizedCode[1].value == ">"
		or tokenizedCode[1].value == ">="
	do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseEqualExpression()

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


function parser.parseEqualExpression()
	local left = parser.parseShiftExpression()

	while tokenizedCode[1].value == "==" or tokenizedCode[1].value == "!=" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseShiftExpression()

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


function parser.parseShiftExpression()
	local left = parser.parseAdditiveExpression()

	while tokenizedCode[1].value == "<<" or tokenizedCode[1].value == ">>" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseAdditiveExpression()

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


function parser.parseAdditiveExpression()
	local left = parser.parseMultiplicativeExpression()

	while tokenizedCode[1].value == "+" or tokenizedCode[1].value == "-" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseMultiplicativeExpression()

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


function parser.parseMultiplicativeExpression()
	local left = parser.parseExponentialExpression()

	while tokenizedCode[1].value == "*" or tokenizedCode[1].value == "/" or tokenizedCode[1].value == "%" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseExponentialExpression()

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


function parser.parseExponentialExpression()
	local left = parser.parseMemberExpression()

	while tokenizedCode[1].value == "**" or tokenizedCode[1].value == "//" do
		local start = #newlines

		local operator = shift().value
		local right    = parser.parseMemberExpression()

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


function parser.parseMemberExpression()
	local left = parser.parsePrimaryExpression()

	while tokenizedCode[1].value == "." do
		local start = #newlines

		shift()

		local right = parser.parsePrimaryExpression()

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


function parser.parsePrimaryExpression()
	local start = #newlines

	local token = shift()

	if token.value == "func" then
		local func = parser.parseFunction(start)

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
		local value = parser.parseExpression(true)

		token = shift()

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
			parser.parseArray()
		)
	elseif token.value == "{" then
		return ast.Node(
			start,
			ast.Dictionary,
			parser.parseDictionary()
		)
	elseif token.value == "-" or token.value == "~" or token.value == "!" then
		local value = parser.parsePrimaryExpression()

		return ast.Node(
			start,
			ast.UnaryExpression,
			{
				operator = token.value,
				value    = value,
			}
		)
	elseif token.type == tokens.str then
		local str = ast.Node(
			start,
			ast.String,
			token.value
		)

		if
			tokens.operators[
				string.upper(
					string.gsub(tokenizedCode[1].type, "-.*", "")
				)
			] == nil
			and tokenizedCode[1].type ~= tokens.punctuation
			and tokenizedCode[1].type ~= tokens.eol and tokenizedCode[1].type ~= tokens.eof
		then
			str = ast.Node(
				start,
				ast.BinaryExpression,
				{
					left = str,
					operator = "+",
					right    = parser.parseExpression()
				}
			)
		end

		return str
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
						arguments = parser.parseArguments(),
					}
				)
			end
		end

		while tokenizedCode[1].value == "[" do
			shift()

			local right = parser.parseExpression(true)

			token = shift()

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
	elseif token.type == tokens.num then
		return ast.Node(
			start,
			ast.Number,
			token.value
		)
	elseif token.value == ";" then
		return parser.parseStatement()
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


function parser.parseArguments()
	local start = #newlines

	local token = shift()

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
		shift()
	end

	local arguments = {}

	if tokenizedCode[1].value ~= ")" then
		tablex.push(arguments, parser.parseExpression(true))

		while tokenizedCode[1].value == "," do
			shift()

			tablex.push(arguments, parser.parseExpression(true))
		end
	end

	token = shift()

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


function parser.parseArray()
	local start = #newlines

	while tokenizedCode[1].type == tokens.eol do
		shift()
	end

	local values = {}

	if tokenizedCode[1].value ~= "]" then
		tablex.push(values, parser.parseExpression(true))

		while tokenizedCode[1].value == "," do
			shift()

			if tokenizedCode[1].value == "]" then
				break
			end

			tablex.push(values, parser.parseExpression(true))
		end
	end

	local token = shift()

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


function parser.parseDictionary()
	local start = #newlines

	while tokenizedCode[1].type == tokens.eol do
		shift()
	end

	local values = {}

	if tokenizedCode[1].value ~= "}" then
		local key = parser.parseExpression(true)

		local token = shift()

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
				value = parser.parseExpression(true),
			}
		)

		while tokenizedCode[1].value == "," do
			shift()

			if tokenizedCode[1].value == "}" then
				break
			end

			key = parser.parseExpression(true)

			token = shift()

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
					value = parser.parseExpression(true),
				}
			)
		end
	end

	local token = shift()

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
	newlines    = {""}

	program = ast.Node(
		0,
		ast.Program,
		{
			body    = {},
			exports = {},
		}
	)

	tokenizedCode = tokenizer.tokenize(sourceCode)

	while tokenizedCode[1].type ~= tokens.eof do
		local statement = parser.parseStatement()

		if statement ~= nil and #statement == 2 and type(statement[2]) == "boolean" then
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
