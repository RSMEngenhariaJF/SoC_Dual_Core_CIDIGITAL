#!/usr/bin/env python3
"""
UVM Simulation Runner
Compiles and runs UVM testbench for CVA6 SoC
"""

import os
import sys
import subprocess
from pathlib import Path

class UVMSimRunner:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.uvm_tb_dir = self.project_root / "uvm_tb"
        self.sim_dir = self.uvm_tb_dir / "sim"
        self.sim_dir.mkdir(exist_ok=True)
    
    def compile(self, test_name="base_test"):
        """Compile UVM testbench"""
        print(f"[UVM] Compiling testbench for test: {test_name}")
        
        # VCS compilation command
        cmd = [
            "vcs",
            "-sverilog",
            "+incdir+uvm_tb",
            f"+incdir+{self.project_root}/rtl",
            "-f", str(self.uvm_tb_dir / "files.f"),
            "-top", "tb_soc_uvm",
            "-o", str(self.sim_dir / "simv"),
            "+define+TEST_NAME=" + test_name
        ]
        
        print(f"[UVM] Command: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=self.sim_dir)
        
        return result.returncode == 0
    
    def run(self, test_name="base_test", dump_vcd=False):
        """Run UVM simulation"""
        print(f"\n[UVM] Running simulation with test: {test_name}")
        
        cmd = [
            str(self.sim_dir / "simv"),
            f"+UVM_TESTNAME={test_name}",
            "+UVM_VERBOSITY=UVM_MEDIUM"
        ]
        
        if dump_vcd:
            cmd.append("+dump_vcd")
        
        print(f"[UVM] Command: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=self.sim_dir)
        
        return result.returncode == 0
    
    def generate_file_list(self):
        """Generate compilation file list"""
        files = [
            "../../rtl/axi4/axi4_defines.sv",
            "../../rtl/ace/ace_bus.sv",
            "../agents/ace_master_agent.sv",
            "../agents/ace_slave_agent.sv",
            "../agents/memory_agent.sv",
            "../monitors/ace_monitor.sv",
            "../monitors/coherency_monitor.sv",
            "../sequences/ace_sequences.sv",
            "../sequences/coherency_sequences.sv",
            "../scoreboards/coherency_sb.sv",
            "../env/soc_env.sv",
            "../env/soc_virtual_sequencer.sv",
            "../tests/soc_tests.sv",
            "../tb_soc_uvm.sv"
        ]
        
        file_list = self.uvm_tb_dir / "files.f"
        with open(file_list, 'w') as f:
            for file in files:
                f.write(f"{file}\n")
        
        print(f"[UVM] Generated: {file_list}")

def main():
    runner = UVMSimRunner()
    
    # Available tests
    tests = [
        "base_test",
        "read_test",
        "write_test",
        "mixed_test",
        "coherency_test",
        "stress_test"
    ]
    
    print("=" * 70)
    print("CVA6 SoC UVM Test Suite")
    print("=" * 70)
    print("\nAvailable tests:")
    for i, test in enumerate(tests, 1):
        print(f"  {i}. {test}")
    print()
    
    if len(sys.argv) > 1:
        test_name = sys.argv[1]
    else:
        test_name = "base_test"
    
    if test_name not in tests:
        print(f"ERROR: Unknown test '{test_name}'")
        print(f"Available tests: {', '.join(tests)}")
        return 1
    
   # Generate file list
    runner.generate_file_list()
    
    # Compile
    if not runner.compile(test_name):
        print("[ERROR] Compilation failed")
        return 1
    
    # Run
    dump_vcd = "--dump" in sys.argv
    if not runner.run(test_name, dump_vcd):
        print("[ERROR] Simulation failed")
        return 1
    
    print("\n[UVM] Simulation completed successfully!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
