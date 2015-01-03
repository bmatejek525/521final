# K-medoids implementation based on the commonly used PAM algorithm (Kaufman's original algorithm)

function pam{T<:Real}(costs::DenseMatrix{T}, k::Integer)
    # check arguments
    n = size(costs, 1)
    size(costs, 2) == n || error("costs must be a square matrix.")
    k <= n || error("Number of medoids should be less than n.")

    println(typeof(swap(costs, build(costs, k)...)))

	collect(swap(costs, build(costs, k)...))
end

# BUILD phase
# consider: throughout this process, it might actually be cleaner to store the medoids and do a lookup... 
# rather than storing the values!
function build{T<:Real}(costs::DenseMatrix{T}, k::Integer)
    n = size(costs, 1)

	medoids = Set{Int}() # CONSIDER: does a set make more sense than an array?
	non_medoid_points = Set(1:n)

	min_cost = typemax(Float64)
	first_medoid = -1
	for i = 1:n
		cost = 0
		for j = 1:n # cost of making i the medoid
			cost += costs[i,j]
		end
		if cost < min_cost
			min_cost = cost
			first_medoid = i
		end
	end

	# ADD: check that first_medoid is not -1
	push!(medoids, first_medoid)
	delete!(non_medoid_points, first_medoid)

	# initialize current cost dictionary
	dist_to_medoid = Dict{Int,Float64}()
	for i = 1:n
		dist_to_medoid[i] = costs[first_medoid,i] # at first, every object's medoid is the only chosen medoid
	end

	while (length(medoids) < k)
		min_next_medoid = -1
		max_delta = typemin(Float64)
		for i = 1:n # try all possible next medoids
			if !in(i, medoids)
				# consider making i the next medoid
				delta = 0
				for j in 1:n
					if dist_to_medoid[j] > costs[i,j] # j would be switched to i's cluster; could change this to max w/ 0
						delta += dist_to_medoid[j] - costs[i,j]
					end
				end
				if delta > max_delta
					max_delta = delta
					min_next_medoid = i
				end
			end
		end
		push!(medoids, min_next_medoid)
		for i in 1:n
			if (costs[i,min_next_medoid] < dist_to_medoid[i])
				dist_to_medoid[i] = costs[i,min_next_medoid]
			end
		end
		delete!(non_medoid_points, min_next_medoid) # if i keep this, i can adjust the check above... by examining non_medoid_points
	end
	# this should build k medoids

	# return initialization (k indices -- representing k medoids)
	medoids, non_medoid_points
end

# helper function for mapping -- TEST THIS!
function compute_medoid_map(costs, medoids::Vector{Int})
	map(i -> medoids_arr[indmin(map(j -> costs[i,j], medoids_arr))], 1:n)
end


function calculateSwapValue(costs, medoids::Set{Int}, non_medoids::Set{Int}, old_medoid, new_medoid)
	# I think moving the mapping solved the problem... try helper functions now!
	n = size(costs, 1)
	delta = 0
	for point in non_medoids
		m = collect(medoids)[indmin(map(i -> costs[i,point], collect(medoids)))]
		curr_cost = costs[point, m]
		if costs[point, new_medoid] < curr_cost # new medoid is closer to point
			delta += costs[point, new_medoid] - curr_cost
		elseif old_medoid == m # point's medoid is removed, must reassign point
			updated_medoids_arr = filter(i -> in(i, medoids) && i != m, [1:n]) # medoids - m
			second_closest_medoid = updated_medoids_arr[indmin(map(i -> costs[i,point], updated_medoids_arr))]
			delta += min(costs[point, new_medoid], costs[point, second_closest_medoid]) - curr_cost
		end
	end

	# add old_medoid's contribution
	#updated_medoids_arr = [1:n][map(i -> (in(i, medoids) && i != old_medoid) || i == new_medoid, [1:n])]
	updated_medoids_arr = filter(i -> (in(i, medoids) && i != old_medoid) || i == new_medoid, [1:n])
	# to optimize, maybe filter over medoids and append new_medoid?

	#collect(push!(delete!(medoids, old_medoid), new_medoid))
	#println(updated_medoids_arr)
	
	delta += minimum(map(i -> costs[i,old_medoid], updated_medoids_arr))
end


# SWAP phase
# consider all pairs of objects (i, h) for which object i is a medoid and h is not
# determine effect on objective function when i is no longer a medoid and h is
function swap(costs, medoids::Set{Int}, non_medoids::Set{Int})
	n = size(costs, 1)

	println("n: $(n)")

	# medoid_mapping[i] = medoid of point i
	medoid_mapping = computeMedoidMap(costs, collect(medoids))

	#println("medoids: $(medoids)")
	#println("non_medoids: $(non_medoids)")

	while true
		best_swap = -1, -1, typemax(Float64)
		for old_m in medoids
			for new_m in non_medoids
				swap_value = calculateSwapValue(costs, medoids, non_medoids, old_m, new_m)
				if swap_value < best_swap[3]
					best_swap = old_m, new_m, swap_value
				end
			end
		end

		old_m, new_m, delta = best_swap

		if delta < 0
			current_cost = calculateCost(costs, collect(Int, medoids))
			#println("best_swap: $(best_swap)")
			#println()
			println("here: $(delta), $(medoids), $(old_m), $(non_medoids), $(new_m)")
			delete!(medoids, old_m)
			#println("medoids: $(medoids)")
			#println()
			push!(non_medoids, old_m)
			delete!(non_medoids, new_m)
			push!(medoids, new_m)
			new_cost = calculateCost(costs, collect(Int, medoids))
			println("actual delta: $(new_cost - current_cost)")
		else
			println("STOP")
			break
		end

		# other sanity checks... check that calculateCost in utils function before and after each swap is equal to delta
		# ^ DO THIS!!!
		# (if it's supposedly going down at each round, I must not be calculating the swap_value correctly)

	end

	medoids
end


