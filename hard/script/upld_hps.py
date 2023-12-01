#!/usr/bin/python3

from subprocess import Popen, PIPE
import os
from os import path
import argparse

QUARTUS_DIR = "/opt/intelFPGA/18.1/quartus/"
PRELOADER_FILE = "/opt/intelFPGA/18.1/University_Program/Monitor_Program/arm_tools/u-boot-spl.de1-soc.srec"

def run(command):

    my_env = os.environ.copy()
    my_env["PATH"] = QUARTUS_DIR + "/bin64/:" + my_env["PATH"]

    process = Popen(command, env=my_env, stdout=PIPE, shell=True)

    while True:
        line = process.stdout.readline().rstrip()
        if not line:
            break

        # Kill when waiting for gdb connection
        if line == b'Starting GDB Server.':
            process.kill()
            break

        yield line

if __name__ == "__main__":


    parser = argparse.ArgumentParser()

    parser.add_argument('-a', '--axf', help="binary .axf file that contains vectors table")

    args = parser.parse_args()


    if args.axf:
        axf_file = args.axf
        if not path.exists(axf_file):
            print(axf_file + " doesn't exist")
            exit()

        print("********************** MAKE SREC FILE **********************")
        for output in run("/opt/intelFPGA/18.1/University_Program/Monitor_Program/arm_tools/baremetal/bin/arm-altera-eabi-objcopy -v -O srec "+axf_file+" "+axf_file+".srec"):
            print(output.decode())

        print("********************** LOAD PRELOADER AND BINARY WITH VECTORS **********************")
        for output in run("quartus_hps -c 1 -o GDBSERVER --gdbport0=2843 --preloader=/opt/intelFPGA/18.1/University_Program/Monitor_Program/arm_tools/u-boot-spl.de1-soc.srec --preloaderaddr=0xffff13a0 --source="+axf_file+".srec"):
            print(output.decode())
    else:
        print("********************** LOAD PRELOADER **********************")
        for output in run("quartus_hps -c 1 -o GDBSERVER --gdbport0=2843 --preloader=/opt/intelFPGA/18.1/University_Program/Monitor_Program/arm_tools/u-boot-spl.de1-soc.srec --preloaderaddr=0xffff13a0"):
            print(output.decode())