using ITensors
using Plots
using Measures
#include("src/gates_function.jl")
include("src/expect.jl")

# We are simulating the time evolution of a 1D spin chain with N sites, where each site is a spin-1/2 particle. 
# The simulation is done by applying a sequence of unitary gates to an initial state of the system, 
# which is a product state where each site alternates between up and down.

function main()
    N = 5 # number of sites (NEED TO GO TILL 96 for Rog_results)
    cutoff = 1E-14 # specifies a truncation threshold for the SVD in MPS representation (SMALL CUTOFF = MORE ENTANGLEMENT)
    tau = 0.05 # time step (NEED TO BE 0.05 for Rog_results)
    ttotal = 10 # total time of evolution (NEED TO GO TILL 50 for Rog_results)
    tolerance  = 5E-1 # acceptable level of error or deviation from an exact value or solution


    # s is an array of spin 1/2 tensor indices (Index objects) which will be the site or physical indices of the MPS.
    # conserve_qns=true conserves the total spin quantum number "S" in the system as it evolves
    s = siteinds("S=1/2", N; conserve_qns=true)  

    # Constants for Rogerro's fit (only interaction term)
    a_t = 0
    b_t = 2.10
    c_t = 0
    
    # # Specify the directory path
    # #directory_path = "/home/zohalaraib/Test_rep/tests/Rog_tests"
    # directory_path = joinpath(@__DIR__)

    # # Create the file path within the specified directory
    # datafile_path = joinpath(directory_path, "datafiles", string(N) * "(par)_" * string(ttotal) * "(ttotal)final.txt")
    
    # # Open the file for writing
    # datafile = open(datafile_path, "w")
    
    #extract output from the expect.jl file where the survival probability values were computed at each timestep
    Sz_array, prob_surv_array = calc_expect(s, tau, N, cutoff, ttotal)

    # close(datafile)  # Close the file

    #index of minimum of the prob_surv_array (containing survival probability values at each time step)
    i_min = argmin(prob_surv_array)
    # time at which the mimimum survival probability is reached
    t_min = tau * i_min - tau
    # Rogerro(2021) defines his fit for the first minimum of the survival probability reached for a time t_p 
    t_p_Rog = a_t*log(N) + b_t * sqrt(N) + c_t
    println("t_p_Rog= ",t_p_Rog)
    println("i_min =", i_min)
    println("t_min= ", t_min)
    # Check that our time of minimum survival probability compared to Rogerro(2021) remains within the timestep and tolerance.
    @assert abs(t_min - t_p_Rog) <  tau + tolerance 

    # # Plotting P_surv vs t
    # plot(0.0:tau:tau*(length(prob_surv_array)-1), prob_surv_array, xlabel = "t", ylabel = "prob_surv", legend = false, size=(800, 600), aspect_ratio=:auto,margin= 10mm) 


    # # Save the plot in the same directory
    # plot_path = joinpath(directory_path, "plots", string(N) * "(par)_" * string(ttotal) * "(ttotal)final.pdf")

    # savefig(plot_path)
end 

@time main()
