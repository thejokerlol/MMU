# 
# Synthesis run script generated by Vivado
# 

debug::add_scope template.lib 1
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7a100tcsg324-1

set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.cache/wt [current_project]
set_property parent.project_path C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
read_verilog -library xil_defaultlib {
  C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/sources_1/new/RAM.v
  C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/sources_1/new/Translation_Buffer.v
  C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/sources_1/new/AXI_Slave_RAM.v
  C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/sources_1/new/mmu.v
}
read_xdc C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/constrs_1/new/mmu_constraints.xdc
set_property used_in_implementation false [get_files C:/Users/vamsi/Desktop/MMU/Memory_Management_Unit/Memory_Management_Unit.srcs/constrs_1/new/mmu_constraints.xdc]

synth_design -top mmu -part xc7a100tcsg324-1 -flatten_hierarchy none
write_checkpoint -noxdef mmu.dcp
catch { report_utilization -file mmu_utilization_synth.rpt -pb mmu_utilization_synth.pb }
