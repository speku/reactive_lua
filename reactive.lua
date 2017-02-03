do
  local functionless_observables = {
    branch = true,
    log = true,
    timestamp = true,
    count = true,
    throttle = true,
    print = true,
    buffer = true
  }

  local function CreateObservable()

    local next_observable
  	local branches = {}

  	return function(...)
  		local next_type, potential_next, arg3 = ...

  		if not next_observable and (type(potential_next) == "function" or functionless_observables(next_type)) then
  			local newObservable = CreateObservable()

        if next_type == "filter" then
  				next_observable = function(...)
  					if potential_next(...) then
  						return newObservable(...)
  					end
  				end
  			elseif next_type == "map" then
  				next_observable = function(...)
  					return newObservable(potential_next(...))
  				end
  			elseif next_type == "fold" then
  				local accumulator = arg3
  				next_observable = function(...)
  					accumulator = potential_next(accumulator,...)
  					return newObservable(accumulator,...)
  				end
  			elseif next_type == "subscribe" then
  				next_observable = potential_next
  			elseif next_type == "scan" then
  				local scanned_values = {}
  				local accumulator = arg3
  				next_observable = function(...)
  					accumulator = potential_next(accumulator,...)
            table.insert(scanned_values,accumulator)
  					return newObservable(accumulator,scanned_values,...)
  				end
  			elseif next_type == "branch" then
  				table.insert(branches, newObservable)
  				return newObservable
  			elseif next_type == "call" then
  				next_observable = potential_next
  			elseif next_type == "merge" then
  				potential_next("call", newObservable)
  				next_observable = newObservable
        elseif next_type == "log" then
          local logged_values = {}
          next_observable = function(...)
            table.insert(logged_values, potential_next and potential_next(...) or {...})
            return newObservable(logged_values,...)
          end
        elseif next_type == "count" then
          local count = 0
          next_observable = function(...)
            count = count + 1
            return newObservable(...)
          end
        elseif next_type == "print" then
          next_observable = function(...)
            print(potential_next and potential_next(...) or ...)
            return newObservable(...)
          end
        elseif next_type == "effect" then
          next_observable = function(...)
            potential_next(...)
            return newObservable(...)
          end
        elseif next_type == "timestamp" then
          next_observable = function(...)
            return newObservable(GetTime(),...)
          end
        elseif next_type == "throttle" and type(potential_next) == "number" then
          local delay = potential_next
          local last_time = GetTime()
          next_observable = function(...)
            local current_time = GetTime()
            if current_time - last_Time >= delay then
              last_time = currentTime
              return newObservable(...)
            end
          end
        elseif next_type == "buffer" and type(potential_next) == "number" then
          local period = potential_next
          local last_time = GetTime()
          local buffered_values = {}
          next_observable = function(...)
            local current_time = GetTime()
            if current_time - last_Time < period then
              last_time = currentTime
              table.insert(buffered_values, {...})
            else
              last_time = current_time
              local total_buffered = buffered_values
              buffered_values = {}
              return newObservable(total_buffered,...)
            end
          end
        end
  			return next_observable and next_observable
  		end

  		for _,observable in ipairs(branches) do
  			observable(...)
  		end

  		return next_observable and next_observable(...)
  	end
  end
end

do
	local observable_frame = CreateFrame("Frame")
	local observables = {}

	observable_frame:SetScript("OnEvent", function(self,event,...)
		observables[event](event,...)
	end)

	function Observe(event)
		if observables[event] then
			return observables[event]("branch")
		else
			observable_frame:RegisterEvent(event)
			observables[event] = CreateObservable()
			return observables[event]
		end
	end
end

function Filter(predicates)
  predicates = string.split


end
