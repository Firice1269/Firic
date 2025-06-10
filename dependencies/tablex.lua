local tablex = {}


function tablex.contains(self, element)
	for _, v in pairs(self) do
		if v == element then
			return true
		end
	end

	return false
end


function tablex.pop(self)
	return table.remove(self, #self)
end


function tablex.print(self)
	print(tablex.repr(self))
end


function tablex.push(self, element)
	table.insert(self, #self + 1, element)
end


function tablex.repr(self, indentation)
	indentation = indentation or 0

	local len = 2

	local text = "{\n"

	if type(self) == "table" then
		len = #self

		for i, v in pairs(self) do
			for _ = 0, indentation, 1 do
				text = text .. "  "
			end

			if type(i) == "string" then
				text = text .. "'" .. i .. "': "

				len = 2
			elseif type(i) ~= "number" then
				text = text .. tablex.repr(i, indentation + 1) .. ": "

				len = 2
			end

			if type(v) == "table" then
				text = text .. tablex.repr(v, indentation + 1)

				len = 2
			elseif type(v) == "string" then
				text = text .. "'" .. v .. "'"
			else
				text = text .. tostring(v)
			end

			text = text .. ",\n"
		end

		for _ = 1, indentation, 1 do
			text = text .. "  "
		end

		text = text .. "}"

		if string.gsub(text, " ", "") == "{\n}" then
			text = "{}"
		end
	else
		text = self
	end

	if len <= 1 then
		text = string.gsub(text, "[,(\n  )]", "")
	end

	return text
end


function tablex.shift(self)
	return table.remove(self, 1)
end


return tablex
