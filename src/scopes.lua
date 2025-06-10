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


function scopes.findVariable(name, scope)
	if scope.variables[name] ~= nil then
		return scope
	end

	if scope.parent == nil then
		print("ERROR: Cannot find '" .. name .. "' in scope")
		os.exit()
	end

	return scopes.findVariable(name, scope.parent)
end


function scopes.declareVariable(name, value, constant, scope)
	local parent = scope

	while parent.variables[name] ~= nil do
		parent = parent.parent

		if parent == nil then
			print("ERROR: " .. name .. " is already defined")
			os.exit()
		end
	end

	scope.variables[name] = value

	if constant then
		scope.constants[name] = {}
	end

	return value
end


function scopes.assignVariable(name, value, scope)
	scope = scopes.findVariable(name, scope)

	if scope.constants[name] ~= nil then
		print("ERROR: " .. name .. " is a constant")
		os.exit()
	end

	scope.variables[name] = value
	return value
end


function scopes.lookupVariable(name, scope)
	scope = scopes.findVariable(name, scope)
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
		copy = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'copy' (expected 1): " .. #arguments)
				os.exit()
			end

			if arguments[1].type ~= tokens.array and arguments[1].type ~= tokens.dictionary then
				print("ERROR: Unexpected type of argument to function 'copy' (expected array or dictionary): " .. arguments[1].type)
				os.exit()
			end

			return tokens.Token(arguments[1].type, table.pack(table.unpack(arguments[1].value)))
		end),


		len = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'len' (expected 1): " .. #arguments)
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
				print("ERROR: Unexpected type of argument to function 'len' (expected array or string): " .. arguments[1].type)
				os.exit()
			end
		end),


		print = tokens.Token(tokens.nativeFunction, function(arguments)
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
						print("function " .. v.value.name)
					elseif v.type == tokens.array or v.type == tokens.dictionary then
						print(repr(v))
					else
						print(v.value)
					end
				end
			end
		end),


		randint = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments ~= 2 then
				print("ERROR: Unexpected number of arguments to function 'randint' (expected 0): " .. #arguments)
				os.exit()
			end

			if arguments[1].type ~= tokens.number then
				print("ERROR: Unexpected type of argument to function 'randint' (expected number): " .. arguments[1].type)
				os.exit()
			end

			if arguments[2].type ~= tokens.number then
				print("ERROR: Unexpected type of argument to function 'randint' (expected number): " .. arguments[2].type)
				os.exit()
			end

			if arguments[2].value < arguments[1].value then
				return tokens.Token(tokens.number, arguments[1].value)
			end

			return tokens.Token(
				tokens.number,
				math.random(round(arguments[1].value), round(arguments[2].value))
			)
		end),


		type = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'type' (expected 1): " .. #arguments)
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
		contains   = {},
		find       = {},
		insert     = {},
		pop        = {},
		push       = {},
		remove     = {},
		reverse    = {},
		sort       = {},
	},
	{
		contains = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'array.contains' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			for _, v in ipairs(arguments[2].value) do
				if v.value == arguments[4].value then
					return tokens.Token(tokens.boolean, true)
				end
			end

			return tokens.Token(tokens.boolean, false)
		end),


		find = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'array.find' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			local indices = {}

			for i, v in ipairs(arguments[2].value) do
				if v.value == arguments[4].value then
					tablex.push(indices, tokens.Token(tokens.number, i - 1))
				end
			end

			return tokens.Token(tokens.array, indices)
		end),


		insert = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 2 then
				print("ERROR: Unexpected number of arguments to function 'array.insert' (expected 2): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.insert' (expected array): " .. arguments[1].type)
				os.exit()
			end

			if arguments[5].type ~= tokens.number then
				print("ERROR: Unexpected type of argument to function 'array.insert' (expected number): " .. arguments[5].type)
				os.exit()
			end

			if arguments[5].value < 0 then
				arguments[5].value = arguments[5].value + #arguments[2].value + 1
			end

			table.insert(arguments[2].value, arguments[5].value + 1, arguments[4])

			return arguments[2]
		end),


		pop = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 0 then
				print("ERROR: Unexpected number of arguments to function 'array.pop' (expected 0): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.pop' (expected array): " .. arguments[1].type)
				os.exit()
			end

			tablex.pop(arguments[2].value)

			return arguments[2]
		end),


		push = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'array.push' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.push' (expected array): " .. arguments[1].type)
				os.exit()
			end

			tablex.push(arguments[2].value, arguments[4])

			return arguments[2]
		end),


		remove = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'array.remove' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.remove' (expected array): " .. arguments[1].type)
				os.exit()
			end

			if arguments[4].type ~= tokens.number then
				print("ERROR: Unexpected type of argument to function 'array.remove' (expected number): " .. arguments[4].type)
				os.exit()
			end

			if arguments[4].value < 0 then
				arguments[4].value = arguments[4].value + #arguments[2].value
			end

			table.remove(arguments[2].value, arguments[4].value + 1)

			return arguments[2]
		end),


		reverse = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 0 then
				print("ERROR: Unexpected number of arguments to function 'array.reverse' (expected 0): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.reverse' (expected array): " .. arguments[1].type)
				os.exit()
			end

			local value = {}

			for _, v in ipairs(arguments[2].value) do
				table.insert(value, 1, v)
			end

			arguments[2].value = value
			return arguments[2]
		end),


		sort = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 0 then
				print("ERROR: Unexpected number of arguments to function 'array.sort' (expected 0): " .. #arguments - 3)
				os.exit()
			end

			if arguments[1].type ~= tokens.identifier and arguments[1].type ~= tokens.array then
				print("ERROR: Unexpected type of caller to function 'array.sort' (expected array): " .. arguments[1].type)
				os.exit()
			end


			table.sort(arguments[2].value, function(a, b)
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

				return x < y
			end)


			return arguments[2]
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
		contains = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.contains' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			for _, v in ipairs(arguments[2].value) do
				if v.value.value == arguments[4].value then
					return tokens.Token(tokens.boolean, true)
				end
			end

			return tokens.Token(tokens.boolean, false)
		end),


		find = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.find' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			local keys = {}

			for _, v in ipairs(arguments[2].value) do
				if v.value.value == arguments[4].value then
					tablex.push(keys, v.key)
				end
			end

			return tokens.Token(tokens.array, keys)
		end),


		insert = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 2 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.insert' (expected 2): " .. #arguments - 3)
				os.exit()
			end

			for _, v in ipairs(arguments[2].value) do
				if v.key.value == arguments[5].value then
					v.value = arguments[4]
					return arguments[2]
				end
			end

			tablex.push(
				arguments[2].value,
				{
					key = arguments[5],
					value = arguments[4]
				}
			)

			return arguments[2]
		end),


		keys = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 0 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.keys' (expected 0): " .. #arguments - 3)
				os.exit()
			end

			local keys = {}

			for _, v in ipairs(arguments[2].value) do
				tablex.push(keys, v.key)
			end

			return tokens.Token(tokens.array, keys)
		end),


		remove = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 1 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.remove' (expected 1): " .. #arguments - 3)
				os.exit()
			end

			for i, v in ipairs(arguments[2].value) do
				if v.key.value == arguments[4].value then
					table.remove(arguments[2].value, i)
				end
			end

			return arguments[2]
		end),


		values = tokens.Token(tokens.nativeFunction, function(arguments)
			if #arguments - 3 ~= 0 then
				print("ERROR: Unexpected number of arguments to function 'dictionary.values' (expected 0): " .. #arguments - 3)
				os.exit()
			end

			local values = {}

			for _, v in ipairs(arguments[2].value) do
				tablex.push(values, v.value)
			end

			return tokens.Token(tokens.array, values)
		end),
	}
)

return scopes
