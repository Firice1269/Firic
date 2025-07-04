local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local scopes = {}


function scopes.Scope(parent, constants, variables)
	parent    = parent    or nil
	constants = constants or {}
	variables = variables or {}


	return {
		parent    = parent,
		constants = constants,
		variables = variables,
	}
end


function scopes.findVariable(name, scope, line)
	if scope.variables[name] ~= nil then
		return scope
	end

	if scope.parent == nil then
		print("error on line " .. line .. ": cannot find '" .. name .. "' in scope")
		os.exit()
	end

	return scopes.findVariable(name, scope.parent, line)
end


function scopes.declareVariable(name, value, constant, scope, line)
	local parent = scope

	while parent.variables[name] == nil do
		parent = parent.parent

		if parent == nil then
			break
		end
	end

	if parent ~= nil then
		print("error on line " .. line .. ": '" .. name .. "' is already defined")
		os.exit()
	end

	scope.variables[name] = value

	if constant then
		scope.constants[name] = {}
	end

	return value
end


function scopes.assignVariable(name, value, scope, line)
	scope = scopes.findVariable(name, scope, line)

	if scope.constants[name] ~= nil then
		print("error while evaluating variable assignment at line " .. line .. ": '" .. name .. "' is constant")
		os.exit()
	end

	scope.variables[name] = value
	return value
end


function scopes.lookupVariable(name, scope, line)
	scope = scopes.findVariable(name, scope, line)
	return scope.variables[name]
end


local function repr(structure, indentation)
	indentation = indentation or 0

	local text

	if structure.type == tokens.array then
		text = "[\n"
	elseif structure.type == tokens.dictionary then
		text = "{\n"
	end

	for _, v in ipairs(structure.value) do
		for _ = 0, indentation, 1 do
			text = text .. "  "
		end

		if structure.type == tokens.dictionary then
			text = text .. tostring(v.key.value) .. ": "
			v = v.value
		end

		if v.type == tokens.array or v.type == tokens.dictionary then
			text = text .. repr(v, indentation + 1)
		else
			text = text .. tostring(v.value)
		end

		text = text .. ",\n"
	end

	if #structure.value ~= 0 then
		text = string.sub(text, 1, #text - 2) .. "\n"
	end

	for _ = 1, indentation, 1 do
		text = text .. "  "
	end

	if structure.type == tokens.array then
		text = text .. "]"
	elseif structure.type == tokens.dictionary then
		text = text .. "}"
	end

	if #structure.value <= 1 then
		if #structure.value == 0 then
			if structure.type == tokens.array then
				text = "[]"
			elseif structure.type == tokens.dictionary then
				text = "{}"
			end
		elseif structure.type == tokens.array then
			if structure.value[1].type ~= tokens.array and structure.value[1].type ~= tokens.dictionary then
				text = string.gsub(text, "\n%s*", "")
			end
		end
	end

	return text
end


local function round(n)
	if n + 0.5 >= math.ceil(n) then
		return math.ceil(n)
	end

	return math.floor(n)
end


scopes.globalScope = scopes.Scope(
	nil,
	{
		--FUNCTIONS
		copy        = {},
		len         = {},
		print       = {},
		randint     = {},
		range       = {},
		type        = {},
		--FUNCTIONS

		--VARIABLES
		["true"]  = {},
		["false"] = {},
		null      = {},
		--VARIABLES
	},
	{
		--FUNCTIONS
		copy = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'copy' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type ~= tokens.array and arguments[1].type ~= tokens.dictionary then
				print(
					"error while evaluating function 'copy' at line" .. line
					.. ": expected array or dictionary while evaluating argument #1, got '"
					.. string.lower(arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			return tokens.Token(arguments[1].type, table.pack(table.unpack(arguments[1].value)))
		end),


		len = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'len' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type == tokens.array then
				return tokens.Token(tokens.number, #arguments[1].value)
			elseif arguments[1].type == tokens.string then
				return tokens.Token(
					tokens.number,
					string.len(
						string.sub(
							arguments[1].value,
							2,
							#arguments[1].value - 1
						)
					)
				)
			else
				print(
					"error while evaluating function 'len' at line" .. line
					.. ": expected array or string while evaluating argument #1, got '"
					.. string.lower(arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end
		end),


		print = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments == 0 then
				print()
			else
				for _, v in ipairs(arguments) do
					if v.type == tokens.string then
						local value = string.gsub(v.value, "\\\\", "\\")
						value = string.gsub(value, "\\\"", "\"")
						value = string.gsub(value, "\\n", "\n")

						print(string.sub(value, 2, #value - 1))
					elseif v.type == tokens.nativeFunction or v.type == tokens.userFunction then
						if v.value.name == nil then
							print("anonymous function")
						else
							print("function " .. v.value.name)
						end
					elseif v.type == tokens.array or v.type == tokens.dictionary then
						print(repr(v))
					else
						print(v.value)
					end
				end
			end
		end),


		randint = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments < 1 or #arguments > 2 then
				print(
					"error while evaluating function 'randint' at line " .. line
					.. ": expected 1-2 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local min
			local max

			if arguments[2] == nil then
				min = tokens.Token(tokens.number, 1)
				max = arguments[1]
			else
				min = arguments[1]
				max = arguments[2]
			end

			if min.type ~= tokens.number then
				print(
					"error while evaluating function 'randint' at line" .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(min.type)
					.. "' instead"
				)

				os.exit()
			end

			if max.type ~= tokens.number then
				print(
					"error while evaluating function 'randint' at line" .. line
					.. ": expected number while evaluating argument #2, got '"
					.. string.lower(max.type)
					.. "' instead"
				)

				os.exit()
			end

			if max.value < min.value then
				return tokens.Token(tokens.number, min.value)
			end

			return tokens.Token(
				tokens.number,
				math.random(round(min.value), round(max.value))
			)
		end),


		range = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments < 1 or #arguments > 3 then
				print(
					"error while evaluating function 'range' at line " .. line
					.. ": expected 1-3 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local min
			local max
			local step

			if arguments[2] == nil then
				min  = tokens.Token(tokens.number, 1)
				max  = arguments[1]
				step = tokens.Token(tokens.number, 1)
			elseif arguments[3] == nil then
				min  = arguments[1]
				max  = arguments[2]
				step = tokens.Token(tokens.number, 1)
			else
				min  = arguments[1]
				max  = arguments[2]
				step = arguments[3]
			end

			if min.type ~= tokens.number then
				print(
					"error while evaluating function 'range' at line" .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(min.type)
					.. "' instead"
				)

				os.exit()
			end

			if max.type ~= tokens.number then
				print(
					"error while evaluating function 'range' at line" .. line
					.. ": expected number while evaluating argument #2, got '"
					.. string.lower(max.type)
					.. "' instead"
				)

				os.exit()
			end

			if step.type ~= tokens.number then
				print(
					"error while evaluating function 'range' at line" .. line
					.. ": expected number while evaluating argument #3, got '"
					.. string.lower(step.type)
					.. "' instead"
				)

				os.exit()
			end

			local range = {}

			for i = min.value, max.value, step.value do
				tablex.push(
					range,
					tokens.Token(tokens.number, i)
				)
			end

			return tokens.Token(tokens.array, range)
		end),


		type = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'type' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type == tokens.array then
				return tokens.Token(tokens.string, "\"array\"")
			elseif arguments[1].type == tokens.boolean then
				return tokens.Token(tokens.string, "\"bool\"")
			elseif arguments[1].type == tokens.dictionary then
				return tokens.Token(tokens.string, "\"dict\"")
			elseif arguments[1].type == tokens.null then
				return tokens.Token(tokens.string, "\"null\"")
			elseif arguments[1].type == tokens.number then
				return tokens.Token(tokens.string, "\"num\"")
			elseif arguments[1].type == tokens.string then
				return tokens.Token(tokens.string, "\"str\"")
			elseif arguments[1].type == tokens.nativeFunction or arguments[1].type == tokens.userFunction then
				return tokens.Token(tokens.string, "\"func\"")
			end
		end),
		--FUNCTIONS

		--VARIABLES
		["true"]  = tokens.Token(tokens.boolean, true),
		["false"] = tokens.Token(tokens.boolean, false),
		null      = tokens.Token(tokens.null, "null"),
		--VARIABLES
	}
)

scopes.array = scopes.Scope(
	scopes.globalScope,
	{
		contains    = {},
		find        = {},
		insert      = {},
		pop         = {},
		push        = {},
		randelement = {},
		remove      = {},
		reverse     = {},
		sort        = {},
	},
	{
		contains = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'array.contains' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			for _, v in ipairs(arguments[1].value) do
				if v.value == arguments[2].value then
					return tokens.Token(tokens.boolean, true)
				end
			end

			return tokens.Token(tokens.boolean, false)
		end),


		find = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'array.find' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local indices = {}

			for i, v in ipairs(arguments[1].value) do
				if v.value == arguments[2].value then
					tablex.push(indices, tokens.Token(tokens.number, i - 1))
				end
			end

			return tokens.Token(tokens.array, indices)
		end),


		insert = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 < 1 or #arguments - 1 > 2 then
				print(
					"error while evaluating function 'array.insert' at line " .. line
					.. ": expected 1-2 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[3] == nil then
				tablex.push(arguments[1].value, arguments[2])
			else
				if arguments[3].type ~= tokens.number then
					print(
					"error while evaluating function 'array.insert' at line" .. line
					.. ": expected number while evaluating argument #2, got '"
					.. string.lower(arguments[3].type)
					.. "' instead"
				)

				os.exit()
				end

				if arguments[3].value < 0 then
					arguments[3].value = arguments[3].value + #arguments[1].value + 1
				end

				table.insert(arguments[1].value, arguments[3].value + 1, arguments[2])
			end

			return arguments[1]
		end),


		randelement = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'array.randelement' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return arguments[1].value[math.random(#arguments[1].value)]
		end),


		remove = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'array.remove' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[2].type ~= tokens.number then
				print(
					"error while evaluating function 'array.remove' at line" .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(arguments[2].type)
					.. "' instead"
				)

				os.exit()
			end

			if arguments[2].value < 0 then
				arguments[2].value = arguments[2].value + #arguments[1].value
			end

			table.remove(arguments[1].value, arguments[2].value + 1)

			return arguments[1]
		end),


		reverse = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'array.reverse' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local value = {}

			for _, v in ipairs(arguments[1].value) do
				table.insert(value, 1, v)
			end

			arguments[1].value = value
			return arguments[1]
		end),


		sort = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 > 1 then
				print(
					"error while evaluating function 'array.sort' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local descending = tokens.Token(tokens.boolean, false)

			if arguments[2] ~= nil then
				descending = arguments[2]
			end


			table.sort(arguments[1].value, function(a, b)
				local x = a.value
				local y = b.value

				if type(x) == "table" then
					x = #x
				end

				if type(y) == "table" then
					y = #y
				end

				if type(x) ~= "string" and type(y) == "string" then
					x = tostring(x)
				end

				if type(x) == "string" and type(y) ~= "string" then
					y = tostring(y)
				end

				if descending.value then
					return x > y
				else
					return x < y
				end
			end)


			return arguments[1]
		end),
	}
)

scopes.dictionary = scopes.Scope(
	scopes.globalScope,
	{
		contains = {},
		find     = {},
		insert   = {},
		keys     = {},
		remove   = {},
		values   = {},
	},
	{
		contains = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'dictionary.contains' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			for _, v in ipairs(arguments[1].value) do
				if v.value.value == arguments[2].value then
					return tokens.Token(tokens.boolean, true)
				end
			end

			return tokens.Token(tokens.boolean, false)
		end),


		find = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'dictionary.find' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local keys = {}

			for _, v in ipairs(arguments[1].value) do
				if v.value.value == arguments[2].value then
					tablex.push(keys, v.key)
				end
			end

			return tokens.Token(tokens.array, keys)
		end),


		insert = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 2 then
				print(
					"error while evaluating function 'dictionary.insert' at line " .. line
					.. ": expected 2 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			for _, v in ipairs(arguments[1].value) do
				if v.key.value == arguments[3].value then
					v.value = arguments[2]
					return arguments[1]
				end
			end

			tablex.push(
				arguments[1].value,
				{
					key = arguments[3],
					value = arguments[2]
				}
			)

			return arguments[1]
		end),


		keys = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'dictionary.keys' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local keys = {}

			for _, v in ipairs(arguments[1].value) do
				tablex.push(keys, v.key)
			end

			return tokens.Token(tokens.array, keys)
		end),


		remove = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'dictionary.remove' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			for i, v in ipairs(arguments[1].value) do
				if v.key.value == arguments[2].value then
					table.remove(arguments[1].value, i)
				end
			end

			return arguments[1]
		end),


		values = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'dictionary.values' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local values = {}

			for _, v in ipairs(arguments[1].value) do
				tablex.push(values, v.value)
			end

			return tokens.Token(tokens.array, values)
		end),
	}
)

return scopes
