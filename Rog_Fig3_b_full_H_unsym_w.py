
# This file plots using the datafiles generated for table I(Rog) 
# from julia testfile of t_p vs N_sites. 

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

# Define the directory and file name, N_sites and ttotal are inputs that need to be formatted into the file path
N_start = 4  
N_stop = 24
file_path = f"misc/datafiles/Rog/N_start_{N_start}/N_stop_{N_stop}/N_tpRog_tpmine.dat"

# Read the data from the file
data = np.loadtxt(file_path)

# the file structure is:
# delta_omega t_p_Rog t_p_mine
N_array = data[:, 0]
t_p_array_Rog = data[:, 1]
t_p_array_mine = data[:, 2]
mpl.rc('text', usetex=True)
mpl.rcParams['font.size'] = 20
mpl.rcParams['font.family'] = 'serif'

mpl.rcParams['xtick.major.size'] = 7
mpl.rcParams['xtick.major.width'] = 2
mpl.rcParams['xtick.major.pad'] = 8
mpl.rcParams['xtick.minor.size'] = 4
mpl.rcParams['xtick.minor.width'] = 2
mpl.rcParams['ytick.major.size'] = 7
mpl.rcParams['ytick.major.width'] = 2
mpl.rcParams['ytick.minor.size'] = 4
mpl.rcParams['ytick.minor.width'] = 2
mpl.rcParams['axes.linewidth'] = 2
fig, ax = plt.subplots(figsize=(10, 8))

ax.tick_params(axis='both', which='both', direction='in', top=True, right=True)
ax.minorticks_on()

plt.plot(N_array, t_p_array_Rog, label="Rogerro(2021)")
ax.scatter(N_array, t_p_array_mine, color="g", s=70, label="Our results") 

# # Calculate the log(N_sites) line
# log_N_line = np.log(N_array)
# plt.plot(N_array, log_N_line, linestyle='--', label="log(N_sites)")

plt.xlabel("System size N")
plt.ylabel("Minimum time $t_p$ [$\mu^{-1}$]")
ax.set_title("Rogerro(2021) Fig. 3(b) for an unsymmetric $\delta_{\omega}$=$\mu / 4$", fontsize=24) 
plt.legend(frameon=False)
ax.grid(False)
plt.savefig("N_vs_t_p_for_unsymmetric_del_omega.pdf")
plt.show()
