
 add_fsm_encoding \
       {AXI_Slave_RAM.ram_controller_state} \
       { }  \
       {{0000 000} {0001 001} {0010 010} {0011 011} {0100 100} {0101 101} }

 add_fsm_encoding \
       {mmu.mmu_state} \
       { }  \
       {{0000 0000} {0001 0001} {0010 0010} {0011 0011} {0100 0100} {0101 0101} {0110 0110} {0111 0111} {1000 1000} {1001 1001} {1010 1010} {1011 1011} }
