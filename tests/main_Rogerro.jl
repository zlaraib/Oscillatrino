using ITensors
using Plots
using Measures
using ITensorTDVP
using DelimitedFiles
# using TimeEvoMPS
include("../src/evolution.jl")
include("../src/constants.jl")

# We are simulating the time evolution of a 1D spin chain with N_sites sites, where each site is a spin-1/2 particle. 
# The simulation is done by applying a sequence of unitary gates to an initial state of the system, 
# which is a product state where each site alternates between up and down.

function main()
    N_sites = 4 # number of sites (NEED TO GO TILL 96 for Rog_results)
    cutoff = 1E-14 # specifies a truncation threshold for the SVD in MPS representation (SMALL CUTOFF = MORE ENTANGLEMENT)
    τ = 0.05 # time step (NEED TO BE 0.05 for Rog_results)
    ttotal = 5 # total time of evolution (NEED TO GO TILL 50 for Rog_results)
    tolerance  = 5E-1 # acceptable level of error or deviation from the exact value or solution
    Δx = 1E-3 # length of the box of interacting neutrinos at a site/shape function width of neutrinos in cm 
    maxdim = 1000 #bond dimension

    # s is an array of spin 1/2 tensor indices (Index objects) which will be the site or physical indices of the MPS.
    # We overload siteinds function, which generates custom Index array with Index objects having the tag of total spin quantum number for all N_sites.
    # conserve_qns=false doesnt conserve the total spin quantum number "S" in the system as it evolves
    s = siteinds("S=1/2", N_sites; conserve_qns=false)  

    # Constants for Rogerro's fit (only self-interaction term)
    a_t = 1.224
    b_t = 0
    c_t = 1.62
    
    # Initialize an array of ones for all N_sites sites
    mu = ones(N_sites) # erg
    
    # Create an array of dimension N_sites and fill it with the value 1/(sqrt(2) * G_F). This is the number of neutrinos. 
    N = mu .* fill((Δx)^3/(sqrt(2) * G_F), N_sites)
    
    # Create a B vector which would be same for all N_sites particles 
    B = [0, 0, -1]

    # Create arrays ω_a and ω_b
    ω_a = fill(0.5, div(N_sites, 2))
    ω_b = fill(0, div(N_sites, 2))

    # Defining Δω as in Rogerro(2021)
    Δω = (ω_a - ω_b)/2
    
    # Concatenate ω_a and ω_b to form ω
    ω = vcat(ω_a, ω_b)

    ψ = productMPS(s, N -> N <= N_sites/2 ? "Dn" : "Up")
    energy_sign = [i <= N_sites ÷ 2 ? 1 : 1 for i in 1:N_sites]

    # Specify the relative directory path
    datadir = joinpath(@__DIR__, "..","misc","datafiles","Rog", "par_"*string(N_sites), "tt_"*string(ttotal))
    #extract output from the expect.jl file where the survival probability values were computed at each timestep
    Sz_array, prob_surv_array = evolve(s, τ, N, ω, B, N_sites, Δx, ψ, energy_sign, cutoff, maxdim, datadir,ttotal)

    # This function scans through the array, compares each element with its neighbors, 
    # and returns the index of the first local minimum it encounters. 
    # If no local minimum is found, it returns -1 to indicate that.
    function find_first_local_minima_index(arr)
        N = length(arr)
        for i in 2:(N-1)
            if arr[i] < arr[i-1] && arr[i] < arr[i+1]
                return i
            end
        end
        return -1  
    end
    
    # Index of first minimum of the prob_surv_array (containing survival probability values at each time step)
    i_first_local_min = find_first_local_minima_index(prob_surv_array)
    
    # Writing if_else statement to communicate if local minima (not) found
    if i_first_local_min != -1
        println("Index of the first local minimum: ", i_first_local_min)
    else
        println("No local minimum found in the array.")
    end

    # Time at which the first mimimum survival probability is reached
    t_min = τ * i_first_local_min - τ
    println("Corresponding time of first minimum index= ", t_min)

    # Rogerro(2021)'s fit for the first minimum of the survival probability reached for a time t_p 
    t_p_Rog = a_t*log(N_sites) + b_t * sqrt(N_sites) + c_t
    println("t_p_Rog= ",t_p_Rog)

    # Check that our time of first minimum survival probability compared to Rogerro(2021) remains within the timestep and tolerance.
    @assert abs(t_min - t_p_Rog) <  τ + tolerance 

    # Specify the relative directory path
    plotdir = joinpath(@__DIR__, "..","misc","plots","Rog", "par_"*string(N_sites), "tt_"*string(ttotal))

    # check if a directory exists, and if it doesn't, create it using mkpath
    isdir(plotdir) || mkpath(plotdir)

    # Plotting P_surv vs t
    plot(0.0:τ:τ*(length(prob_surv_array)-1), prob_surv_array, xlabel = "t", ylabel = "Survival Probabillity p(t)",title = "Running main_Rogerro script \n for N_sites$(N_sites) with maxdim=1 MF for τ$(τ)", legend = false, size=(700, 600), aspect_ratio=:auto,margin= 10mm, label= ["My_plot_for_N$(N_sites)"]) 
    scatter!([t_p_Rog],[prob_surv_array[i_first_local_min]], label= ["t_p_Rog"])
    scatter!([t_min],[prob_surv_array[i_first_local_min]], label= ["My_t_min)"], legendfontsize=5, legend=:bottomleft)
    # Save the plot as a PDF file
    savefig(joinpath(plotdir,"Survival probability vs t (Rog)for N_sites$(N_sites) with maxdim=1 and cutoff for τ$(τ).pdf"))
end 

@time main()

