using ITensors
using Plots 
using Measures 
using LinearAlgebra
include("../src/evolution.jl")
include("../src/constants.jl")

# We are simulating the time evolution of a 1D spin chain with N sites, where each site is a spin-1/2 particle. 
# The simulation is done by applying a sequence of unitary gates to an initial state of the system, 
# which is a product state where each site alternates between up and down.
function main()
  N = 10 # number of sites
  cutoff = 1E-14 # specifies a truncation threshold for the SVD in MPS representation
  τ = 0.1 # time step 
  ttotal = 5.0 # total time of evolution 
  ∇x = 1E-3 # length of the box of interacting neutrinos at a site/shape function width of neutrinos in cm 
  tolerance  = 1E-5 # acceptable level of error or deviation from the exact value or solution

  # Make an array of 'site' indices and label as s 
  # conserve_qns=true conserves the total spin quantum number "S"(in z direction) in the system as it evolves
  s = siteinds("S=1/2", N; conserve_qns=false)  

  # Initialize an array of zeros for all N particles
  mu = zeros(N)
                                
  # Create an array of dimension N and fill it with the value 1/(sqrt(2) * G_F)
  n = mu.* fill((∇x)^3/(sqrt(2) * G_F), N)
      
  # Create a B vector which would be same for all N particles 
  B = [1, 0, 0]             
  
  # Create an array ω with N elements. Each element of the array is a const pi.
  ω = fill(π, N) 

  gates = create_gates(s, n, ω, B, N, ∇x, τ)
  
  # Initialize psi to be a product state (alternating up and down)
  ψ = productMPS(s, n -> isodd(n) ? "Up" : "Dn")

  #extract output from the expect.jl file where the survival probability values were computed at each timestep
  Sz_array, prob_surv_array = evolve(s, τ, n, ω, B, N, ∇x, ψ, cutoff, tolerance, ttotal)
  # Plotting P_surv vs t
  plot(0.0:τ:τ*(length(Sz_array)-1), Sz_array, xlabel = "t", ylabel = "<Sz>", legend = false, size=(700, 600), aspect_ratio=:auto,margin= 10mm) 

  # Save the plot as a PDF file
  savefig("<Sz> vs t (only vacuum oscillation term plot)_N=4.pdf")
end

@time main()

