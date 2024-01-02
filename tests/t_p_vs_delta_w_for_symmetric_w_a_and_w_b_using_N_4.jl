using ITensors
using Plots
using Measures
using DelimitedFiles

include("../src/evolution.jl")
include("../src/constants.jl")

N = 4
ttotal = 5 
function main(Δω, N, ttotal)
    cutoff = 1E-14
    τ = 0.005

    tolerance  = 5E-1
    Δx = 1E-3
    if Δω==-0.5
        a_t = 0
        b_t = 0
        c_t = 1.82
    end
    if Δω==0.0
        a_t = 0.0
        b_t = 2.105
        c_t = 0
    end
    if Δω==0.05
        a_t = 2.586
        b_t = 0
        c_t = 0
    end
    if Δω==0.125
        a_t = 1.656
        b_t = 0
        c_t = 1.42
    end
    if Δω==0.25
        a_t = 1.224
        b_t = 0
        c_t = 1.62
    end
    if Δω==0.5
        a_t = 1.064
        b_t = 0
        c_t = 1.42
    end
    if Δω==1.0
        a_t = 0.965
        b_t = 0
        c_t = 0
    end

    s = siteinds("S=1/2", N; conserve_qns=false)
    mu = ones(N)
    n = mu .* fill((Δx)^3/(sqrt(2) * G_F), N)
    B = [0, 0, -1]
    Δω_array= fill(Δω, div(N, 2))
    # Calculate ω_a and ω_b based on Δω
    ω_a = Δω_array 
    ω_b = -Δω_array 
    
    ω = vcat(ω_a, ω_b)
    ψ = productMPS(s, n -> n <= N/2 ? "Dn" : "Up")
    Sz_array, prob_surv_array = evolve(s, τ, n, ω, B, N, Δx, ψ, cutoff, ttotal)
    function find_first_local_minima_index(arr)
        n = length(arr)
        for i in 2:(n-1)
            if arr[i] < arr[i-1] && arr[i] < arr[i+1]
                return i
            end
        end
        return -1  
    end
    
    i_first_local_min = find_first_local_minima_index(prob_surv_array)
    if i_first_local_min != -1
        println("Index of the first local minimum: ", i_first_local_min)
    else 
        println("No local minimum found in the array.")
    end
    t_min = τ * i_first_local_min - τ
    println("Corresponding time of first minimum index= ", t_min)
    t_p_Rog = a_t*log(N) + b_t * sqrt(N) + c_t
    println("t_p_Rog= ",t_p_Rog)
    # Check that our time of first minimum survival probability compared to Rogerro(2021) remains within the timestep and tolerance.
    @assert abs(t_min - t_p_Rog) <  τ + tolerance 
    return t_p_Rog, t_min
end

# Arrays to store t_p_Rog and t_min for each Δω
Δω_values = [-0.5, 0.0, 0.125, 0.25, 0.5, 1.0]
t_p_Rog_array = Float64[]
t_min_array = Float64[]

datadir = joinpath(@__DIR__, "..","misc","datafiles","Rog", "par_"*string(N), "tt_"*string(ttotal))
isdir(datadir) || mkpath(datadir)
for Δω in Δω_values
    t_p_Rog, t_min = main(Δω)
    push!(t_p_Rog_array, t_p_Rog)
    push!(t_min_array, t_min)
end
fname1 = joinpath(datadir, "δω_tpRog_tpmine.dat")
writedlm(fname1, [Δω_values t_p_Rog_array t_min_array])

plotdir = joinpath(@__DIR__, "..","misc","plots","Rog", "par_"*string(N), "tt_"*string(ttotal))
    
# check if a directory exists, and if it doesn't, create it using mkpath
isdir(plotdir) || mkpath(plotdir)
# Create the plot
plot(Δω_values, t_p_Rog_array, label="Rogerro(2021)", xlabel="δω", ylabel="Minimum Time(tₚ)", title="Table I. Rogerro(2021) ", aspect_ratio=:auto,margin= 10mm)
plot!(Δω_values, t_min_array, label="Our results")
savefig(joinpath(plotdir,"tₚ_vs_δω_w/symmetric_ωa/b_for N$(N).pdf"))
