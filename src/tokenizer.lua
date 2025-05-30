local tablex = require("dependencies.tablex")
local tokens = require("src.tokens")

local tokenizer = {}


function tokenizer.tokenize(sourceCode)
	local tokenizedCode = {}

	local KEYWORDS = {
		["break"]    = {},
		["continue"] = {},
		["else"]     = {},
		["elseif"]   = {},
		["export"]   = {},
		["func"]     = {},
		["if"]       = {},
		["import"]   = {},
		["let"]      = {},
		["loop"]     = {},
		["return"]   = {},
		["var"]      = {},
	}

	local OPERATORS = {
		--ARITHMETIC
		["**"] = {},
		["//"] = {},
		["*"]  = {},
		["/"]  = {},
		["%"]  = {},
		["+"]  = {},
		["-"]  = {},
		--ARITHMETIC

		--ASSIGNMENT
		["="]   = {},
		["&="]  = {},
		["&&="] = {},
		["|="]  = {},
		["||="] = {},
		["^="]  = {},
		["<<="] = {},
		[">>="] = {},
		["**="] = {},
		["//="] = {},
		["*="]  = {},
		["/="]  = {},
		["%="]  = {},
		["+="]  = {},
		["-="]  = {},
		--ASSIGNMENT

		--BITWISE
		["&"]  = {},
		["~"]  = {},
		["|"]  = {},
		["^"]  = {},
		["<<"] = {},
		[">>"] = {},
		--BITWISE

		--COMPARISON
		["=="] = {},
		["!="] = {},
		["<"]  = {},
		["<="] = {},
		[">"]  = {},
		[">="] = {},
		--COMPARISON

		--LOGICAL
		["&&"] = {},
		["!"] = {},
		["||"] = {},
		--LOGICAL
	}

	local PUNCTUATION = {
		[" "] = {},
		["{"] = {},
		["("] = {},
		[")"] = {},
		[":"] = {},
		["["] = {},
		["]"] = {},
		[","] = {},
		["}"] = {},
	}

	local comment = false
	local escape  = false

	local tempString = ""
	local tempNumber = ""

	local quoteCount       = 0
	local fewerCount       = 0
	local greaterCount     = 0
	local ampersandCount   = 0
	local tildeCount       = 0
	local exclamationCount = 0
	local pipeCount        = 0
	local caretCount       = 0
	local asteriskCount    = 0
	local slashCount       = 0
	local percentCount     = 0
	local plusCount        = 0
	local minusCount       = 0
	local equalsCount      = 0

	if sourceCode ~= "" then
		if sourceCode[#sourceCode] ~= " " then
			sourceCode = sourceCode .. " "
		end
	end

	for character in string.gmatch(sourceCode, ".") do
		if character == "\n" then
			if quoteCount == 1 then
				print("ERROR: Unfinished string literal: " .. tempString)
				os.exit()
			end

			if tempString ~= "" then --push finished words
				if KEYWORDS[tempString] ~= nil then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.keyword, tempString)
					)
				else
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.identifier, tempString)
					)
				end

				tempString = ""
			end

			if tempNumber ~= "" then --push finished numbers
				if string.find(tempNumber, ".", 1, true) ~= nil then
					if string.sub(tempNumber, 1, 1) == "." then
						if tempNumber == "." then
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.miscellaneousOperator, ".")
							)
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.float, tonumber("0" .. tempNumber))
							)
						end
					else
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.float, tonumber(tempNumber))
						)
					end
				else
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.int, tonumber(tempNumber))
					)
				end

				tempNumber = ""
			end

			tablex.push(
				tokenizedCode,
				tokens.Token(tokens.eol, "newline")
			)

			tempString = ""
			tempNumber = ""

			quoteCount       = 0
			greaterCount     = 0
			fewerCount       = 0
			exclamationCount = 0
			asteriskCount    = 0
			slashCount       = 0
			percentCount     = 0
			plusCount        = 0
			minusCount       = 0
			equalsCount      = 0

			comment = false
			escape  = false
		elseif not comment then
			if quoteCount == 1 then
				if escape then
					if character == "\\" or character == "\"" then
						tempString = tempString .. character
					elseif character == "n" then
						tempString = tempString .. "\n"
					else
						print("ERROR: Invalid escape sequence: \\" .. character)
						os.exit()
					end

					escape = false
				elseif character == "\\" then
					escape = true
				else
					tempString = tempString .. character

					if character == "\"" then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.str, tempString)
						)

						tempString = ""
						quoteCount = 0
					end
				end
			elseif character == "\"" then
				if tempString ~= "" then --push finished words
					if KEYWORDS[tempString] ~= nil then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.keyword, tempString)
						)
					else
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.identifier, tempString)
						)
					end

					tempString = ""
				end

				tempString = tempString .. character

				quoteCount = quoteCount + 1
			elseif OPERATORS[character] == nil and PUNCTUATION[character] == nil then
				if
					string.find(character, "[%a_]", 1, false) ~= nil or (
						string.find(character, "[%w_]", 1, false) ~= nil
						and tempString ~= ""
					)
				then --tokenize words
					tempString = tempString .. character
				elseif string.find(character, "[%d%.]", 1, false) ~= nil then --tokenize numbers
					tempNumber = tempNumber .. character
				end
			else
				if tempString ~= "" then --push finished words
					if KEYWORDS[tempString] ~= nil then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.keyword, tempString)
						)
					else
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.identifier, tempString)
						)
					end

					tempString = ""
				end

				if tempNumber ~= "" then --push finished numbers
					if string.find(tempNumber, ".", 1, true) ~= nil then
						if string.sub(tempNumber, 1, 1) == "." then
							if tempNumber == "." then
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.miscellaneousOperator, ".")
								)
							else
								tablex.push(
									tokenizedCode,
									tokens.Token(tokens.float, tonumber("0" .. tempNumber))
								)
							end
						else
							tablex.push(
								tokenizedCode,
								tokens.Token(tokens.float, tonumber(tempNumber))
							)
						end
					else
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.int, tonumber(tempNumber))
						)
					end

					tempNumber = ""
				end

				--tokenize operators
				if character == ">" then
					greaterCount = greaterCount + 1
				elseif character == "<" then
					fewerCount = fewerCount + 1
				elseif character == "&" then
					ampersandCount = ampersandCount + 1
				elseif character == "~" then
					tildeCount = tildeCount + 1
				elseif character == "!" then
					exclamationCount = exclamationCount + 1
				elseif character == "|" then
					pipeCount = pipeCount + 1
				elseif character == "^" then
					caretCount = caretCount + 1
				elseif character == "*" then
					asteriskCount = asteriskCount + 1
				elseif character == "/" then
					slashCount = slashCount + 1
				elseif character == "%" then
					percentCount = percentCount + 1
				elseif character == "+" then
					plusCount = plusCount + 1
				elseif character == "-" then
					if minusCount == 1 then
						comment = true
					else
						minusCount = minusCount + 1
					end
				elseif character == "=" then
					if fewerCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.comparisonOperator, "<=")
						)

						fewerCount = 0
					elseif fewerCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "<<=")
						)

						fewerCount = 0
					elseif greaterCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.comparisonOperator, ">=")
						)

						greaterCount = 0
					elseif greaterCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, ">>=")
						)

						greaterCount = 0
					elseif ampersandCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "&=")
						)

						ampersandCount = 0
					elseif ampersandCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "&&=")
						)

						ampersandCount = 0
					elseif caretCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "^=")
						)

						caretCount = 0
					elseif exclamationCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.comparisonOperator, "!=")
						)

						exclamationCount = 0
					elseif pipeCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "|=")
						)

						pipeCount = 0
					elseif pipeCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "||=")
						)

						pipeCount = 0
					elseif asteriskCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "*=")
						)

						asteriskCount = 0
					elseif asteriskCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "**=")
						)

						asteriskCount = 0
					elseif slashCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "/=")
						)

						slashCount = 0
					elseif slashCount == 2 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "//=")
						)

						slashCount = 0
					elseif percentCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "%=")
						)

						percentCount = 0
					elseif plusCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "+=")
						)

						plusCount = 0
					elseif minusCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.assignmentOperator, "-=")
						)

						minusCount = 0
					elseif equalsCount == 1 then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.comparisonOperator, "==")
						)

						equalsCount = 0
					else
						equalsCount = equalsCount + 1
					end
				end
			end

			if OPERATORS[character] == nil and quoteCount == 0 then --push finished operators
				if fewerCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.comparisonOperator, "<")
					)

					fewerCount = 0
				elseif fewerCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, "<<")
					)

					fewerCount = 0
				elseif greaterCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.comparisonOperator, ">")
					)

					greaterCount = 0
				elseif greaterCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, ">>")
					)

					greaterCount = 0
				elseif ampersandCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, "&")
					)

					ampersandCount = 0
				elseif ampersandCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.logicalOperator, "&&")
					)

					ampersandCount = 0
				elseif tildeCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, "~")
					)

					tildeCount = 0
				elseif exclamationCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.logicalOperator, "!")
					)

					exclamationCount = 0
				elseif pipeCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, "|")
					)

					pipeCount = 0
				elseif pipeCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.logicalOperator, "||")
					)

					pipeCount = 0
				elseif caretCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.bitwiseOperator, "^")
					)

					caretCount = 0
				elseif asteriskCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "*")
					)

					asteriskCount = 0
				elseif asteriskCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "**")
					)

					asteriskCount = 0
				elseif slashCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "/")
					)

					slashCount = 0
				elseif slashCount == 2 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "//")
					)

					slashCount = 0
				elseif percentCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "%")
					)

					percentCount = 0
				elseif plusCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "+")
					)

					plusCount = 0
				elseif minusCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.arithmeticOperator, "-")
					)

					minusCount = 0
				elseif equalsCount == 1 then
					tablex.push(
						tokenizedCode,
						tokens.Token(tokens.assignmentOperator, "=")
					)

					equalsCount = 0
				end

				if PUNCTUATION[character] ~= nil then --push punctuation
					if character ~= " " then
						tablex.push(
							tokenizedCode,
							tokens.Token(tokens.punctuation, character)
						)
					end
				end
			end
		end
	end

	tablex.push(
		tokenizedCode,
		tokens.Token(tokens.eol, "newline")
	)

	tablex.push(
		tokenizedCode,
		tokens.Token(tokens.eof, "EOF")
	)

	return tokenizedCode
end


return tokenizer
