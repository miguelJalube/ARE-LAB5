#create library work        
vlib work
#map library work to work
vmap work work

#compile all file 
vcom -reportprogress 300 -2008 -work work   ../src/avl_user_interface.vhd
vcom -reportprogress 300 -2008 -work work   ../src/generateur_nombres.vhd

# top_sim compilation
vcom -reportprogress 300 -2008 -work work   ../src_tb/avalon_console_sim.vhd

#Chargement fichier pour la simulation
vsim -voptargs="+acc" work.avalon_console_sim 

#lance la console REDS
do ../../console/sim_avalon.tcl

#ajout signaux composant simuler dans la fenetre wave
add wave -divider DUT
add wave dut/*
