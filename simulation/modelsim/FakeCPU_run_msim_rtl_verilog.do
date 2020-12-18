transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/clkgen.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/Instr_Reciver.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/FakeCPU.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/ALU.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/REG.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/MMemory.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/Decode.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/PC_register.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/MM_Manager.v}
vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU {D:/Programming/DigitExp/exp12/FakeCPU/fib_rom.v}

vlog -vlog01compat -work work +incdir+D:/Programming/DigitExp/exp12/FakeCPU/simulation/modelsim {D:/Programming/DigitExp/exp12/FakeCPU/simulation/modelsim/FakeCPU.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  FakeCPU_vlg_tst

add wave *
view structure
view signals
run -all
