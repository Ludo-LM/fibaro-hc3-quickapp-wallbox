tools = {}

-- Get view value
function tools.getView(self, name, typ)
	local function find(s)
		if type(s) == 'table' then
			if s.name == name then
				return s[typ]
			else
				for _,v in pairs(s) do
					local r = find(v)
					if r then
						return r
					end
				end
			end
		end
	end
	local id = type(self) == "userdata" and self ~= tools and self.id or type(self) == "number" and self > 0 and self
	if id then
		return find(api.get("/plugins/getView?id="..tostring(id))["$jason"].body.sections)
	end
end

-- Check global variable existence
function tools:checkVG(vg)
	if type(vg) == "string" and vg ~= "" then
		local response, status = api.get("/globalVariables/" .. vg)
		if type(status) == "number" and (status == 200 or status == 201) and type(response) == "table" then
			if not response.name or response.name ~= vg then
				return false
			end
		else
			return false
		end
		return true
	else
		return false
	end
end

-- Create global variable
function tools:createVG(varName, varValue, varEnum)
	if type(varName) == "string" and varName ~= "" then
		local payload = {name = varName, value = varValue or ""}
		local response, status = api.post("/globalVariables", payload)
		if type(status) == "number" and (status == 200 or status == 201) and type(response) == "table" then
			if type(varEnum) == "table" and #varEnum > 0 then
				local payload = {name = varName, value = varValue or "", isEnum = true, enumValues = varEnum}
				local response, status = api.put("/globalVariables/"..varName, payload)
				if type(status) == "number" and (status == 200 or status == 201) and type(response) == "table" then
					return true
				end
			else
			    return true
			end
		end
	end
	return false
end

-- Change global variable value
function tools:setVG(vg, value)
	if type(vg) == "string" and vg ~= "" then
		local oldvalue = fibaro.getGlobalVariable(vg)
		if oldvalue ~= value then
			fibaro.setGlobalVariable(vg, value)
			return true
		end
	end
	return false
end
