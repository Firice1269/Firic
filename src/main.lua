local interpreter = require("src.interpreter")
local parser      = require("src.parser")
local scopes      = require("src.scopes")
local tablex      = require("dependencies.tablex")


local function repl()
	print("Firic 1.3.3")

	local scope = tablex.copy(scopes.global)

	while true do
		io.stdout:write("> ")
		local program = io.stdin:read("L")

		if program == "exit\n" then
			os.exit()
		end

		local bracketCount = 0
		local str          = false

		for character in string.gmatch(program, ".") do
			if str then
				if character == "\"" then
					str = false
				end
			else
				if character == "\"" then
					str = true
				elseif character == "(" or character == "[" or character == "{" then
					bracketCount = bracketCount + 1
				elseif character == ")" or character == "]" or character == "}" then
					bracketCount = bracketCount - 1
				end
			end
		end

		while bracketCount > 0 do
			local prompt = ""

			for _ = 1, bracketCount, 1 do
				prompt = prompt .. "..."
			end

			io.stdout:write(prompt .. " ")

			local input = io.stdin:read("L")

			if input == "exit\n" then
				os.exit()
			end

			for character in string.gmatch(input, ".") do
				if str then
					if character == "\"" then
						str = false
					end
				else
					if character == "\"" then
						str = true
					elseif character == "(" or character == "[" or character == "{" then
						bracketCount = bracketCount + 1
					elseif character == ")" or character == "]" or character == "}" then
						bracketCount = bracketCount - 1
					end
				end
			end

			local indentation = ""

			for _ = 1, bracketCount, 1 do
				indentation = indentation .. "..."
			end

			if indentation ~= "" then
				indentation = indentation .. " "
			end

			io.stdout:write(indentation .. input)

			program = program .. input
		end

		local value

		for _, statement in ipairs(parser.parse(program, "N/A").value.body) do
			value = interpreter.evaluate(statement, scope, "N/A")
		end

		if value.value ~= "null" then
			scopes.global.variables.print.value({value}, 0)
		end
	end
end

local function run(file)
	local _, name, extension = string.match(file, "^(.-)([^\\/]-)(%.[^\\/%.]-)%.?$")

	if extension ~= ".fi" then
		print("error: expected '.fi' file extension, got '" .. extension .. "' instead")
		os.exit()
	end


	if
		not pcall(function ()
			io.input(file)
		end)
	then
		print("error: cannot find file at " .. file)
		os.exit()
	end


	interpreter.evaluate(
		parser.parse(
			io.input():read("a"),
			name .. extension
		),
		scopes.global,
		name .. extension
	)
end


if arg[1] == nil then
	repl()
else
	run(arg[1])
end
