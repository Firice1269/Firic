local ast    = require("src.ast")
local scopes = require("src.scopes")
local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local interpreter = {}


function interpreter.evaluateArray(array, scope)
	local values = {}

	for _, v in ipairs(array.value) do
		tablex.push(values, interpreter.evaluate(v, scope))
	end

	return tokens.Token(tokens.array, values)
end


function interpreter.evaluateBinaryExpression(expression, scope)
	local left     = interpreter.evaluate(expression.left, scope)
	local operator = expression.operator
	local right    = interpreter.evaluate(expression.right, scope)

	local result

	if operator == "<" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value < right.value)
		else
			print("ERROR: Unexpected argument types for operator '<' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "<=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value <= right.value)
		else
			print("ERROR: Unexpected argument types for operator '<=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "<<" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value << right.value)
		else
			print("ERROR: Unexpected argument types for operator '<<' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == ">" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value > right.value)
		else
			print("ERROR: Unexpected argument types for operator '>' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == ">=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value >= right.value)
		else
			print("ERROR: Unexpected argument types for operator '>=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == ">>" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.boolean, left.value >> right.value)
		else
			print("ERROR: Unexpected argument types for operator '>>' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "==" then
		result = tokens.Token(tokens.boolean, left.value == right.value)
	elseif operator == "!=" then
		result = tokens.Token(tokens.boolean, left.value ~= right.value)
	elseif operator == "&" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value & right.value)
		else
			print("ERROR: Unexpected argument types for operator '&' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "&&" then
		if left.type == tokens.boolean and right.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, left.value and right.value)
		else
			print("ERROR: Unexpected argument types for operator '&&' (expected booleans): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "|" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value | right.value)
		else
			print("ERROR: Unexpected argument types for operator '|' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "||" then
		if left.type == tokens.boolean and right.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, left.value or right.value)
		else
			print("ERROR: Unexpected argument types for operator '||' (expected booleans): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "^" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ~ right.value)
		else
			print("ERROR: Unexpected argument types for operator '^' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "**" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ^ right.value)
		else
			print("ERROR: Unexpected argument types for operator '**' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "//" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ^ (1 / right.value))
		else
			print("ERROR: Unexpected argument types for operator '//' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "*" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value * right.value)
		else
			print("ERROR: Unexpected argument types for operator '*' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "/" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value / right.value)
		else
			print("ERROR: Unexpected argument types for operator '/' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "%" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value % right.value)
		else
			print("ERROR: Unexpected argument types for operator '%' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "+" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value + right.value)
		elseif left.type == tokens.string and right.type == tokens.string then
			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			print("ERROR: Unexpected argument types for operator '+' (expected number or string): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "-" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value - right.value)
		else
			print("ERROR: Unexpected argument types for operator '-' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	end

	return result
end


function interpreter.evaluateDictionary(dictionary, scope)
	local keys   = {}
	local values = {}

	for _, v in ipairs(dictionary) do
		tablex.push(
			values,
			{
				key   = interpreter.evaluate(v.key, scope),
				value = interpreter.evaluate(v.value, scope),
			}
		)

		tablex.push(keys, tostring(values[#values].key))
	end

	table.sort(keys)

	for i, v in ipairs(keys) do
		if v == keys[i + 1] then
			print("ERROR: Duplicate key inside dictionary: " .. v)
			os.exit()
		end
	end

	return tokens.Token(tokens.dictionary, values)
end


function interpreter.evaluateFunctionCall(expression, scope)
	local arguments = {}

	for _, v in ipairs(expression.arguments) do
		tablex.push(arguments, interpreter.evaluate(v, scope))
	end

	local func = interpreter.evaluate(expression.callee, scope)

	if func.type == tokens.nativeFunction then
		return func.value(arguments) or tokens.Token(tokens.null, "null")
	elseif func.type == tokens.userFunction then
		func = func.value

		local parent = scope
		scope        = scopes.Scope(parent)

		for i, v in ipairs(func.parameters) do
			scopes.declareVariable(v, arguments[i], false, scope)
		end

		local value = tokens.Token(tokens.null, "null")

		for _, v in ipairs(func.body) do
			v = interpreter.evaluate(v, scope)

			if v ~= nil then
				if v.type == ast.Return then
					value = interpreter.evaluate(v.value, scope)
					break
				end
			end
		end

		return value
	end

	print("ERROR: Unexpected type of callee (expected function): " .. tablex.repr(func))
	os.exit()
end


function interpreter.evaluateLoop(statement, scope)
	local parent = scope
	scope        = scopes.Scope(parent)

	local value
	local broken

	while not broken do
		broken = false

		for _, v in ipairs(statement.value) do
			v = interpreter.evaluate(v, scope)

			if v ~= nil then
				if v.type == ast.Break then
					broken = true
					break
				elseif v.type == ast.Continue then
					break
				end

				value = v
			end
		end
	end

	return value
end


function interpreter.evaluateMemberExpression(expression, scope)
	local left   = expression.left
	local object = interpreter.evaluate(left, scope)

	if left.type == ast.Identifier then
		left.type = tokens.identifier
	elseif left.type == ast.MemberExpression then
		while left.type == ast.MemberExpression do
			left = left.value.left
		end
	else
		left = object
	end

	local member = expression.right

	if object.type == tokens.array then
		scope = scopes.Scope(
			scope,
			scopes.array.constants,
			scopes.array.variables
		)
	elseif object.type == tokens.dictionary then
		scope = scopes.Scope(
			scope,
			scopes.dictionary.constants,
			scopes.dictionary.variables
		)
	end

	if member.type == ast.FunctionCall then
		table.insert(member.value.arguments, 1, scope)
		table.insert(member.value.arguments, 1, object)
		table.insert(member.value.arguments, 1, left)
	end

	return interpreter.evaluate(member, scope)
end


function interpreter.evaluateIdentifier(identifier, scope)
	return scopes.lookupVariable(identifier.value, scope)
end


function interpreter.evaluateIfStatement(statement, scope, conditions)
	conditions = conditions or {}
	statement  = statement.value

	local condition = true

	if statement.keyword == "else" then
		for _, v in ipairs(conditions) do
			condition = condition and not v.value
		end

		condition = tokens.Token(tokens.boolean, condition)
	elseif statement.keyword == "elseif" then
		for _, v in ipairs(conditions) do
			condition = condition and not v.value
		end

		local v = interpreter.evaluate(statement.condition, scope)

		if v.type ~= tokens.boolean then
			print("ERROR: Unexpected elseif statement condition type (expected boolean): " .. tablex.repr(v))
			os.exit()
		end

		condition = tokens.Token(tokens.boolean, condition and v.value)
		tablex.push(conditions, condition)
	else
		condition = interpreter.evaluate(statement.condition, scope)
		tablex.push(conditions, condition)
	end

	if condition.type ~= tokens.boolean then
		print("ERROR: Unexpected if statement condition type (expected boolean): " .. tablex.repr(condition))
		os.exit()
	end

	local parent = scope
	scope        = scopes.Scope(parent)

	local value

	if condition.value then
		for _, v in ipairs(statement.body) do
			value = interpreter.evaluate(v, scope)
		end
	end

	if statement[1] ~= nil then
		value = interpreter.evaluateIfStatement(statement[1], scope, conditions) or value
	end

	return value
end


function interpreter.evaluateIndexExpression(expression, scope)
	local identifier = expression.identifier

	if type(identifier) == "string" then
		identifier = interpreter.evaluateIdentifier(
			ast.Node(ast.Identifier, identifier),
			scope
		)
	else
		identifier = interpreter.evaluate(identifier, scope)
	end

	local index = interpreter.evaluate(expression.index, scope)

	if identifier.type == tokens.array then
		if index.type ~= tokens.number then
			print("ERROR: Unexpected index type inside index expression (expected number): " .. index.type)
			os.exit()
		end

		if index.value < 0 then
			index.value = index.value + #identifier.value
		end

		local value = identifier.value[index.value + 1]

		if value == nil then
			return tokens.Token(tokens.null, "null")
		end

		return value
	elseif identifier.type == tokens.dictionary then
		for _, v in ipairs(identifier.value) do
			if index.value == v.key.value then
				return v.value
			end
		end

		return tokens.Token(tokens.null, "null")
	elseif identifier.type == tokens.string then
		local value = string.sub(string.sub(identifier.value, 2, #identifier.value - 1), index.value + 1, index.value + 1)

		if value == "" then
			return tokens.Token(tokens.null, "null")
		end

		return tokens.Token(tokens.string, "\"" .. value .. "\"")
	end
end


function interpreter.evaluateProgram(program, scope)
	local value = tokens.Token(tokens.null, "null")

	for _, statement in ipairs(program.value) do
		value = interpreter.evaluate(statement, scope)
	end

	return value
end


function interpreter.evaluateUnaryExpression(expression, scope)
	local operator = expression.operator
	local value    = interpreter.evaluate(expression.value, scope)

	local result

	if operator == "-" then
		if value.type == tokens.number then
			result = tokens.Token(tokens.number, -value.value)
		else
			print("ERROR: Unexpected argument type for operator '-' (expected number): " .. value.type)
			os.exit()
		end
	elseif operator == "~" then
		if value.type == tokens.number then
			result = tokens.Token(tokens.number, ~value.value)
		else
			print("ERROR: Unexpected argument type for operator '~' (expected number): " .. value.type)
			os.exit()
		end
	elseif operator == "!" then
		if value.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, not value.value)
		else
			print("ERROR: Unexpected argument type for operator '!' (expected boolean): " .. value.type)
			os.exit()
		end
	end

	return result
end


function interpreter.evaluateVariableAssignment(expression, scope)
	local name = expression.left

	if name.type ~= ast.Identifier then
		print("ERROR: Unexpected token inside variable assignment (expected identifier): " .. tablex.repr(name))
		os.exit()
	end

	local left = interpreter.evaluate(expression.left, scope)

	local operator = expression.operator
	local right    = interpreter.evaluate(expression.right, scope)

	local result = right

	if operator == "&=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value & right.value)
		else
			print("ERROR: Unexpected argument types for operator '&=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "&&=" then
		if left.type == tokens.boolean and right.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, left.value and right.value)
		else
			print("ERROR: Unexpected argument types for operator '&&=' (expected booleans): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "|=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value | right.value)
		else
			print("ERROR: Unexpected argument types for operator '|=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "||=" then
		if left.type == tokens.boolean and right.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, left.value or right.value)
		else
			print("ERROR: Unexpected argument types for operator '||=' (expected booleans): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "^=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ~ right.value)
		else
			print("ERROR: Unexpected argument types for operator '^=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "<<=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value << right.value)
		else
			print("ERROR: Unexpected argument types for operator '<<=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == ">>=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value >> right.value)
		else
			print("ERROR: Unexpected argument types for operator '>>=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "**=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ^ right.value)
		else
			print("ERROR: Unexpected argument types for operator '**=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "//=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value ^ (1 / right.value))
		else
			print("ERROR: Unexpected argument types for operator '//=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "*=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value * right.value)
		else
			print("ERROR: Unexpected argument types for operator '*=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "/=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value / right.value)
		else
			print("ERROR: Unexpected argument types for operator '/=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "%=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value % right.value)
		else
			print("ERROR: Unexpected argument types for operator '%=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "+=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value + right.value)
		elseif left.type == tokens.string and right.type == tokens.string then
			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			print("ERROR: Unexpected argument types for operator '+=' (expected numbers or strings): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	elseif operator == "-=" then
		if left.type == tokens.number and right.type == tokens.number then
			result = tokens.Token(tokens.number, left.value - right.value)
		else
			print("ERROR: Unexpected argument types for operator '-=' (expected numbers): " .. left.type .. ", " .. right.type)
			os.exit()
		end
	end

	return scopes.assignVariable(name.value, result, scope)
end


function interpreter.evaluateVariableDeclaration(statement, scope)
	local value = interpreter.evaluate(statement.value, scope) or tokens.Token(tokens.null, "null")
	return scopes.declareVariable(statement.name, value, statement.constant, scope)
end


function interpreter.evaluate(astNode, scope)
	if astNode.type == ast.Array then
		return interpreter.evaluateArray(astNode, scope)
	elseif astNode.type == ast.BinaryExpression then
		return interpreter.evaluateBinaryExpression(astNode.value, scope)
	elseif astNode.type == ast.Dictionary then
		return interpreter.evaluateDictionary(astNode.value, scope)
	elseif astNode.type == ast.FunctionCall then
		return interpreter.evaluateFunctionCall(astNode.value, scope)
	elseif astNode.type == ast.FunctionDefinition then
		return scopes.declareVariable(astNode.value.name, tokens.Token(tokens.userFunction, astNode.value), true, scope)
	elseif astNode.type == ast.Loop then
		return interpreter.evaluateLoop(astNode, scope)
	elseif astNode.type == ast.Identifier then
		return interpreter.evaluateIdentifier(astNode, scope)
	elseif astNode.type == ast.IfStatement then
		return interpreter.evaluateIfStatement(astNode, scope)
	elseif astNode.type == ast.IndexExpression then
		return interpreter.evaluateIndexExpression(astNode.value, scope)
	elseif astNode.type == ast.MemberExpression then
		return interpreter.evaluateMemberExpression(astNode.value, scope)
	elseif astNode.type == ast.Number then
		return tokens.Token(tokens.number, astNode.value)
	elseif astNode.type == ast.String then
		return tokens.Token(tokens.string, astNode.value)
	elseif astNode.type == ast.Program then
		return interpreter.evaluateProgram(astNode, scope)
	elseif astNode.type == ast.UnaryExpression then
		return interpreter.evaluateUnaryExpression(astNode.value, scope)
	elseif astNode.type == ast.VariableAssignment then
		return interpreter.evaluateVariableAssignment(astNode.value, scope)
	elseif astNode.type == ast.VariableDeclaration then
		return interpreter.evaluateVariableDeclaration(astNode.value, scope)
	else
		return astNode
	end
end


return interpreter
