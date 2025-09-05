local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local tokenizer = {}


function tokenizer.tokenize(sourceCode, input)
	local KEYWORDS = {
		["break"]  = {},
		case       = {},
		continue   = {},
		default    = {},
		["else"]   = {},
		["elseif"] = {},
		export     = {},
		["for"]    = {},
		func       = {},
		["if"]     = {},
		["in"]     = {},
		let        = {},
		["return"] = {},
		switch     = {},
		var        = {},
		["while"]  = {},
	}

	local lines = {}
	local line  = {}

	for character in string.gmatch(sourceCode, ".") do
		if type(sourceCode) ~= "table" then
			sourceCode = {}
		end

		if character == "\n" then
			tablex.push(lines, line)

			line = {}
		else
			tablex.push(line, character)
		end
	end

	if #line ~= 0 then
		tablex.push(lines, line)
	end

	local tokenizedCode = {}

	for i, line in ipairs(lines) do
		local comment = false

		while #line ~= 0 do
			if comment then
				tablex.shift(line)
			else
				if line[1] == " " or line[1] == "\t" then
					tablex.shift(line)
				elseif
					line[1] == "{"
					or line[1] == "}"
					or line[1] == "["
					or line[1] == "]"
					or line[1] == "("
					or line[1] == ")"
					or line[1] == ","
					or line[1] == ";"
				then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.punctuation, tablex.shift(line))
					)
				elseif line[1] == "?" or line[1] == ":" then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.miscellaneousOperator, tablex.shift(line))
					)
				else
					if string.find(line[1], "[%a_]") ~= nil then
						local str = ""

						while #line > 0 and str.find(line[1], "[%w_]") ~= nil do
							str = str .. tablex.shift(line)
						end

						if KEYWORDS[str] ~= nil then
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.keyword, str)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.identifier, str)
							)
						end
					elseif string.find(line[1], "[%d%.]") ~= nil then
						local num = ""

						while #line > 0 and string.find(line[1], "[%d%.]") ~= nil do
							if line[1] == "." and string.find(num, "%.") ~= nil then
								if num == "." then
									tablex.push(
										tokenizedCode,
										tokens.Token(tokens.miscellaneousOperator, num)
									)
								else
									tablex.push(
										tokenizedCode,
										tokens.Token(tokens.num, tonumber(num))
									)
								end

								num = ""
								break
							else
								num = num .. tablex.shift(line)
							end
						end

						if num == "." then
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.miscellaneousOperator, num)
							)
						elseif num ~= "" then
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.num, tonumber(num))
							)
						end
					elseif line[1] == "\"" then
						local str = tablex.shift(line)

						local escape = false

						while #line > 0 do
							if escape then
								if line[1] == "\\" or line[1] == "\"" or line[1] == "n" then
									str = str .. tablex.shift(line)

									escape = false
								end
							elseif line[1] == "\\" then
								str = str .. tablex.shift(line)

								escape = true
							elseif line[1] == "\"" then
								str = str .. tablex.shift(line)

								break
							else
								str = str .. tablex.shift(line)
							end
						end

						if string.sub(str, #str, #str) ~= "\"" then
							print(
								"error while tokenizing string"
								.. " in " .. input .. " at line " .. i .. ": "
								.. "unfinished string literal '" .. string.sub(str, 2, #str) .. "'"
							)

							os.exit()
						end

						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.str, str)
						)
					elseif line[1] == "&" then
						local operator = tablex.shift(line)

						if line[1] == "&" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.logicalOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.bitwiseOperator, operator)
							)
						end
					elseif line[1] == "|" then
						local operator = tablex.shift(line)

						if line[1] == "|" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.logicalOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.bitwiseOperator, operator)
							)
						end
					elseif line[1] == "^" then
						local operator = tablex.shift(line)

						if line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.bitwiseOperator, operator)
							)
						end
					elseif line[1] == "<" then
						local operator = tablex.shift(line)

						if line[1] == "<" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.bitwiseOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						end
					elseif line[1] == ">" then
						local operator = tablex.shift(line)

						if line[1] == ">" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.bitwiseOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						end
					elseif line[1] == "=" then
						local operator = tablex.shift(line)

						if line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						end
					elseif line[1] == "!" then
						local operator = tablex.shift(line)

						if line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.comparisonOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.logicalOperator, operator)
							)
						end
					elseif line[1] == "+" then
						local operator = tablex.shift(line)

						if line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.arithmeticOperator, operator)
							)
						end
					elseif line[1] == "-" then
						local operator = tablex.shift(line)

						if line[1] == "-" then
							comment = true
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.arithmeticOperator, operator)
							)
						end
					elseif line[1] == "*" then
						local operator = tablex.shift(line)

						if line[1] == "*" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.arithmeticOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.arithmeticOperator, operator)
							)
						end
					elseif line[1] == "/" then
						local operator = tablex.shift(line)

						if line[1] == "/" then
							operator = operator .. tablex.shift(line)

							if line[1] == "=" then
								operator = operator .. tablex.shift(line)

								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.assignmentOperator, operator)
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.arithmeticOperator, operator)
								)
							end
						elseif line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.arithmeticOperator, operator)
							)
						end
					elseif line[1] == "%" then
						local operator = tablex.shift(line)

						if line[1] == "=" then
							operator = operator .. tablex.shift(line)

							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.assignmentOperator, operator)
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.arithmeticOperator, operator)
							)
						end
					elseif line[1] == "~" then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.bitwiseOperator, tablex.shift(line))
						)
					else
						print(
							"error while tokenizing string"
							.. " in " .. input .. " at line " .. i .. ": "
							.. "unexpected character '" .. line[1] .. "'"
						)

						os.exit()
					end
				end
			end
		end

		tablex.push(
			tokenizedCode,
			tokens.Token(tokens.eol, "\\n")
		)
	end

	tablex.push(
		tokenizedCode,
		tokens.Token(tokens.eof, "EOF")
	)

	return tokenizedCode
end


return tokenizer
