local function CreateObservable()
    local next_observable
	local branches = {}
	return function(...)
		local next_type, potential_next, arg3 = ...
		if not next_observable and type(potential_next) == "function" then
			local newObservable = CreateObservable()
			if next_type == "filter" then 
				next_observable = function(...)
					if potential_next(...) then 
						return newObservable(...)
					end
				end
			else if next_type == "map" then
				next_observable = function(...)
					return newObservable(potential_next(...))
				end
			else if next_type == "fold" then
				local accumulator = arg3
				next_observable = function(...)
					accumulator = potential_next(...,accumulator)
					return newObservable(accumulator)
				end
			else if next_type == "subscribe" then
				next_observable = newObservable
				end
			else if next_type == "scan" then 
				local scanned_values = {}
				local accumulator = arg3
				next_observable = function(...)
					accumulator = potential_next(...,accumulator)
					return newObservable(scanned_values)
				end
			else if next_type == "branch" then 
				table.insert(branches, newObservable)
				return newObservable
			else if next_type == "call" then 
				next_observable = potential_next
			else if next_type == "merge" then
				potential_next("call", newObservable)
				next_observable = newObservable
			end
			
			return next_observable and next_observable
				
		end
		
		for _,observable in ipairs(branches) do
			observable(...)
		end
		
		return next_observable and next_observable(...)
	end
end

do
	local observable_frame = CreateFrame("Frame")
	local observables = {}
	
	observable_frame:SetScript("OnEvent", function(self,event,...)
		observables[event](event,...)
	end
	
	function Observable(event)
		if observables[event] then 
			return false
		else
			observable_frame:RegisterEvent(event)
			
			observables[event] = CreateObservable()
			return observables[event]
		end
	end
end






