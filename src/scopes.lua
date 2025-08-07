local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local scopes = {}


function scopes.Scope(parent, inherited, constants, variables, types)
	constants = constants or {}
	variables = variables or {}
	types     = types     or {}


	return {
		parent    = parent,
		inherited = inherited,
		constants = constants,
		variables = variables,
		types     = types,
	}
end


function scopes.copyScope(scope)
	return scopes.Scope(
		scope.parent,
		tablex.copy(scope.inherited),
		tablex.copy(scope.constants),
		tablex.copy(scope.variables),
		tablex.copy(scope.types)
	)
end


function scopes.findVariable(name, scope, line)
	if scope.variables[name] ~= nil then
		return scope
	end

	if scope.parent == nil and scope.inherited == nil then
		print("error on line " .. line .. ": cannot find '" .. name .. "' in scope")
		os.exit()
	end

	return scopes.findVariable(name, scope.inherited or scope.parent, line)
end


function scopes.declareVariable(name, types, value, constant, scope, line)
	if scope.variables[name] ~= nil or scopes.global.constants[name] ~= nil then
		print("error on line " .. line .. ": '" .. name .. "' is already defined")
		os.exit()
	end

	scope.types[name]     = types
	scope.variables[name] = value

	if constant then
		scope.constants[name] = {}
	end

	return value
end


function scopes.assignVariable(name, value, scope, line)
	scope = scopes.findVariable(name, scope, line)

	if scope.constants[name] ~= nil then
		print("error while evaluating variable assignment at line " .. line .. ": '" .. name .. "' is a constant")
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
			if v.key.type == tokens.array or v.key.type == tokens.dictionary then
				text = text .. repr(v.key, indentation + 1)
			elseif v.key.type == tokens.string then
				text = text .. v.key.value
			else
				text = text .. tostring(v.key.value)
			end

			text = text .. ": "
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


scopes.global = scopes.Scope(
	nil,
	nil,
	{
		--FUNCTIONS
		print       = {},
		randint     = {},
		range       = {},
		typeof      = {},
		--FUNCTIONS

		--VARIABLES
		["true"]  = {},
		["false"] = {},
		null      = {},
		--VARIABLES
	},
	{
		--FUNCTIONS
		print = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments == 0 then
				print()
			else
				for _, argument in ipairs(arguments) do
					if argument.type == tokens.string then
						local value = string.gsub(argument.value, "\\\\", "\\")
						value = string.gsub(value, "\\\"", "\"")
						value = string.gsub(value, "\\n", "\n")

						print(string.sub(value, 2, #value - 1))
					elseif argument.type == tokens.nativeFunction then
						local name

						for _, scope in ipairs(scopes.scopes) do
							for k, v in pairs(scope.variables) do
								if v.value == argument.value then
									name = k
								end
							end
						end

						print("function '" .. name .. "'")
					elseif argument.type == tokens.userFunction then
						if argument.value.name == nil then
							print("anonymous function")
						else
							print("function '" .. argument.value.name .. "'")
						end
					elseif argument.type == tokens.array or argument.type == tokens.dictionary then
						print(repr(argument))
					elseif argument.type == tokens.case then
						print(argument.type .. "." .. argument.value[1])
					elseif argument.type == tokens.class or argument.type == tokens.enum or argument.type == tokens.module then
						print(argument.type .. " '" .. argument.value .. "'")
					elseif type(argument.value) == "table" then
						if #argument.value == 0 then
							print("instance of class '" .. argument.type .. "'")
						elseif #argument.value == 1 then
							print(argument.value[1])
						else
							local text = argument.value[1] .. "("

							for i, v in ipairs(argument.value[2]) do
								text = text .. v.value

								if i ~= #argument.value[2] then
									text = text .. ", "
								end
							end

							print(text .. ")")
						end
					else
						print(argument.value)
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
					"error while evaluating function 'randint' at line " .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(min.type)
					.. "' instead"
				)

				os.exit()
			end

			if max.type ~= tokens.number then
				print(
					"error while evaluating function 'randint' at line " .. line
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
					"error while evaluating function 'range' at line " .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(min.type)
					.. "' instead"
				)

				os.exit()
			end

			if max.type ~= tokens.number then
				print(
					"error while evaluating function 'range' at line " .. line
					.. ": expected number while evaluating argument #2, got '"
					.. string.lower(max.type)
					.. "' instead"
				)

				os.exit()
			end

			if step.type ~= tokens.number then
				print(
					"error while evaluating function 'range' at line " .. line
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


		typeof = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'type' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type == tokens.nativeFunction or arguments[1].type == tokens.userFunction then
				return tokens.Token(tokens.string, "\"function\"")
			else
				return tokens.Token(tokens.string, "\"" .. arguments[1].type .. "\"")
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


scopes.Array = scopes.Scope(
	nil,
	nil,
	{
		__init      = {},
		contains    = {},
		copy        = {},
		find        = {},
		insert      = {},
		length      = {},
		randelement = {},
		remove      = {},
		reverse     = {},
		sort        = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments > 1 then
				print(
					"error while evaluating function 'Array.__init' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if #arguments == 0 then
				return tokens.Token(tokens.array, {})
			end

			local str = arguments[1]

			if arguments[1].type == tokens.string then
				str = string.sub(arguments[1].value, 2, #arguments[1].value - 1)
			else
				str = tostring(arguments[1].value)
			end

			local self = tokens.Token(tokens.array, {})

			for character in str.gmatch(str, ".") do
				tablex.push(
					self.value,
					tokens.Token(tokens.string, "\"" .. character .. "\"")
				)
			end

			return self
		end),


		contains = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'Array.contains' at line " .. line
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


		copy = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Array.copy' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return tablex.copy(arguments[1])
		end),


		find = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'Array.find' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local indices = tokens.Token(tokens.array, {})

			for i, v in ipairs(arguments[1].value) do
				if v.value == arguments[2].value then
					tablex.push(
						indices.value,
						tokens.Token(tokens.number, i - 1)
					)
				end
			end

			return indices
		end),


		insert = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 < 1 or #arguments - 1 > 2 then
				print(
					"error while evaluating function 'Array.insert' at line " .. line
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
					"error while evaluating function 'Array.insert' at line " .. line
					.. ": expected number while evaluating argument #2, got '"
					.. string.lower(string.sub(arguments[3].type, 1, 1)) .. string.sub(arguments[3].type, 2, #arguments[3].type)
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


		length = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Array.length' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return tokens.Token(tokens.number, #arguments[1].value)
		end),


		randelement = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Array.randelement' at line " .. line
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
					"error while evaluating function 'Array.remove' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[2].type ~= tokens.number then
				print(
					"error while evaluating function 'Array.remove' at line " .. line
					.. ": expected number while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[2].type, 1, 1)) .. string.sub(arguments[2].type, 2, #arguments[2].type)
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
					"error while evaluating function 'Array.reverse' at line " .. line
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
					"error while evaluating function 'Array.sort' at line " .. line
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

scopes.bool = scopes.Scope(
	nil,
	nil,
	{
		__init = {}
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments > 1 then
				print(
					"error while evaluating function 'boolean.__init' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if #arguments == 0 then
				return tokens.Token(tokens.boolean, false)
			end

			local bool

			if arguments[1].type == tokens.null then
				bool = tokens.Token(tokens.boolean, false)
			elseif arguments[1].type == tokens.number then
				bool = tokens.Token(tokens.boolean, arguments[1].value ~= 0)
			elseif arguments[1].type == tokens.string then
				bool = tokens.Token(tokens.boolean, arguments[1].value == "\"true\"")
			end

			return bool
		end)
	}
)

scopes.Dictionary = scopes.Scope(
	nil,
	nil,
	{
		__init   = {},
		contains = {},
		copy     = {},
		find     = {},
		insert   = {},
		keys     = {},
		length   = {},
		remove   = {},
		values   = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments > 1 then
				print(
					"error while evaluating function 'Dictionary.__init' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if #arguments == 0 then
				return tokens.Token(tokens.dictionary, {})
			end

			local dict

			if arguments[1].type == tokens.array then
				dict = tokens.Token(tokens.dictionary, {})

				local value = {}

				for i, v in ipairs(arguments[1].value) do
					if i % 2 == 0 then
						value.value = v
						tablex.push(dict.value, value)
						value = {}
					else
						value.key = v
					end
				end

				if value.key ~= nil then
					value.value = tokens.Token(tokens.null, "null")
					tablex.push(dict.value, value)
				end
			end

			return dict
		end),


		contains = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'Dictionary.contains' at line " .. line
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


		copy = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Dictionary.copy' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return tablex.copy(arguments[1])
		end),


		find = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'Dictionary.find' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local keys = tokens.Token(tokens.array, {})

			for _, v in ipairs(arguments[1].value) do
				if v.value.value == arguments[2].value then
					tablex.push(keys.value, v.key)
				end
			end

			return keys
		end),


		insert = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 2 then
				print(
					"error while evaluating function 'Dictionary.insert' at line " .. line
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
					"error while evaluating function 'Dictionary.keys' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local keys = tokens.Token(tokens.array, {})

			for _, v in ipairs(arguments[1].value) do
				tablex.push(keys.value, v.key)
			end

			return keys
		end),


		length = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Array.length' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return tokens.Token(tokens.number, #arguments[1].value)
		end),


		remove = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'Dictionary.remove' at line " .. line
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
					"error while evaluating function 'Dictionary.values' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local values = tokens.Token(tokens.array, {})

			for _, v in ipairs(arguments[1].value) do
				tablex.push(values.value, v.value)
			end

			return values
		end),
	}
)

scopes.num = scopes.Scope(
	nil,
	nil,
	{
		__init = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments > 1 then
				print(
					"error while evaluating function 'num.__init' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if #arguments == 0 then
				return tokens.Token(tokens.number, 0)
			end

			local num

			if arguments[1].type == tokens.string then
				num = tokens.Token(
					tokens.number,
					tonumber(
						string.sub(
							arguments[1].value,
							2,
							#arguments[1].value - 1
						)
					)
				)

				if num.value == nil then
					return nil
				end
			elseif arguments[1].value == "true" then
				num = tokens.Token(tokens.number, 1)
			elseif arguments[1].value == "false" then
				num = tokens.Token(tokens.number, 0)
			else
				num = tokens.Token(tokens.number, tonumber(arguments[1].value))
			end

			return num
		end),
	}
)

scopes.str = scopes.Scope(
	nil,
	nil,
	{
		__init       = {},
		capitalize   = {},
		copy         = {},
		decapitalize = {},
		endswith     = {},
		length       = {},
		lower        = {},
		upper        = {},
		startswith   = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments > 1 then
				print(
					"error while evaluating function 'str.__init' at line " .. line
					.. ": expected 0-1 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if #arguments == 0 then
				return tokens.Token(tokens.string, "\"\"")
			end

			local str

			if arguments[1].type == tokens.array or arguments[1].type == tokens.dictionary then
				str = tokens.Token(tokens.string, "\"" .. repr(arguments[1].value) .. "\"")
			elseif arguments[1].type == tokens.string then
				str = arguments[1]
			else
				str = tokens.Token(tokens.string, "\"" .. tostring(arguments[1].value) .. "\"")
			end

			return str
		end),


		capitalize = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'str.capitalize' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local str = {}

			for character in string.gmatch(arguments[1].value, ".") do
				tablex.push(str, character)
			end

			local indices = {2}

			for i, v in ipairs(str) do
				if v == " " and i ~= #str - 1 then
					tablex.push(indices, i + 1)
				end
			end

			for _, v in ipairs(indices) do
				arguments[1].value = string.sub(arguments[1].value, 1, v - 1)
				.. string.upper(
					string.sub(arguments[1].value, v, v)
				)
				.. string.sub(arguments[1].value, v + 1, #arguments[1].value)
			end

			return arguments[1]
		end),


		decapitalize = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'str.decapitalize' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			arguments[1].value = "\""
			.. string.lower(string.sub(arguments[1].value, 2, 2))
			.. string.sub(arguments[1].value, 3, #arguments[1].value)

			return arguments[1]
		end),


		endswith = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'str.endswith' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type ~= tokens.string then
				print(
					"error while evaluating function 'str.endswith' at line " .. line
					.. ": expected string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			if "\"" .. string.sub(arguments[1].value, #arguments[1].value - 1, #arguments[1].value - 1) .. "\"" == arguments[2].value then
				return tokens.Token(tokens.boolean, true)
			end

			return tokens.Token(tokens.boolean, false)
		end),


		length = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'Array.length' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			return tokens.Token(tokens.number, #arguments[1].value)
		end),


		lower = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'str.lower' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			arguments[1].value = string.lower(arguments[1].value)
			return arguments[1]
		end),


		upper = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'str.upper' at line " .. line
					.. ": expected 0 arguments, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			arguments[1].value = string.upper(arguments[1].value)
			return arguments[1]
		end),


		startswith = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 1 then
				print(
					"error while evaluating function 'str.startswith' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type ~= tokens.string then
				print(
					"error while evaluating function 'str.startswith' at line " .. line
					.. ": expected string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			if "\"" .. string.sub(arguments[1].value, 2, 2) .. "\"" == arguments[2].value then
				return tokens.Token(tokens.boolean, true)
			end

			return tokens.Token(tokens.boolean, false)
		end),
	}
)


scopes.declareVariable(
	"Array",
	{},
	tokens.Token(tokens.class, "array", scopes.Array),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"bool",
	{},
	tokens.Token(tokens.class, "boolean", scopes.bool),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"Dictionary",
	{},
	tokens.Token(tokens.class, "dictionary", scopes.Dictionary),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"num",
	{},
	tokens.Token(tokens.class, "number", scopes.num),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"str",
	{},
	tokens.Token(tokens.class, "string", scopes.str),
	true,
	scopes.global,
	0
)


scopes.scopes = {
	scopes.global,
	scopes.Array,
	scopes.Dictionary,
	scopes.str,
}


return scopes
