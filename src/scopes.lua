local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local scopes = {}


function scopes.Scope(parent, inherited, constants, variables)
	constants = constants or {}
	variables = variables or {}


	return {
		parent    = parent,
		inherited = inherited,
		constants = constants,
		variables = variables,
	}
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


function scopes.declareVariable(name, value, constant, scope, line)
	if scope.variables[name] ~= nil or scopes.global.variables[name] ~= nil then
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
		copy        = {},
		len         = {},
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

			if arguments[1].type ~= tokens.array and arguments[1].type ~= tokens.dictionary and arguments[1].type ~= tokens.string then
				print(
					"error while evaluating function 'copy' at line " .. line
					.. ": expected array, dictionary, or string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			return tablex.copy(arguments[1])
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
				return tokens.Token(tokens.number, #arguments[1].value, tablex.copy(scopes.number))
			elseif arguments[1].type == tokens.string then
				return tokens.Token(
					tokens.number,
					string.len(
						string.sub(
							arguments[1].value,
							2,
							#arguments[1].value - 1
						)
					),
					tablex.copy(scopes.number)
				)
			else
				print(
					"error while evaluating function 'len' at line " .. line
					.. ": expected array or string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end
		end),


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
						local scope = {
							scopes.global,
							scopes.array,
							scopes.boolean,
							scopes.dictionary,
							scopes.number,
							scopes.string,
						}

						local name

						for _, s in ipairs(scope) do
							for k, v in pairs(s.variables) do
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
						print(argument.value[1])
					elseif argument.type == tokens.class then
						print("class '" .. argument.value .. "'")
					elseif argument.type == tokens.enum then
						print("enum '" .. argument.value .. "'")
					elseif argument.type == tokens.boolean or argument.type == tokens.null or argument.type == tokens.number then
						print(argument.value)
					else
						print("instance of class '" .. argument.type .. "'")
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
				min = tokens.Token(tokens.number, 1, tablex.copy(scopes.number))
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
				return tokens.Token(tokens.number, min.value, tablex.copy(scopes.number))
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
				min  = tokens.Token(tokens.number, 1, tablex.copy(scopes.number))
				max  = arguments[1]
				step = tokens.Token(tokens.number, 1, tablex.copy(scopes.number))
			elseif arguments[3] == nil then
				min  = arguments[1]
				max  = arguments[2]
				step = tokens.Token(tokens.number, 1, tablex.copy(scopes.number))
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
					tokens.Token(tokens.number, i, tablex.copy(scopes.number))
				)
			end

			return tokens.Token(tokens.array, range, tablex.copy(scopes.array))
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

			if arguments[1].type == tokens.array then
				return tokens.Token(tokens.string, "\"array\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.boolean then
				return tokens.Token(tokens.string, "\"bool\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.dictionary then
				return tokens.Token(tokens.string, "\"dict\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.null then
				return tokens.Token(tokens.string, "\"null\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.number then
				return tokens.Token(tokens.string, "\"num\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.string then
				return tokens.Token(tokens.string, "\"str\"", tablex.copy(scopes.string))
			elseif arguments[1].type == tokens.nativeFunction or arguments[1].type == tokens.userFunction then
				return tokens.Token(tokens.string, "\"func\"", tablex.copy(scopes.string))
			else
				return tokens.Token(tokens.string, "\"" .. arguments[1].type .. "\"", tablex.copy(scopes.string))
			end
		end),
		--FUNCTIONS

		--VARIABLES
		["true"]  = tokens.Token(tokens.boolean, true, tablex.copy(scopes.boolean)),
		["false"] = tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean)),
		null      = tokens.Token(tokens.null, "null"),
		--VARIABLES
	}
)


scopes.array = scopes.Scope(
	nil,
	nil,
	{
		__init      = {},
		contains    = {},
		find        = {},
		insert      = {},
		randelement = {},
		remove      = {},
		reverse     = {},
		sort        = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'array.__init' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local str = arguments[1]

			if arguments[1].type == tokens.string then
				str = string.sub(arguments[1].value, 2, #arguments[1].value - 1)
			else
				str = tostring(arguments[1].value)
			end

			local self = tokens.Token(tokens.array, {}, tablex.copy(scopes.array))

			for character in str.gmatch(str, ".") do
				tablex.push(
					self.value,
					tokens.Token(tokens.string, character, tablex.copy(scopes.string))
				)
			end

			return self
		end),


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
					return tokens.Token(tokens.boolean, true, tablex.copy(scopes.boolean))
				end
			end

			return tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))
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

			local indices = tokens.Token(tokens.array, {}, tablex.copy(scopes.array))

			for i, v in ipairs(arguments[1].value) do
				if v.value == arguments[2].value then
					tablex.push(
						indices.value,
						tokens.Token(tokens.number, i - 1, tablex.copy(scopes.number))
					)
				end
			end

			return indices
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
					"error while evaluating function 'array.insert' at line " .. line
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
					"error while evaluating function 'array.remove' at line " .. line
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

			local descending = tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))

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

scopes.boolean = scopes.Scope(
	nil,
	nil,
	{
		__init = {}
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'boolean.__init' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local bool

			if arguments[1].type == tokens.null then
				bool = tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))
			elseif arguments[1].type == tokens.number then
				bool = tokens.Token(tokens.boolean, arguments[1].value ~= 0, tablex.copy(scopes.boolean))
			elseif arguments[1].type == tokens.string then
				bool = tokens.Token(tokens.boolean, arguments[1].value == "\"true\"", tablex.copy(scopes.boolean))
			end

			return bool
		end)
	}
)

scopes.dictionary = scopes.Scope(
	nil,
	nil,
	{
		__init   = {},
		contains = {},
		find     = {},
		insert   = {},
		keys     = {},
		remove   = {},
		values   = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'dictionary.__init' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local dict

			if arguments[1].type == tokens.array then
				dict = tokens.Token(tokens.dictionary, {}, tablex.copy(scopes.dictionary))

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
					"error while evaluating function 'dictionary.contains' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			for _, v in ipairs(arguments[1].value) do
				if v.value.value == arguments[2].value then
					return tokens.Token(tokens.boolean, true, tablex.copy(scopes.boolean))
				end
			end

			return tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))
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

			local keys = tokens.Token(tokens.array, {}, tablex.copy(scopes.array))

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

			local keys = tokens.Token(tokens.array, {}, tablex.copy(scopes.array))

			for _, v in ipairs(arguments[1].value) do
				tablex.push(keys.value, v.key)
			end

			return keys
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

			local values = tokens.Token(tokens.array, {}, tablex.copy(scopes.array))

			for _, v in ipairs(arguments[1].value) do
				tablex.push(values.value, v.value)
			end

			return values
		end),
	}
)

scopes.number = scopes.Scope(
	nil,
	nil,
	{
		__init = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'number.__init' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
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
					),
					tablex.copy(scopes.number)
				)
			elseif arguments[1].value == "true" then
				num = tokens.Token(tokens.number, 1, tablex.copy(scopes.number))
			elseif arguments[1].value == "false" then
				num = tokens.Token(tokens.number, 0, tablex.copy(scopes.number))
			else
				num = tokens.Token(tokens.number, tonumber(arguments[1].value), tablex.copy(scopes.number))
			end

			return num
		end),
	}
)

scopes.string = scopes.Scope(
	nil,
	nil,
	{
		__init       = {},
		capitalize   = {},
		decapitalize = {},
		endswith     = {},
		lower        = {},
		upper        = {},
		startswith   = {},
	},
	{
		__init = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments ~= 1 then
				print(
					"error while evaluating function 'string.__init' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			local str

			if arguments[1].type == tokens.array or arguments[1].type == tokens.dictionary then
				str = tokens.Token(
					tokens.string,
					"\"" .. repr(arguments[1].value) .. "\"",
					tablex.copy(scopes.string)
				)
			elseif arguments[1].type == tokens.string then
				str = tablex.copy(arguments[1])
			else
				str = tokens.Token(
					tokens.string,
					"\"" .. tostring(arguments[1].value) .. "\"",
					tablex.copy(scopes.string)
				)
			end

			return str
		end),


		capitalize = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'string.capitalize' at line " .. line
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
					"error while evaluating function 'string.decapitalize' at line " .. line
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
					"error while evaluating function 'string.endswith' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type ~= tokens.string then
				print(
					"error while evaluating function 'string.endswith' at line " .. line
					.. ": expected string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			if "\"" .. string.sub(arguments[1].value, #arguments[1].value - 1, #arguments[1].value - 1) .. "\"" == arguments[2].value then
				return tokens.Token(tokens.boolean, true, tablex.copy(scopes.boolean))
			end

			return tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))
		end),


		lower = tokens.Token(tokens.nativeFunction, function (arguments, line)
			if #arguments - 1 ~= 0 then
				print(
					"error while evaluating function 'string.lower' at line " .. line
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
					"error while evaluating function 'string.upper' at line " .. line
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
					"error while evaluating function 'string.startswith' at line " .. line
					.. ": expected 1 argument, got "
					.. #arguments
					.. " instead"
				)

				os.exit()
			end

			if arguments[1].type ~= tokens.string then
				print(
					"error while evaluating function 'string.startswith' at line " .. line
					.. ": expected string while evaluating argument #1, got '"
					.. string.lower(string.sub(arguments[1].type, 1, 1)) .. string.sub(arguments[1].type, 2, #arguments[1].type)
					.. "' instead"
				)

				os.exit()
			end

			if "\"" .. string.sub(arguments[1].value, 2, 2) .. "\"" == arguments[2].value then
				return tokens.Token(tokens.boolean, true, tablex.copy(scopes.boolean))
			end

			return tokens.Token(tokens.boolean, false, tablex.copy(scopes.boolean))
		end),
	}
)


scopes.declareVariable(
	"array",
	tokens.Token(tokens.class, "array", scopes.array),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"boolean",
	tokens.Token(tokens.class, "boolean", scopes.boolean),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"dictionary",
	tokens.Token(tokens.class, "dictionary", scopes.dictionary),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"number",
	tokens.Token(tokens.class, "number", scopes.number),
	true,
	scopes.global,
	0
)

scopes.declareVariable(
	"string",
	tokens.Token(tokens.class, "string", scopes.string),
	true,
	scopes.global,
	0
)


return scopes
