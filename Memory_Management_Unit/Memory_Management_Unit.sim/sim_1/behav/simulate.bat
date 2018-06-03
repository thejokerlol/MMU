@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.2\\bin
call %xv_path%/xsim Translation_Buffer_tb_behav -key {Behavioral:sim_1:Functional:Translation_Buffer_tb} -tclbatch Translation_Buffer_tb.tcl -view C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Translation_Buffer_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
