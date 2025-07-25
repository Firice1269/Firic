local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local tokenizer = {}


function tokenizer.tokenize(sourceCode)
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
		import     = {},
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

	for i, v in ipairs(lines) do
		local comment = false

		while #v ~= 0 do
			if comment then
				tablex.shift(v)
			else
				if v[1] == " " or v[1] == "\t" then
					tablex.shift(v)
				elseif
					v[1] == "{"
					or v[1] == "}"
					or v[1] == "["
					or v[1] == "]"
					or v[1] == "("
					or v[1] == ")"
					or v[1] == ","
					or v[1] == ";"
				then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.punctuation, tablex.shift(v))
					)
				elseif v[1] == "?" or v[1] == ":" then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.miscellaneousOperator, tablex.shift(v))
					)
				else
					if string.find(v[1], "[%a_]") ~= nil then
						local str = ""

						while #v > 0 and str.find(v[1], "[%w_]") ~= nil do
							str = str .. tablex.shift(v)
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
					elseif string.find(v[1], "[%d%.]") ~= nil then
						local num = ""

						while #v > 0 and string.find(v[1], "[%d%.]") ~= nil do
							if v[1] == "." and string.find(num, "%.") ~= nil then
								if num == "." then
									tablex.push(
										tokenizedCode,
										tokens.Token(tokens.miscellaneousOperator, num)
									)
								else
									tablex.push(
										tokenizedCode,
										tokens.Token(tokens.float, tonumber(num))
									)
								end

								num = ""
								break
							else
								num = num .. tablex.shift(v)
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
								tokens.Token(tokens.int, tonumber(num))
							)
						end
					elseif v[1] == "\"" then
						local str = tablex.shift(v)

						local escape = false

						while #v > 0 do
							if escape then
								if v[1] == "\\" or v[1] == "\"" or v[1] == "n" then
									str = str .. tablex.shift(v)

									escape = false
								else
									print("error while tokenizing string on line " .. i .. ": invalid escape sequence: " .. "\\" .. v[1])
									os.exit()
								end
							elseif v[1] == "\\" then
								str = str .. tablex.shift(v)

								escape = true
							elseif v[1] == "\"" then
								str = str .. tablex.shift(v)

								break
							else
								str = str .. tablex.shift(v)
							end
						end

						if string.sub(str, #str, #str) ~= "\"" then
							print("error while tokenizing line " .. i .. ": unfinished string literal")
							os.exit()
						end

						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.str, str)
						)
					elseif v[1] == "&" then
						local operator = tablex.shift(v)

						if v[1] == "&" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "|" then
						local operator = tablex.shift(v)

						if v[1] == "|" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "^" then
						local operator = tablex.shift(v)

						if v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "<" then
						local operator = tablex.shift(v)

						if v[1] == "<" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == ">" then
						local operator = tablex.shift(v)

						if v[1] == ">" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "=" then
						local operator = tablex.shift(v)

						if v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "!" then
						local operator = tablex.shift(v)

						if v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "+" then
						local operator = tablex.shift(v)

						if v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "-" then
						local operator = tablex.shift(v)

						if v[1] == "-" then
							comment = true
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "*" then
						local operator = tablex.shift(v)

						if v[1] == "*" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "/" then
						local operator = tablex.shift(v)

						if v[1] == "/" then
							operator = operator .. tablex.shift(v)

							if v[1] == "=" then
								operator = operator .. tablex.shift(v)

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
						elseif v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "%" then
						local operator = tablex.shift(v)

						if v[1] == "=" then
							operator = operator .. tablex.shift(v)

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
					elseif v[1] == "~" then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.bitwiseOperator, tablex.shift(v))
						)
					else
						print("error while tokenizing line " .. i .. ": unexpected character: " .. v[1])
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
