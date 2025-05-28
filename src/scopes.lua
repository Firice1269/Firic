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

	if structure.type == tokens.Array then
		text = "[\n"
	elseif structure.type == tokens.Dictionary then
		text = "{\n"
	end

	for _, v in ipairs(structure.value) do
		if structure.type == tokens.Dictionary then
			text = text .. v.key .. ": "
			v = v.value
		end

		for _ = 0, indentation, 1 do
			text = text .. "  "
		end

		if v.type == tokens.Array or v.type == tokens.Dictionary then
			text = text .. repr(v.value, indentation + 1)
		else
			text = text .. v.value
		end

		text = text .. ",\n"
	end

	for _ = 1, indentation, 1 do
		text = text .. "  "
	end

	if structure.type == tokens.Array then
		text = text .. "]"
	elseif structure.type == tokens.Dictionary then
		text = text .. "}"
	end

	if string.gsub(text, " ", "") == "[\n]" or string.gsub(text, " ", "") == "{\n}" then
		text = string.gsub(text, "\n", "")
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
		["print"] = {},
		["type"]  = {},
		--FUNCTIONS

		--VARIABLES
		["true"]  = {},
		["false"] = {},
		["null"]  = {},
		--VARIABLES
	},
	{
		--FUNCTIONS
		["len"] = tokens.Token(tokens.NativeFunction, function(arguments)
			if #arguments ~= 1 then
				print("ERROR: Unexpected number of arguments inside function call (expected 1): " .. #arguments)
				os.exit()
			end

			if arguments[1].type == tokens.Array then
				return tokens.Token(tokens.Number, #arguments[1].value)
			elseif arguments[1].type == tokens.String then
				return tokens.Token(
					tokens.Number,
					string.len(
						string.sub(
							arguments[1].value,
							2,
							#arguments[1].value - 1
						)
					)
				)
			else
				print("ERROR: Unexpected type of argument inside function call (expected array or string): " .. arguments[1].type)
				os.exit()
			end
		end),


		["print"] = tokens.Token(tokens.NativeFunction, function(arguments)
			if #arguments == 0 then
				print()
			else
				for _, v in ipairs(arguments) do
					if v.type == tokens.String then
						print(string.sub(v.value, 2, #v.value - 1))
					elseif v.type == tokens.NativeFunction or v.type == tokens.UserFunction then
						print("function " .. v.value.name)
					elseif v.type == tokens.Array or v.type == tokens.Dictionary then
						print(repr(v))
					else
						print(v.value)
					end
				end
			end
		end),


		["randint"] = tokens.Token(tokens.NativeFunction, function(arguments)
			if #arguments ~= 2 then
				print("ERROR: Unexpected number of arguments inside function call (expected 0): " .. #arguments)
				os.exit()
			end

			if arguments[1].type ~= tokens.Number then
				print("ERROR: Unexpected type of argument inside function call (expected number): " .. arguments[1].type)
				os.exit()
			end

			if arguments[2].type ~= tokens.Number then
				print("ERROR: Unexpected type of argument inside function call (expected number): " .. arguments[2].type)
				os.exit()
			end

			return tokens.Token(
				tokens.Number,
				math.random(round(arguments[1].value), round(arguments[2].value))
			)
		end),


		["type"] = tokens.Token(tokens.NativeFunction, function(arguments)
			if #arguments ~= 1 then
				print("ERROR: Unexpected number of arguments inside function call (expected 1): " .. #arguments)
				os.exit()
			end

			if arguments[1].type == tokens.Boolean then
				return tokens.Token(tokens.String, "\"bool\"")
			elseif arguments[1].type == tokens.Null then
				return tokens.Token(tokens.String, "\"null\"")
			elseif arguments[1].type == tokens.Number then
				return tokens.Token(tokens.String, "\"num\"")
			elseif arguments[1].type == tokens.String then
				return tokens.Token(tokens.String, "\"str\"")
			elseif arguments[1].type == tokens.NativeFunction or arguments[1].type == tokens.UserFunction then
				return tokens.Token(tokens.String, "\"function\"")
			end
		end),
		--FUNCTIONS

		--VARIABLES
		["true"]  = tokens.Token(tokens.Boolean, true),
		["false"] = tokens.Token(tokens.Boolean, false),
		["null"]  = tokens.Token(tokens.Null, "null"),
		--VARIABLES
	}
)


return scopes
