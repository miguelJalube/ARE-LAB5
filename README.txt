Project for the Terasic DE1-Soc board

This projects used avalon bus from HPS and it is exported to design an interface in the FPGA side. 
The interface designed control DE1SoC IO (leds, buttons, switches) and others functions.


How to run the project:
    - compile Quartus project (located in hard/eda/DE1_SoC.qpf)
    - open Arm Development Studio, open the corresponding project located in soft/proj
    - Load the board with the .sof file (with python3 script setup_de1_soc.py), 
    - Compile the source files and load the processor
    - Run


folder structure:
    - doc: documentation
    - hard: files related to hardware, ie VHDL source and simulation files, Quartus and Qsys project
    - publi: publications
    - soft: files related to software, ie linux files and project, Altera Monitor Program source and project files
