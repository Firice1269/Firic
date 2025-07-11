local ast    = require("src.ast")
local scopes = require("src.scopes")
local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local interpreter = {}


local function checkArgumentTypes(left, operator, right, line)
	if operator == "&&" or operator == "||" then
		if left.type ~= tokens.boolean or right.type ~= tokens.boolean then
			print(
				"error while evaluating binary expression at line " .. line
				.. ": expected booleans while evaluating arguments of binary operator '" .. operator .. "', got '"
				.. string.lower(string.sub(left.type, 1, 1)) .. string.sub(left.type, 2, #left.type)
				.. " " .. operator .. " "
				.. string.lower(string.sub(right.type, 1, 1)) .. string.sub(right.type, 2, #right.type)
				.. "' instead"
			)

			os.exit()
		end
	elseif operator == "+" then
		if
			left.type ~= tokens.number and left.type ~= tokens.string
			or right.type ~= tokens.string and right.type ~= tokens.number
		then
			print(
				"error while evaluating binary expression at line " .. line
				.. ": expected numbers or strings while evaluating arguments of binary operator '" .. operator .. "', got '"
				.. string.lower(string.sub(left.type, 1, 1)) .. string.sub(left.type, 2, #left.type)
				.. " " .. operator .. " "
				.. string.lower(string.sub(right.type, 1, 1)) .. string.sub(right.type, 2, #right.type)
				.. "' instead"
			)

			os.exit()
		end
	elseif operator ~= "==" and operator ~= "!=" then
		if left.type ~= tokens.number or right.type ~= tokens.number then
			print(
				"error while evaluating binary expression at line " .. line
				.. ": expected numbers while evaluating arguments of binary operator '" .. operator .. "', got '"
				.. string.lower(string.sub(left.type, 1, 1)) .. string.sub(left.type, 2, #left.type)
				.. " " .. operator .. " "
				.. string.lower(string.sub(right.type, 1, 1)) .. string.sub(right.type, 2, #right.type)
				.. "' instead"
			)

			os.exit()
		end
	end
end


function interpreter.evaluateArray(array, scope)
	local values = {}

	for _, v in ipairs(array.value) do
		tablex.push(values, interpreter.evaluate(v, scope))
	end

	return tokens.Token(tokens.array, values, tablex.copy(scopes.array))
end


function interpreter.evaluateBinaryExpression(expression, scope)
	local left     = interpreter.evaluate(expression.value.left, scope)
	local operator = expression.value.operator
	local right    = interpreter.evaluate(expression.value.right, scope)

	checkArgumentTypes(left, operator, right, expression.start)

	local result

	if operator == "<" then
		result = tokens.Token(tokens.boolean, left.value < right.value, tablex.copy(scopes.boolean))
	elseif operator == "<=" then
		result = tokens.Token(tokens.boolean, left.value <= right.value, tablex.copy(scopes.boolean))
	elseif operator == "<<" then
		result = tokens.Token(tokens.boolean, left.value << right.value, tablex.copy(scopes.boolean))
	elseif operator == ">" then
		result = tokens.Token(tokens.boolean, left.value > right.value, tablex.copy(scopes.boolean))
	elseif operator == ">=" then
		result = tokens.Token(tokens.boolean, left.value >= right.value, tablex.copy(scopes.boolean))
	elseif operator == ">>" then
		result = tokens.Token(tokens.boolean, left.value >> right.value, tablex.copy(scopes.boolean))
	elseif operator == "==" then
		result = tokens.Token(tokens.boolean, left.value == right.value, tablex.copy(scopes.boolean))
	elseif operator == "!=" then
		result = tokens.Token(tokens.boolean, left.value ~= right.value, tablex.copy(scopes.boolean))
	elseif operator == "&" then
		result = tokens.Token(tokens.number, left.value & right.value, tablex.copy(scopes.number))
	elseif operator == "&&" then
		result = tokens.Token(tokens.boolean, left.value and right.value, tablex.copy(scopes.boolean))
	elseif operator == "|" then
		result = tokens.Token(tokens.number, left.value | right.value, tablex.copy(scopes.number))
	elseif operator == "||" then
		result = tokens.Token(tokens.boolean, left.value or right.value, tablex.copy(scopes.boolean))
	elseif operator == "^" then
		result = tokens.Token(tokens.number, left.value ~ right.value, tablex.copy(scopes.number))
	elseif operator == "**" then
		result = tokens.Token(tokens.number, left.value ^ right.value, tablex.copy(scopes.number))
	elseif operator == "//" then
		result = tokens.Token(tokens.number, left.value ^ (1 / right.value), tablex.copy(scopes.number))
	elseif operator == "*" then
		result = tokens.Token(tokens.number, left.value * right.value, tablex.copy(scopes.number))
	elseif operator == "/" then
		result = tokens.Token(tokens.number, left.value / right.value, tablex.copy(scopes.number))
	elseif operator == "%" then
		result = tokens.Token(tokens.number, left.value % right.value, tablex.copy(scopes.number))
	elseif operator == "+" then
		if left.type == tokens.string or right.type == tokens.string then
			if left.type == tokens.number then
				left = tokens.Token(tokens.string, "\"" .. tostring(left.value) .. "\"", tablex.copy(scopes.string))
			elseif right.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"", tablex.copy(scopes.string))
			end

			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			result = tokens.Token(tokens.number, left.value + right.value, tablex.copy(scopes.number))
		end
	elseif operator == "-" then
		result = tokens.Token(tokens.number, left.value - right.value, tablex.copy(scopes.number))
	end

	return result
end


function interpreter.evaluateClassDefinition(statement, scope)
	local inherited = statement.value.inherited

	if inherited ~= nil then
		inherited = interpreter.evaluate(inherited, scope).class
	end

	local class = scopes.Scope(scope, tablex.copy(inherited))

	for _, v in ipairs(statement.value.body) do
		interpreter.evaluate(v, class)
	end

	return scopes.declareVariable(
		statement.value.name,
		tokens.Token(tokens.class, statement.value.name, class),
		true,
		scope,
		statement.start
	)
end


function interpreter.evaluateClassMethod(expression, scope, parent)
	if string.sub(expression.value.call.value, 1, 2) == "__" then
		if expression.start ~= nil then
			print(
				"error while evaluating function call at line ".. expression.start
				.. ": cannot explicitly call '" .. expression.value.call.value .. "'"
			)

			os.exit()
		end
	end

	local func = interpreter.evaluate(expression.value.call, scope)

	parent, scope.parent = scope.parent, parent

	local arguments = {}

	for _, v in ipairs(expression.value.arguments) do
		tablex.push(arguments, interpreter.evaluate(v, scope))
	end

	if func.type == tokens.nativeFunction then
		return func.value(arguments, expression.start) or tokens.Token(tokens.null, "null")
	elseif func.type == tokens.userFunction then
		scope = scopes.Scope(tablex.copy(func.value.scope))

		if #arguments ~= #func.value.parameters then
			print(
				"error while evaluating function '" .. expression.value.call.value .. "' at line " .. expression.start
				.. ": expected " .. #func.value.parameters .. " argument(s), got "
				.. #arguments
				.. " instead"
			)
			os.exit()
		end

		for i, v in ipairs(func.value.parameters) do
			scopes.declareVariable(v, arguments[i], false, scope, expression.start)
		end

		local value = tokens.Token(tokens.null, "null")

		for _, v in ipairs(func.value.body) do
			v = interpreter.evaluate(v, scope)

			if v ~= nil then
				if v.type == ast.Return then
					value = interpreter.evaluate(v.value, scope)
					break
				end
			end
		end

		scope.parent = parent

		return value
	end

	print(
		"error while evaluating function call at line " .. expression.start
		.. ": expected function, got '"
		.. string.lower(string.sub(func.type, 1, 1)) .. string.sub(func.type, 2, #func.type)
		.. "' instead"
	)

	os.exit()
end


function interpreter.evaluateDictionary(dictionary, scope)
	local keys   = {}
	local values = {}

	for _, v in ipairs(dictionary.value) do
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
			print("error while parsing dictionary at line " .. dictionary.start .. ": duplicate key: " .. v)
			os.exit()
		end
	end

	return tokens.Token(tokens.dictionary, values, tablex.copy(scopes.dictionary))
end


function interpreter.evaluateEnum(statement, scope)
	local class = scopes.Scope()

	for _, v in ipairs(statement.value.body) do
		scopes.declareVariable(
			v,
			tokens.Token(tokens.case, {v}),
			true,
			class,
			statement.start
		)
	end

	return scopes.declareVariable(
		statement.value.name,
		tokens.Token(tokens.enum, statement.value.name, class),
		true,
		scope,
		statement.start
	)
end


function interpreter.evaluateFunction(expression, scope)
	local func = tokens.Token(tokens.userFunction, expression.value)
	func.value.scope = scope

	if expression.value.name == nil then
		return func
	else
		return scopes.declareVariable(expression.value.name, func, true, scope, expression.start)
	end
end


function interpreter.evaluateFunctionCall(expression, scope)
	local func = interpreter.evaluate(expression.value.call, scope)

	local arguments = {}

	for _, v in ipairs(expression.value.arguments) do
		tablex.push(arguments, interpreter.evaluate(v, scope))
	end

	if func.type == tokens.class then
		local init = func.class.variables.__init

		if init == nil then
			print(
				"error while evaluating class instance at line " .. expression.start
				.. ": expected initializer function ('__init') but found none"
			)

			os.exit()
		end

		if init.type == tokens.nativeFunction then
			if expression.value.call.value == "string" then
				if #arguments ~= 1 then
					print(
						"error while evaluating function 'string.__init' at line " .. expression.start
						.. ": expected 1 argument, got "
						.. #arguments
						.. " instead"
					)

					os.exit()
				end

				if
					arguments[1].type ~= tokens.array
					and arguments[1].type ~= tokens.boolean
					and arguments[1].type ~= tokens.dictionary
					and arguments[1].type ~= tokens.null
					and arguments[1].type ~= tokens.number
					and arguments[1].type ~= tokens.string
				then
					if arguments[1].class.variables.__string ~= nil then
						return interpreter.evaluateClassMethod(
							ast.Node(
								nil,
								ast.FunctionCall,
								{
									call      = ast.Node(nil, ast.Identifier, "__string"),
									arguments = arguments
								}
							),
							arguments[1].class
						)
					end
				end
			end

			return init.value(arguments, expression.start) or tokens.Token(tokens.null, "null")
		elseif init.type == tokens.userFunction then
			local parent        = scope
			scope               = scopes.Scope(init.value.scope)
			scope.parent.parent = parent

			local instance = tokens.Token(expression.value.call.value, {}, tablex.copy(func.class))
			instance.class.parent = nil

			if instance.class.inherited ~= nil then
				instance.class.inherited.parent = nil
			end

			table.insert(arguments, 1, instance)

			if #arguments ~= #init.value.parameters then
				print(
					"error while evaluating function '" .. expression.value.call.value .. ".__init' at line " .. expression.start
					.. ": expected " .. #init.value.parameters - 1 .. " argument(s), got "
					.. #arguments - 1
					.. " instead"
				)
				os.exit()
			end

			for i, v in ipairs(init.value.parameters) do
				scopes.declareVariable(v, arguments[i], i == 1, scope, expression.start)
			end

			for _, v in ipairs(init.value.body) do
				v = interpreter.evaluate(v, scope)

				if v ~= nil then
					if v.type == ast.Return then
						instance = interpreter.evaluate(v.value, scope)
						break
					end
				end
			end

			scope.parent.parent = nil

			return instance
		end

		print(
			"error while evaluating class instance at line " .. expression.start
			.. ": expected function while evaluating initializer ('__init'), got '"
			.. string.lower(string.sub(init.type, 1, 1)) .. string.sub(init.type, 2, #init.type)
			.. "' instead"
		)

		os.exit()
	elseif func.type == tokens.nativeFunction then
		return func.value(arguments, expression.start) or tokens.Token(tokens.null, "null")
	elseif func.type == tokens.userFunction then
		scope = scopes.Scope(func.value.scope)

		if #arguments ~= #func.value.parameters then
			print(
				"error while evaluating function '" .. expression.value.call.value .. "' at line " .. expression.start
				.. ": expected " .. #func.value.parameters .. " argument(s), got "
				.. #arguments
				.. " instead"
			)
			os.exit()
		end

		for i, v in ipairs(func.value.parameters) do
			scopes.declareVariable(v, arguments[i], false, scope, expression.start)
		end

		local value = tokens.Token(tokens.null, "null")

		for _, v in ipairs(func.value.body) do
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

	print(
		"error while evaluating function call at line " .. expression.start
		.. ": expected function, got '"
		.. string.lower(string.sub(func.type, 1, 1)) .. string.sub(func.type, 2, #func.type)
		.. "' instead"
	)

	os.exit()
end


function interpreter.evaluateLoop(statement, scope)
	local parent = scope

	local value

	if statement.value.keyword == "for" then
		local array = interpreter.evaluate(statement.value.expression.value.right, parent)

		if array.type ~= tokens.array then
			print(
				"error while evaluating for loop at line" .. statement.start
				.. ": expected array while evaluating iterator, got '"
				.. string.lower(string.sub(array.type, 1, 1)) .. string.sub(array.type, 2, #array.type)
				.. "' instead"
			)

			os.exit()
		end

		local broken = false

		for _, v in ipairs(array.value) do
			if broken then
				break
			end

			scope = scopes.Scope(parent)
			scopes.declareVariable(statement.value.expression.value.left.value, v, false, scope, statement.start)

			for _, w in ipairs(statement.value.body) do
				w = interpreter.evaluate(w, scope)

				if w ~= nil then
					if w.type == ast.Break then
						broken = true
						break
					elseif w.type == ast.Continue then
						break
					end

					value = w
				end
			end
		end
	elseif statement.value.keyword == "while" then
		local broken = false

		while interpreter.evaluate(statement.value.expression, parent).value and not broken do
			scope = scopes.Scope(parent)

			for _, v in ipairs(statement.value.body) do
				v = interpreter.evaluate(v, scope)

				if v ~= nil then
					if v.type == ast.Break then
						broken = true
						break
					elseif v.type == ast.Continue then
						break
					end
				end

				value = v
			end
		end
	end

	return value
end


function interpreter.evaluateMemberExpression(expression, scope)
	local left   = expression.value.left
	local object = interpreter.evaluate(left, scope)

	if left.type == ast.MemberExpression then
		while left.type == ast.MemberExpression do
			left = left.value.left
		end
	elseif left.type ~= ast.Identifier then
		left = interpreter.evaluate(left, scope)
	end

	if object.type == tokens.null then
		print("error while evaluating member expression at line " .. expression.start .. ": object is null")
		os.exit()
	end

	local parent = scope
	scope        = object.class

	local member = expression.value.right

	if member.type == ast.IndexExpression then
		if member.value.left.type == ast.FunctionCall then
			table.insert(member.value.left.value.arguments, 1, object)
			left = interpreter.evaluateClassMethod(member.value.left, scope, parent)
			table.remove(member.value.left.value.arguments, 1)

			return interpreter.evaluateIndexExpression(
				ast.Node(
					member.start,
					ast.IndexExpression,
					{
						left  = left,
						right = member.value.right,
					}
				),
				scope
			)
		end

		return interpreter.evaluate(member, scope)
	elseif member.type == ast.Identifier then
		return interpreter.evaluateIdentifier(member, scope)
	elseif member.type == ast.FunctionCall then
		table.insert(member.value.arguments, 1, object)
		left = interpreter.evaluateClassMethod(member, scope, parent)
		table.remove(member.value.arguments, 1)

		return left
	end
end


function interpreter.evaluateIdentifier(identifier, scope)
	return scopes.lookupVariable(identifier.value, scope, identifier.start)
end


function interpreter.evaluateIfStatement(statement, scope, conditions)
	conditions = conditions or {}
	statement  = statement.value

	local condition = true

	if statement.keyword == "else" then
		for _, v in ipairs(conditions) do
			condition = condition and not v.value
		end

		condition = tokens.Token(tokens.boolean, condition, tablex.copy(scopes.boolean))
	elseif statement.keyword == "elseif" then
		for _, v in ipairs(conditions) do
			condition = condition and not v.value
		end

		local v = interpreter.evaluate(statement.condition, scope)

		if v.type ~= tokens.boolean then
			print(
				"error while evaluating elseif statement at line" .. statement.start
				.. ": expected boolean while evaluating condition, got '"
				.. string.lower(string.sub(v.type, 1, 1)) .. string.sub(v.type, 2, #v.type)
				.. "' instead"
			)

			os.exit()
		end

		condition = tokens.Token(tokens.boolean, condition and v.value, tablex.copy(scopes.boolean))
		tablex.push(conditions, condition)
	else
		condition = interpreter.evaluate(statement.condition, scope)
		tablex.push(conditions, condition)
	end

	if condition.type ~= tokens.boolean then
		print(
			"error while evaluating if statement at line" .. statement.start
			.. ": expected boolean while evaluating condition, got '"
			.. string.lower(string.sub(condition.type, 1, 1)) .. string.sub(condition.type, 2, #condition.type)
			.. "' instead"
		)

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
	local left = expression.value.left

	if left.type == tokens.identifier then
		left = interpreter.evaluateIdentifier(
			ast.Node(left.start, ast.Identifier, left.value),
			scope
		)
	else
		left = interpreter.evaluate(left, scope)
	end

	local index = interpreter.evaluate(expression.value.right, scope)

	if left.type == tokens.array then
		if index.type ~= tokens.number then
			print(
				"error while evaluating index expression at line " .. expression.start
				.. ": expected number while evaluating index, got '"
				.. string.lower(string.sub(index.type, 1, 1)) .. string.sub(index.type, 2, #index.type)
				.. "' instead"
			)

			os.exit()
		end

		if index.value < 0 then
			index.value = index.value + #left.value
		end

		local value = left.value[index.value + 1]

		if value == nil then
			return tokens.Token(tokens.null, "null")
		end

		return value
	elseif left.type == tokens.dictionary then
		for _, v in ipairs(left.value) do
			if index.value == v.key.value then
				return v.value
			end
		end

		return tokens.Token(tokens.null, "null")
	elseif left.type == tokens.string then
		local value = string.sub(string.sub(left.value, 2, #left.value - 1), index.value + 1, index.value + 1)

		if value == "" then
			return tokens.Token(tokens.null, "null")
		end

		return tokens.Token(tokens.string, "\"" .. value .. "\"", tablex.copy(scopes.string))
	end
end


function interpreter.evaluateProgram(program, scope)
	local value = tokens.Token(tokens.null, "null")

	for _, statement in ipairs(program.value) do
		value = interpreter.evaluate(statement, scope)
	end

	return value
end


function interpreter.evaluateTernaryExpression(expression, scope)
	local condition = interpreter.evaluate(expression.value.condition, scope)

	if condition.type ~= tokens.boolean then
		print(
			"error while evaluating ternary expression at line" .. expression.start
			.. ": expected boolean while evaluating condition, got '"
			.. string.lower(string.sub(condition.type, 1, 1)) .. string.sub(condition.type, 2, #condition.type)
			.. "' instead"
		)

		os.exit()
	end

	if condition.value then
		return interpreter.evaluate(expression.value.left, scope)
	else
		return interpreter.evaluate(expression.value.right, scope)
	end
end


function interpreter.evaluateUnaryExpression(expression, scope)
	local operator = expression.value.operator
	local value    = interpreter.evaluate(expression.value.value, scope)

	local result

	if operator == "-" then
		if value.type == tokens.number then
			result = tokens.Token(tokens.number, -value.value, tablex.copy(scopes.number))
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected number while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. string.lower(string.sub(value.type, 1, 1)) .. string.sub(value.type, 2, #value.type)
				.. "' instead"
			)

			os.exit()
		end
	elseif operator == "~" then
		if value.type == tokens.number then
			result = tokens.Token(tokens.number, ~value.value, tablex.copy(scopes.number))
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected number while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. string.lower(string.sub(value.type, 1, 1)) .. string.sub(value.type, 2, #value.type)
				.. "' instead"
			)

			os.exit()
		end
	elseif operator == "!" then
		if value.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, not value.value, tablex.copy(scopes.boolean))
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected boolean while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. string.lower(string.sub(value.type, 1, 1)) .. string.sub(value.type, 2, #value.type)
				.. "' instead"
			)

			os.exit()
		end
	end

	return result
end


function interpreter.evaluateVariableAssignment(statement, scope)
	local parent = scope

	local variable = statement.value.left

	while variable.type == ast.MemberExpression do
		scope    = interpreter.evaluate(variable.value.left, scope).class
		variable = variable.value.right
	end

	if variable.type ~= ast.Identifier then
		print(
			"error while evaluating variable assignment at line " .. statement.start
			.. ": expected memberExpression or identifier while parsing variable name, got '"
			.. string.lower(string.sub(variable.type, 1, 1)) .. string.sub(variable.type, 2, #variable.type)
			.. "' instead"
		)

		os.exit()
	end

	local left     = interpreter.evaluate(variable, scope)
	local operator = statement.value.operator
	local right    = interpreter.evaluate(statement.value.right, parent)

	if operator == "=" then
		return scopes.assignVariable(variable.value, right, scope, statement.start)
	end

	checkArgumentTypes(left, string.sub(operator, 1, #operator - 1), right, statement.start)

	local result

	if operator == "&=" then
		result = tokens.Token(tokens.number, left.value & right.value, tablex.copy(scopes.number))
	elseif operator == "&&=" then
		result = tokens.Token(tokens.boolean, left.value and right.value, tablex.copy(scopes.boolean))
	elseif operator == "|=" then
		result = tokens.Token(tokens.number, left.value | right.value, tablex.copy(scopes.number))
	elseif operator == "||=" then
		result = tokens.Token(tokens.boolean, left.value or right.value, tablex.copy(scopes.boolean))
	elseif operator == "^=" then
		result = tokens.Token(tokens.number, left.value ~ right.value, tablex.copy(scopes.number))
	elseif operator == "<<=" then
		result = tokens.Token(tokens.number, left.value << right.value, tablex.copy(scopes.number))
	elseif operator == ">>=" then
		result = tokens.Token(tokens.number, left.value >> right.value, tablex.copy(scopes.number))
	elseif operator == "**=" then
		result = tokens.Token(tokens.number, left.value ^ right.value, tablex.copy(scopes.number))
	elseif operator == "//=" then
		result = tokens.Token(tokens.number, left.value ^ (1 / right.value), tablex.copy(scopes.number))
	elseif operator == "*=" then
		result = tokens.Token(tokens.number, left.value * right.value, tablex.copy(scopes.number))
	elseif operator == "/=" then
		result = tokens.Token(tokens.number, left.value / right.value, tablex.copy(scopes.number))
	elseif operator == "%=" then
		result = tokens.Token(tokens.number, left.value % right.value, tablex.copy(scopes.number))
	elseif operator == "+=" then
		if left.type == tokens.string or right.type == tokens.string then
			if left.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"", tablex.copy(scopes.string))
			elseif right.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"", tablex.copy(scopes.string))
			end

			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			result = tokens.Token(tokens.number, left.value + right.value, tablex.copy(scopes.number))
		end
	elseif operator == "-=" then
		result = tokens.Token(tokens.number, left.value - right.value, tablex.copy(scopes.number))
	end

	return scopes.assignVariable(variable.value, result, scope, statement.start)
end


function interpreter.evaluateVariableDeclaration(statement, scope)
	local value = interpreter.evaluate(statement.value.value, scope) or tokens.Token(tokens.null, "null")
	return scopes.declareVariable(statement.value.name, value, statement.value.constant, scope, statement.start)
end


function interpreter.evaluate(astNode, scope)
	if astNode.type == ast.Array then
		return interpreter.evaluateArray(astNode, scope)
	elseif astNode.type == ast.BinaryExpression then
		return interpreter.evaluateBinaryExpression(astNode, scope)
	elseif astNode.type == ast.ClassDefinition then
		return interpreter.evaluateClassDefinition(astNode, scope)
	elseif astNode.type == ast.Dictionary then
		return interpreter.evaluateDictionary(astNode, scope)
	elseif astNode.type == ast.Enum then
		return interpreter.evaluateEnum(astNode, scope)
	elseif astNode.type == ast.Function then
		return interpreter.evaluateFunction(astNode, scope)
	elseif astNode.type == ast.FunctionCall then
		return interpreter.evaluateFunctionCall(astNode, scope)
	elseif astNode.type == ast.Loop then
		return interpreter.evaluateLoop(astNode, scope)
	elseif astNode.type == ast.Identifier then
		return interpreter.evaluateIdentifier(astNode, scope)
	elseif astNode.type == ast.IfStatement then
		return interpreter.evaluateIfStatement(astNode, scope)
	elseif astNode.type == ast.IndexExpression then
		return interpreter.evaluateIndexExpression(astNode, scope)
	elseif astNode.type == ast.MemberExpression then
		return interpreter.evaluateMemberExpression(astNode, scope)
	elseif astNode.type == ast.Number then
		return tokens.Token(tokens.number, astNode.value, tablex.copy(scopes.number))
	elseif astNode.type == ast.Program then
		return interpreter.evaluateProgram(astNode, scope)
	elseif astNode.type == ast.String then
		return tokens.Token(tokens.string, astNode.value, tablex.copy(scopes.string))
	elseif astNode.type == ast.TernaryExpression then
		return interpreter.evaluateTernaryExpression(astNode, scope)
	elseif astNode.type == ast.UnaryExpression then
		return interpreter.evaluateUnaryExpression(astNode, scope)
	elseif astNode.type == ast.VariableAssignment then
		return interpreter.evaluateVariableAssignment(astNode, scope)
	elseif astNode.type == ast.VariableDeclaration then
		return interpreter.evaluateVariableDeclaration(astNode, scope)
	else
		return astNode
	end
end


return interpreter
