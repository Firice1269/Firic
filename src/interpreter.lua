local ast    = require("src.ast")
local scopes = require("src.scopes")
local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local interpreter = {}


local function checkArgumentTypes(left, operator, right, line)
	if operator ~= "" then
		if operator == "&&" or operator == "||" then
			if left.type ~= tokens.boolean or right.type ~= tokens.boolean then
				print(
					"error while evaluating binary expression at line " .. line
					.. ": expected booleans while evaluating arguments of binary operator '" .. operator .. "', got '"
					.. left.type
					.. " " .. operator .. " "
					.. right.type
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
					.. left.type
					.. " " .. operator .. " "
					.. right.type
					.. "' instead"
				)

				os.exit()
			end
		elseif operator ~= "==" and operator ~= "!=" then
			if left.type ~= tokens.number or right.type ~= tokens.number then
				print(
					"error while evaluating binary expression at line " .. line
					.. ": expected numbers while evaluating arguments of binary operator '" .. operator .. "', got '"
					.. left.type
					.. " " .. operator .. " "
					.. right.type
					.. "' instead"
				)

				os.exit()
			end
		end
	end
end


function checkVariableTypes(name, types, value)
	local fail   = true
	local result = tablex.copy(value)

	if #types == 0 then
		fail = false
	else
		for _, t in ipairs(types) do
			if not fail then
				break
			end

			if type(t) == "table" then
				if t.keys == nil then
					if value.type == tokens.array then
						fail = false

						for i, v in ipairs(value.value) do
							local f, n, r = checkVariableTypes(name .. "[" .. i - 1 .. "]", t, v)
							fail = f

							if fail then
								name, result = n, r
								break
							end
						end
					end
				elseif value.type == tokens.dictionary then
					fail = false

					for i, v in ipairs(value.value) do
						local f, n, r = checkVariableTypes(name .. ".keys()[" .. i - 1 .. "]", t.keys, v.key)
						fail = f

						if fail then
							name, result = n, r
							break
						end

						f, n, r = checkVariableTypes(name .. "[" .. tostring(v.key.value) .. "]", t.values, v.value)
						fail = f

						if fail then
							name, result = n, r
							break
						end
					end
				else
					fail = true
				end
			elseif
				t ~= value.type and t ~= "function"
				or t ~= value.type and value.type ~= tokens.nativeFunction and value.type ~= tokens.userFunction
			then
				fail = true

				if value.type == tokens.number then
					if t == "float" then
						fail = false

						for _, v in ipairs(types) do
							if v == "int" or v == "num" then
								goto continue
							end
						end

						if string.find(tostring(value.value), "%.") == nil then
							result = tokens.Token(tokens.number, tonumber(value.value .. ".0"))
						end
					elseif t == "int" then
						fail = false

						for _, v in ipairs(types) do
							if v == "float" or v == "num" then
								goto continue
							end
						end

						if string.find(tostring(value.value), "%.") ~= nil then
							if value.value + 0.5 >= math.ceil(value.value) then
								result = tokens.Token(tokens.number, math.ceil(value.value))
							else
								result = tokens.Token(tokens.number, math.floor(value.value))
							end
						end
					elseif t == "num" then
						fail = false
					end
				end
			else
				fail = false
			end
		end

		::continue::
	end

	if result.type == tokens.nativeFunction or result.type == tokens.userFunction then
		result.type = "function"
	end

	return fail, name, result
end


function interpreter.evaluateArray(array, scope)
	local values = {}

	for _, v in ipairs(array.value) do
		tablex.push(values, interpreter.evaluate(v, scope))
	end

	return tokens.Token(tokens.array, values)
end


function interpreter.evaluateBinaryExpression(expression, scope)
	local left     = interpreter.evaluate(expression.value.left, scope)
	local operator = expression.value.operator
	local right    = interpreter.evaluate(expression.value.right, scope)

	checkArgumentTypes(left, operator, right, expression.start)

	local result

	if operator == "<" then
		result = tokens.Token(tokens.boolean, left.value < right.value)
	elseif operator == "<=" then
		result = tokens.Token(tokens.boolean, left.value <= right.value)
	elseif operator == "<<" then
		result = tokens.Token(tokens.boolean, left.value << right.value)
	elseif operator == ">" then
		result = tokens.Token(tokens.boolean, left.value > right.value)
	elseif operator == ">=" then
		result = tokens.Token(tokens.boolean, left.value >= right.value)
	elseif operator == ">>" then
		result = tokens.Token(tokens.boolean, left.value >> right.value)
	elseif operator == "==" then
		result = tokens.Token(tokens.boolean, left.value == right.value)
	elseif operator == "!=" then
		result = tokens.Token(tokens.boolean, left.value ~= right.value)
	elseif operator == "&" then
		result = tokens.Token(tokens.number, left.value & right.value)
	elseif operator == "&&" then
		result = tokens.Token(tokens.boolean, left.value and right.value)
	elseif operator == "|" then
		result = tokens.Token(tokens.number, left.value | right.value)
	elseif operator == "||" then
		result = tokens.Token(tokens.boolean, left.value or right.value)
	elseif operator == "^" then
		result = tokens.Token(tokens.number, left.value ~ right.value)
	elseif operator == "**" then
		result = tokens.Token(tokens.number, left.value ^ right.value)
	elseif operator == "//" then
		result = tokens.Token(tokens.number, left.value ^ (1 / right.value))
	elseif operator == "*" then
		result = tokens.Token(tokens.number, left.value * right.value)
	elseif operator == "/" then
		result = tokens.Token(tokens.number, left.value / right.value)
	elseif operator == "%" then
		result = tokens.Token(tokens.number, left.value % right.value)
	elseif operator == "+" then
		if left.type == tokens.string or right.type == tokens.string then
			if left.type == tokens.number then
				left = tokens.Token(tokens.string, "\"" .. tostring(left.value) .. "\"")
			elseif right.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"")
			end

			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			result = tokens.Token(tokens.number, left.value + right.value)
		end
	elseif operator == "-" then
		result = tokens.Token(tokens.number, left.value - right.value)
	end

	return result
end


function interpreter.evaluateClassDefinition(statement, scope)
	local inherited = statement.value.inherited

	if inherited ~= nil then
		inherited = interpreter.evaluateIdentifier(inherited, scope).class
	end

	local class = scopes.Scope(scope, tablex.copy(inherited))

	for _, v in ipairs(statement.value.body) do
		interpreter.evaluate(v, class)
	end

	return scopes.declareVariable(
		statement.value.name,
		{},
		tokens.Token(tokens.class, statement.value.name, class),
		true,
		scope,
		statement.start
	)
end


function interpreter.evaluateClassMethod(expression, scope, parent)
	local functionName = expression.value.call.value

	if string.sub(functionName, 1, 2) == "__" then
		if expression.start ~= nil then
			print(
				"error while evaluating function call at line ".. expression.start
				.. ": cannot explicitly call '" .. functionName .. "'"
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
				"error while evaluating function '" .. functionName .. "' at line " .. expression.start
				.. ": expected " .. #func.value.parameters .. " argument(s), got "
				.. #arguments
				.. " instead"
			)

			os.exit()
		end

		for i, v in ipairs(func.value.parameters) do
			local fail, name, result = checkVariableTypes(v.name, v.types, arguments[i])

			if fail then
				print(
					"error while evaluating function '" .. functionName .. "' at line " .. expression.start
					.. ": cannot set type of '" .. name .. "' to '" .. result.type .. "'"
				)

				os.exit()
			end

			if name == v.name then
				arguments[i] = tokens.Token(arguments[i].type, result.value, arguments[i].class)
			end

			scopes.declareVariable(v.name, v.types, arguments[i], i == 1, scope, expression.start)
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
		.. func.type
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

	return tokens.Token(tokens.dictionary, values)
end


function interpreter.evaluateEnum(statement, scope)
	local class = scopes.Scope()

	for _, v in ipairs(statement.value.body) do
		local name = v.value
		local value

		if v.value.parameters == nil then
			value = tokens.Token(statement.value.name, {name})
		else
			name  = name.name


			value = tokens.Token(
				tokens.nativeFunction,
				load(
					" \
					return function (arguments, line) \
						table.remove(arguments, 1) \
						 \
						if #arguments ~= " .. #v.value.parameters .. " then \
						 	print( \
								\"error while evaluating case '" .. name .. "' at line \" .. line \
								.. \": expected " .. #v.value.parameters .. " arguments, got \" \
								.. #arguments \
								.. \" instead\" \
							) \
							 \
							os.exit() \
						end \
						 \
						local value = { \
							type  = \"" .. statement.value.name .. "\", \
							value = {\"" .. name .. "\", {}}, \
						} \
						 \
						for i, v in ipairs(load(\"return " .. string.gsub(tablex.repr(v.value.parameters), "\n", "\\\n") .. "\")()) do \
							local fail, name, result = checkVariableTypes( \
								\"" .. name .. "[\" .. i - 1 .. \"]\", \
								v, \
								arguments[i] \
							) \
							\
							if fail then \
								print( \
									\"error while evaluating case '" .. name .. "' at line \" .. line \
									.. \": cannot set type of \" .. name .. \" to '\" .. result.type .. \"'\" \
								) \
								\
								os.exit() \
							end \
							 \
							if name == \"" .. name .. "[\" .. i - 1 .. \"]\" then \
								arguments[i] = { \
									type  = arguments[i].type, \
									value = result.value, \
									class = arguments[i].class, \
								} \
							end \
							 \
							table.insert(value.value[2], #value.value[2] + 1, arguments[i]) \
						end \
						 \
						return value \
					end \
					"
				)()
			)
		end

		scopes.declareVariable(
			name,
			{},
			value,
			true,
			class,
			statement.start
		)
	end

	tablex.push(scopes.scopes, class)

	return scopes.declareVariable(
		statement.value.name,
		{},
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
		return scopes.declareVariable(expression.value.name, expression.value.types, func, true, scope, expression.start)
	end
end


function interpreter.evaluateFunctionCall(expression, scope)
	local functionName = expression.value.call.value

	local func = interpreter.evaluate(expression.value.call, scope)

	local arguments = {}

	for _, v in ipairs(expression.value.arguments) do
		tablex.push(arguments, interpreter.evaluate(v, scope))
	end

	if func.type == tokens.class then
		functionName = functionName .. "__init"

		local init = func.class.variables.__init

		if init == nil then
			print(
				"error while evaluating class instance at line " .. expression.start
				.. ": expected initializer function ('__init') but found none"
			)

			os.exit()
		end

		if init.type == tokens.nativeFunction then
			if
				functionName == "str"
				and arguments[1] ~= nil and arguments[1].type ~= tokens.null and arguments[1].class.variables.__string ~= nil
			then
				return interpreter.evaluateClassMethod(
					ast.Node(
						nil,
						ast.FunctionCall,
						{
							call      = ast.Node(nil, ast.Identifier, "__str"),
							arguments = arguments
						}
					),
					arguments[1].class
				)
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
					"error while evaluating function '" .. functionName .. "' at line " .. expression.start
					.. ": expected " .. #init.value.parameters - 1 .. " argument(s), got "
					.. #arguments - 1
					.. " instead"
				)
				os.exit()
			end

			for i, v in ipairs(init.value.parameters) do
				local fail, name, result = checkVariableTypes(v.name, v.types, arguments[i])

				if fail then
					print(
						"error while evaluating function '" .. functionName .. "' at line " .. expression.start
						.. ": cannot set type of '" .. name .. "' to '" .. result.type .. "'"
					)

					os.exit()
				end

				if name == v.name then
					arguments[i] = tokens.Token(arguments[i].type, result.value, arguments[i].class)
				end

				scopes.declareVariable(v.name, v.types, arguments[i], i == 1, scope, expression.start)
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
			.. init.type
			.. "' instead"
		)

		os.exit()
	elseif func.type == tokens.nativeFunction then
		return func.value(arguments, expression.start) or tokens.Token(tokens.null, "null")
	elseif func.type == tokens.userFunction then
		scope = scopes.Scope(func.value.scope)

		if #arguments ~= #func.value.parameters then
			print(
				"error while evaluating function '" .. functionName .. "' at line " .. expression.start
				.. ": expected " .. #func.value.parameters .. " argument(s), got "
				.. #arguments
				.. " instead"
			)
			os.exit()
		end

		for i, v in ipairs(func.value.parameters) do
			local fail, name, result = checkVariableTypes(v.name, v.types, arguments[i])

			if fail then
				print(
					"error while evaluating function '" .. functionName .. "' at line " .. expression.start
					.. ": cannot set type of '" .. name .. "' to '" .. result.type .. "'"
				)

				os.exit()
			end

			if name == v.name then
				arguments[i] = tokens.Token(arguments[i].type, result.value, arguments[i].class)
			end

			scopes.declareVariable(v.name, v.types, arguments[i], false, scope, expression.start)
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

		local fail, name, result = checkVariableTypes(functionName, func.value.types, value)

		if fail then
			print(
				"error while evaluating function '" .. functionName .. "' at line " .. expression.start
				.. ": function '" .. functionName .. "' cannot return value of type '" .. result.type .. "'"
			)

			os.exit()
		end

		if name == functionName then
			value = tokens.Token(value.type, result.value, value.class)
		end

		return value
	end

	print(
		"error while evaluating function call at line " .. expression.start
		.. ": expected function, got '"
		.. func.type
		.. "' instead"
	)

	os.exit()
end


function interpreter.evaluateLoop(statement, scope)
	local value

	if statement.value.keyword == "for" then
		local array = interpreter.evaluate(statement.value.expression.value.right, scope)

		if array.type ~= tokens.array then
			print(
				"error while evaluating for loop at line" .. statement.start
				.. ": expected array while evaluating iterator, got '"
				.. array.type
				.. "' instead"
			)

			os.exit()
		end

		local broken = false

		for _, v in ipairs(array.value) do
			if broken then
				break
			end

			scope = scopes.Scope(scope)
			scopes.declareVariable(statement.value.expression.value.left.value, {}, v, false, scope, statement.start)

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

		while interpreter.evaluate(statement.value.expression, scope).value and not broken do
			scope = scopes.Scope(scope)

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

	if object.class == nil then
		if object.type == tokens.array or object.type == tokens.dictionary then
			scope = scopes[string.upper(string.sub(object.type, 1, 1)) .. string.sub(object.type, 2, #object.type)]
		elseif object.type == tokens.boolean or object.type == tokens.number or object.type == tokens.string then
			scope = scopes[object.type]
		end
	else
		scope = object.class
	end

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

		return interpreter.evaluateIndexExpression(member, scope)
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

		condition = tokens.Token(tokens.boolean, condition)
	elseif statement.keyword == "elseif" then
		for _, v in ipairs(conditions) do
			condition = condition and not v.value
		end

		local v = interpreter.evaluate(statement.condition, scope)

		if v.type ~= tokens.boolean then
			print(
				"error while evaluating elseif statement at line" .. statement.start
				.. ": expected boolean while evaluating condition, got '"
				.. v.type
				.. "' instead"
			)

			os.exit()
		end

		condition = tokens.Token(tokens.boolean, condition and v.value)
		tablex.push(conditions, condition)
	else
		condition = interpreter.evaluate(statement.condition, scope)
		tablex.push(conditions, condition)
	end

	if condition.type ~= tokens.boolean then
		print(
			"error while evaluating if statement at line" .. statement.start
			.. ": expected boolean while evaluating condition, got '"
			.. condition.type
			.. "' instead"
		)

		os.exit()
	end

	scope = scopes.Scope(scope)

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
				.. index.type
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

		return tokens.Token(tokens.string, "\"" .. value .. "\"")
	else
		print(
			"error while evaluating index expression at line " .. expression.start ..
			": expected array, dictionary, or string; got "
			.. left.type
			.. " instead"
		)

		os.exit()
	end
end


function interpreter.evaluateProgram(program, scope)
	local value = tokens.Token(tokens.null, "null")

	for _, statement in ipairs(program) do
		value = interpreter.evaluate(statement, scope)
	end

	return value
end


function interpreter.evaluateSwitchStatement(statement, scope)
	local value = interpreter.evaluate(statement.value.value, scope)

	for _, case in ipairs(statement.value.cases) do
		for _, v in ipairs(case.values) do
			if v.type == ast.MemberExpression and v.value.right.type == ast.FunctionCall then
				local left = interpreter.evaluate(v.value.left, scope)

				if left.type == tokens.enum then
					if type(value.value) == "table" and value.value[1] == v.value.right.value.call.value then
						scope = scopes.Scope(scope)

						for i, argument in ipairs(v.value.right.value.arguments) do
							if argument.type ~= ast.Identifier then
								print(
									"error while evaluating switch statement at line " .. argument.start
									.. ": expected identifier while evaluating enum case, got "
									.. string.lower(argument.type)
									.. " instead"
								)

								os.exit()
							end

							scopes.declareVariable(
								argument.value,
								{},
								value.value[2][i],
								true,
								scope,
								statement.start
							)
						end

						return interpreter.evaluateProgram(case.body, scope)
					end
				elseif value.value == left.value then
					return interpreter.evaluateProgram(case.body, scopes.Scope(scope))
				end
			elseif value.value == interpreter.evaluate(v, scope).value then
				return interpreter.evaluateProgram(case.body, scopes.Scope(scope))
			end
		end
	end

	if statement.value.default ~= nil then
		return interpreter.evaluateProgram(statement.value.default, scopes.Scope(scope))
	end
end


function interpreter.evaluateTernaryExpression(expression, scope)
	local condition = interpreter.evaluate(expression.value.condition, scope)

	if condition.type ~= tokens.boolean then
		print(
			"error while evaluating ternary expression at line" .. expression.start
			.. ": expected boolean while evaluating condition, got '"
			.. condition.type
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
			result = tokens.Token(tokens.number, -value.value)
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected number while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. value.type
				.. "' instead"
			)

			os.exit()
		end
	elseif operator == "~" then
		if value.type == tokens.number then
			result = tokens.Token(tokens.number, ~value.value)
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected number while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. value.type
				.. "' instead"
			)

			os.exit()
		end
	elseif operator == "!" then
		if value.type == tokens.boolean then
			result = tokens.Token(tokens.boolean, not value.value)
		else
			print(
				"error while evaluating unary expression at at line " .. expression.start
				.. ": expected boolean while evaluating arguments of unary operator '" .. operator .. "', got '"
				.. " " .. operator .. " "
				.. value.type
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
			.. variable.type
			.. "' instead"
		)

		os.exit()
	end

	local left     = interpreter.evaluateIdentifier(variable, scope)
	local operator = statement.value.operator
	local right    = interpreter.evaluate(statement.value.right, parent)

	checkArgumentTypes(left, string.sub(operator, 1, #operator - 1), right, statement.start)

	local result = right

	if operator == "&=" then
		result = tokens.Token(tokens.number, left.value & right.value)
	elseif operator == "&&=" then
		result = tokens.Token(tokens.boolean, left.value and right.value)
	elseif operator == "|=" then
		result = tokens.Token(tokens.number, left.value | right.value)
	elseif operator == "||=" then
		result = tokens.Token(tokens.boolean, left.value or right.value)
	elseif operator == "^=" then
		result = tokens.Token(tokens.number, left.value ~ right.value)
	elseif operator == "<<=" then
		result = tokens.Token(tokens.number, left.value << right.value)
	elseif operator == ">>=" then
		result = tokens.Token(tokens.number, left.value >> right.value)
	elseif operator == "**=" then
		result = tokens.Token(tokens.number, left.value ^ right.value)
	elseif operator == "//=" then
		result = tokens.Token(tokens.number, left.value ^ (1 / right.value))
	elseif operator == "*=" then
		result = tokens.Token(tokens.number, left.value * right.value)
	elseif operator == "/=" then
		result = tokens.Token(tokens.number, left.value / right.value)
	elseif operator == "%=" then
		result = tokens.Token(tokens.number, left.value % right.value)
	elseif operator == "+=" then
		if left.type == tokens.string or right.type == tokens.string then
			if left.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"")
			elseif right.type == tokens.number then
				right = tokens.Token(tokens.string, "\"" .. tostring(right.value) .. "\"")
			end

			result = tokens.Token(
				tokens.string,
				string.sub(left.value, 1, #left.value - 1) .. string.sub(right.value, 2, #right.value)
			)
		else
			result = tokens.Token(tokens.number, left.value + right.value)
		end
	elseif operator == "-=" then
		result = tokens.Token(tokens.number, left.value - right.value)
	end

	local fail, name, r = checkVariableTypes(
		variable.value,
		scopes.findVariable(variable.value, scope, statement.start).types[variable.value],
		result
	)

	if fail then
		print(
			"error while evaluating variable assignment at line " .. statement.start
			.. ": cannot set type of '" .. name .. "' to '" .. r.type .. "'"
		)

		os.exit()
	end

	if name == variable.value then
		result.value = r.value
	end

	return scopes.assignVariable(variable.value, result, scope, statement.start)
end


function interpreter.evaluateVariableDeclaration(statement, scope)
	local value = interpreter.evaluate(statement.value.value or ast.Node(nil, ast.Identifier, "null"), scope)

	local types = statement.value.types

	if types == nil then
		if statement.value.value == nil then
			types = {}
		else
			types = {value.type}
		end
	elseif #types == 1 and statement.value.value == nil then
		if type(types[1]) == "table" then
			if types[1].keys == nil then
				value = tokens.Token(tokens.array, {})
			else
				value = tokens.Token(tokens.dictionary, {})
			end
		elseif types[1] == "bool" then
			value = tokens.Token(tokens.boolean, false)
		elseif types[1] == "float" then
			value = tokens.Token(tokens.number, 0.0)
		elseif types[1] == "int" then
			value = tokens.Token(tokens.number, 0)
		elseif types[1] == "str" then
			value = tokens.Token(tokens.string, "\"\"")
		end
	end

	local fail, name, result = checkVariableTypes(statement.value.name, types, value)

	if fail and statement.value.value ~= nil then
		print(
			"error while evaluating variable declaration at line " .. statement.start
			.. ": cannot set type of '" .. name .. "' to '" .. result.type .. "'"
		)

		os.exit()
	end

	if name == statement.value.name then
		value = tokens.Token(value.type, result.value, value.class)
	end

	return scopes.declareVariable(
		statement.value.name,
		types,
		value,
		statement.value.constant,
		scope,
		statement.start
	)
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
		return tokens.Token(tokens.number, astNode.value)
	elseif astNode.type == ast.Program then
		return interpreter.evaluateProgram(astNode.value, scope)
	elseif astNode.type == ast.String then
		return tokens.Token(tokens.string, astNode.value)
	elseif astNode.type == ast.SwitchStatement then
		return interpreter.evaluateSwitchStatement(astNode, scope)
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
