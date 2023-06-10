using ITensors
using Plots
using Measures

N = 50 # number of sites NEED TO GO TILL 96
cutoff = 1E-8 # specifies a truncation threshold for the SVD in MPS representation THE SMALLER THE BETTER BECUASE SMALL CUTOFF MEANS MORE ENTANGLEMENT
tau = 0.05 # time step NEED TO BE 0.05
ttotal = 25 # total time of evolution NEED TO GO TILL 50
# delta_w_const =  0 #value for delta_w from Rog paper


# delta_w = ones(Float64, N÷2)
# delta_wB= - ones(Float64, N÷2)
# #delta_w = append!(delta_wA, delta_wB)
# append!(delta_w,delta_wB)
# delta_w = delta_w_const * delta_w
# println(delta_w)

s = siteinds("S=1/2", N; conserve_qns=true)  

gates = ITensor[] 


for i in 1:(N-1) 
    for j in i+1:N
        s1 = s[i]
        s2 = s[j]
        # Rog sigma_i = 2 * S_i of our code here 

         hj=  
         
         #-1/(4 *(N-1)) * (delta_w[i] * op("Sz", s1)* op("Id", s2) + delta_w[j] * op("Sz", s2) * op("Id", s1) ) + #S
        2.0/N *
        (op("Sz", s1) * op("Sz", s2) +
        1 / 2 * op("S+", s1) * op("S-", s2) +
        1 / 2 * op("S-", s1) * op("S+", s2))
        Gj = exp(-im * tau / 2 * hj)  
        push!(gates, Gj) 
    end
end

append!(gates, reverse(gates)) 

psi = productMPS(s, n -> isodd(n) ? "Dn" : "Up")

c = div(N, 2) # c = N/2 

Sz_array = Float64[] 
prob_surv_array = Float64[] 

# Specify the directory path
directory_path = "/home/zohalaraib/Test_rep/tests/Rog_tests"

# Create the file path within the specified directory
datafile_path = joinpath(directory_path, "datafiles", string(N) * "(par)_" * string(ttotal) * "(ttotal)final.txt")


# Open the file for writing
datafile = open(datafile_path, "w")

for t in 0.0:tau:ttotal
    sz = expect(psi, "Sz"; sites=1)
    push!(Sz_array, sz) 
    
    t ≈ ttotal && break  
    global psi = apply(gates, psi; cutoff)
    normalize!(psi) 

    prob_surv= 0.5 * (1- 2*sz)
    push!(prob_surv_array, prob_surv)
    println("$t $prob_surv")
    
    # Write the values to the data file
    println(datafile, "$t $prob_surv")
    flush(datafile) # Flush the buffer to write immediately
end

close(datafile)  # Close the file

@assert prob_surv_array[1] == 1.0

# Plotting P_surv vs t
plot(0.0:tau:tau*(length(prob_surv_array)-1), prob_surv_array, xlabel = "t", ylabel = "prob_surv", legend = false, size=(800, 600), aspect_ratio=:auto,margin= 10mm) 


# Save the plot in the same directory
plot_path = joinpath(directory_path, "plots", string(N) * "(par)_" * string(ttotal) * "(ttotal)final.png")

savefig(plot_path)