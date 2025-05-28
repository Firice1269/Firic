local interpreter = require("src.interpreter")
local parser      = require("src.parser")
local scopes      = require("src.scopes")


local function run(file)
	local extension = string.match(file, "^.+(%..+)$")

	if extension ~= ".fi" then
		print("ERROR: Unexpected file extension (expected .fi): " .. extension)
		os.exit()
	end

	io.input(file)
	local contents = io.input():read("a")

	local program = parser.parse(contents)
	interpreter.evaluate(program, scopes.globalScope)
end


if type(arg[1]) == "string" then
	run(arg[1])
else
	os.exit()
end
