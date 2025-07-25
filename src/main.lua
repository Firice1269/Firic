local interpreter = require("src.interpreter")
local parser      = require("src.parser")
local scopes      = require("src.scopes")
local tablex      = require("dependencies.tablex")


local function repl()

end


local function run(file)
	local extension = string.match(file, "^.+(%..+)$")

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


	local contents = io.input():read("a")

	local program = parser.parse(contents)
	interpreter.evaluate(program, tablex.copy(scopes.global))
end


if arg[1] == nil then
	repl()
else
	run(arg[1])
end
