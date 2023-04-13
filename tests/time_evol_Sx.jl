using ITensors
# We are simulating the time evolution of a 1D spin chain with N sites, where each site is a spin-1/2 particle. 
# The simulation is done by applying a sequence of unitary gates to an initial state of the system, 
# which is a product state where each site alternates between up and down.
let
  N = 100 # number of sites
  cutoff = 1E-8 # specifies a truncation threshold for the SVD in MPS representation
  tau = 0.1 # time step 
  ttotal = 5.0 # total time of evolution 

  # Make an array of 'site' indices
  s = siteinds("S=1/2", N; conserve_qns= false) # conserve_qns=true specifies the quantum numbers (total spin in sys = quantum number "S") that are conserved by the system (as sys evolves)


  # Make gates (1,2),(2,3),(3,4),... i.e. unitary gates which act on neighboring pairs of sites in the chain
  gates = ITensor[] # empty array that will hold ITensors that will be our Trotter gates
  #gates is an array of ITensors, each representing a time evolution operator for a pair of neighboring sites in this quantum system.
  for j in 1:(N - 1)
    s1 = s[j]
    s2 = s[j + 1]
    #hj = 0.25 *((op("S-",s1)*op("S-",s2)) + (op("S-",s1)*op("S+",s2)) + (op("S+",s1)*op("S-",s2)) + (op("S+",s1)*op("S+",s2)))
     hj =  pi  * 0.5 *((
     (op("S+", s1)* op("Id", s2))  + (op("S-", s1))* op("Id", s2))  + (op("S+", s2) *op("Id", s1))   + (op("S-", s2) *op("Id", s1)) )
    #   1 / 2 * op("S+", s1) * op("S-", s2) +
    #   1 / 2 * op("S-", s1) * op("S+", s2)
    
    Gj = exp(-im * tau / 2 * hj) #making Trotter gate Gj that would correspond to each gate in the gate array of ITensors
    push!(gates,Gj) # The push! function adds an element to the end of an array, ! = performs an operation without creating a new object, (in a wy overwite the previous array in consideration) i.e. it appends a new element Gj (which is an ITensor object representing a gate) to the end of the gates array.
end
  # Include gates in reverse order too
  # (N,N-1),(N-1,N-2),...
  append!(gates,reverse(gates)) # append! adds all the elements of a collection to the end of an array.


  # Initialize psi to be a product state (alternating up and down)
  psi = productMPS(s, n -> isodd(n) ? "Up" : "Dn")

  c = div(N, 2) # center site # c = N/2 because only half of the spins on the chain are utilized 


  # Compute and print <Sz> at each time step
  # then apply the gates to go to the next time
  for t in 0.0:tau:ttotal
    Sz = expect(psi, "Sz"; sites=c) # computing initial expectation value of Sz at the center of the chain (site c)
    println("$t $Sz")  #Sz measured at each time step.
      # Do the time evolution by applying the gates
      # till ttotal with the time difference of Tau
    t≈ttotal && break

    psi = apply(gates, psi; cutoff)# apply each gate in gates successively to the wavefunction psi =  evolving the wavefunction in time according to the time-dependent Hamiltonian represented by the gates.
    # The apply function is smart enough to determine which site indices each gate has, and then figure out where to apply it to our MPS. It automatically handles truncating the MPS and can even handle non-nearest-neighbor gates, though that feature is not used in this example.
    normalize!(psi) #The normalize! function is used to ensure that the MPS is properly normalized after each application of the time evolution gates. This is necessary to ensure that the MPS represents a valid quantum state
  end

  return
end
