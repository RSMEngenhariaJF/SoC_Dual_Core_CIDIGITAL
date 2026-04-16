#!/usr/bin/env python3
"""
CVA6 Real Core Integration Script
Automates the integration of real CVA6 from OpenHW repository
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

class CVA6Integrator:
    def __init__(self):
        self.project_root = Path(".")
        self.cva6_repo_path = self.project_root / "cva6_repo"
        self.cva6_rtl_dest = self.project_root / "rtl" / "cores" / "cva6"
    
    def check_git(self):
        """Check if git is available"""
        try:
            subprocess.run(["git", "--version"], capture_output=True, check=True)
            return True
        except:
            return False
    
    def clone_cva6(self):
        """Clone CVA6 repository"""
        print("[1] Cloning CVA6 Repository...")
        print(f"    Target: {self.cva6_repo_path}")
        
        if self.cva6_repo_path.exists():
            print("    [⚠] Repository already exists. Skipping clone.")
            return True
        
        cmd = ["git", "clone", "--depth", "1", 
               "https://github.com/openhwgroup/cva6.git", 
               str(self.cva6_repo_path)]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            if result.returncode == 0:
                print("    ✓ Clone successful")
                return True
            else:
                print(f"    ✗ Clone failed: {result.stderr}")
                return False
        except subprocess.TimeoutExpired:
            print("    ✗ Clone timeout (exceeded 5 minutes)")
            return False
        except Exception as e:
            print(f"    ✗ Clone error: {e}")
            return False
    
    def list_cva6_modules(self):
        """List all CVA6 modules to copy"""
        modules = [
            "corev_apu/cva6.sv",
            "corev_apu/alu.sv",
            "corev_apu/branch_unit.sv",
            "corev_apu/compressed_decoder.sv",
            "corev_apu/controller.sv",
            "corev_apu/csr_regfile.sv",
            "corev_apu/ex_stage.sv",
            "corev_apu/id_stage.sv",
            "corev_apu/if_stage.sv",
            "corev_apu/instr_decoder.sv",
            "corev_apu/mult.sv",
            "corev_apu/pmp.sv",
            "corev_apu/register_file.sv",
            "corev_apu/lsu/lsu.sv",
            "corev_apu/lsu/misaligned.sv",
            "corev_apu/lsu/pma.sv",
            "corev_apu/frontend/bht.sv",
            "corev_apu/frontend/instr_queue.sv",
            "corev_apu/frontend/icache.sv",
            "corev_apu/apu/apu.sv",
            "corev_apu/clint/clint.sv",
            "corev_apu/debug/dmi_cdc.sv",
            "corev_apu/debug/dm_csrs.sv",
            "corev_apu/util/*.sv"
        ]
        return modules
    
    def copy_cva6_files(self):
        """Copy CVA6 RTL files to project"""
        print("\n[2] Copying CVA6 RTL Files...")
        
        if not self.cva6_repo_path.exists():
            print("    ✗ CVA6 repository not found")
            return False
        
        self.cva6_rtl_dest.mkdir(parents=True, exist_ok=True)
        
        modules = self.list_cva6_modules()
        copied = 0
        
        for module in modules:
            src = self.cva6_repo_path / module
            if src.exists():
                if src.is_file():
                    dst = self.cva6_rtl_dest / src.name
                    shutil.copy2(src, dst)
                    copied += 1
                    print(f"    ✓ {src.name}")
                elif src.is_dir():
                    # Copy all files in directory
                    for f in src.glob("*.sv"):
                        dst = self.cva6_rtl_dest / f.name
                        shutil.copy2(f, dst)
                        copied += 1
                        print(f"    ✓ {f.name}")
        
        print(f"\n    Total files copied: {copied}")
        return copied > 0
    
    def create_adapter(self):
        """Create ACE adapter for CVA6 AXI interface"""
        print("\n[3] Creating ACE Adapter...")
        
        adapter_code = '''// CVA6 to ACE Adapter
// Converts CVA6 AXI4 interface to AXI4+ACE

module cva6_ace_adapter #(
    parameter AXI_ID_WIDTH = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
) (
    input clk,
    input rst_n,
    
    // AXI4 interface from CVA6
    input [AXI_ID_WIDTH-1:0] axi_awid,
    input [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input [7:0] axi_awlen,
    input [2:0] axi_awsize,
    input [1:0] axi_awburst,
    input axi_awvalid,
    output axi_awready,
    
    input [AXI_DATA_WIDTH-1:0] axi_wdata,
    input [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb,
    input axi_wlast,
    input axi_wvalid,
    output axi_wready,
    
    output [AXI_ID_WIDTH-1:0] axi_bid,
    output [1:0] axi_bresp,
    output axi_bvalid,
    input axi_bready,
    
    input [AXI_ID_WIDTH-1:0] axi_arid,
    input [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input [7:0] axi_arlen,
    input [2:0] axi_arsize,
    input [1:0] axi_arburst,
    input axi_arvalid,
    output axi_arready,
    
    output [AXI_ID_WIDTH-1:0] axi_rid,
    output [AXI_DATA_WIDTH-1:0] axi_rdata,
    output [1:0] axi_rresp,
    output axi_rlast,
    output axi_rvalid,
    input axi_rready,
    
    // ACE interface to interconnect
    ace_bus.master ace
);

    // Simple pass-through for now
    // Full adapter with snoop support would go here
    
    assign ace.awid = axi_awid;
    assign ace.awaddr = axi_awaddr;
    assign ace.awlen = axi_awlen;
    assign ace.awsize = axi_awsize;
    assign ace.awburst = axi_awburst;
    assign ace.awvalid = axi_awvalid;
    assign axi_awready = ace.awready;
    assign ace.awsnoop = 4'b0001; // WRITEUNIQUE
    assign ace.awdomain = 2'b11;  // SYS_SHARED
    
    assign ace.wdata = axi_wdata;
    assign ace.wstrb = axi_wstrb;
    assign ace.wlast = axi_wlast;
    assign ace.wvalid = axi_wvalid;
    assign axi_wready = ace.wready;
    
    assign axi_bid = ace.bid;
    assign axi_bresp = ace.bresp;
    assign axi_bvalid = ace.bvalid;
    assign ace.bready = axi_bready;
    
    assign ace.arid = axi_arid;
    assign ace.araddr = axi_araddr;
    assign ace.arlen = axi_arlen;
    assign ace.arsize = axi_arsize;
    assign ace.arburst = axi_arburst;
    assign ace.arvalid = axi_arvalid;
    assign axi_arready = ace.arready;
    assign ace.arsnoop = 4'b0101; // READUNIQUE
    assign ace.ardomain = 2'b11;  // SYS_SHARED
    
    assign axi_rid = ace.rid;
    assign axi_rdata = ace.rdata;
    assign axi_rresp = ace.rresp;
    assign axi_rlast = ace.rlast;
    assign axi_rvalid = ace.rvalid;
    assign ace.rready = axi_rready;

endmodule
'''
        
        adapter_path = self.cva6_rtl_dest / "cva6_ace_adapter.sv"
        with open(adapter_path, 'w') as f:
            f.write(adapter_code)
        
        print(f"    ✓ Created: {adapter_path}")
    
    def create_file_list(self):
        """Create compilation file list"""
        print("\n[4] Creating Compilation File List...")
        
        files = []
        
        # Add all copied files
        for f in sorted(self.cva6_rtl_dest.glob("*.sv")):
            files.append(f"rtl/cores/cva6/{f.name}")
        
        # Add adapter
        files.append("rtl/cores/cva6/cva6_ace_adapter.sv")
        
        file_list = self.project_root / "rtl" / "cores" / "cva6" / "files.f"
        with open(file_list, 'w') as f:
            for file in files:
                f.write(f"{file}\n")
        
        print(f"    ✓ Created: {file_list}")
        print(f"    ✓ Files: {len(files)}")
    
    def show_instructions(self):
        """Show integration instructions"""
        print("\n" + "="*70)
        print("CVA6 INTEGRATION COMPLETE")
        print("="*70 + "\n")
        
        print("Next steps:\n")
        print("1. Replace cva6_wrapper.sv with real CVA6 instantiation:")
        print("   rtl/cores/cva6_core.sv (new file)\n")
        
        print("2. Update rtl/top/soc_top.sv to use real CVA6:\n")
        print("   // Instead of cva6_wrapper, use:")
        print("   cva6_core #(...) core_inst (...);")
        print()
        
        print("3. Compile:\n")
        print("   xvlog -f rtl/cores/cva6/files.f -top soc_top")
        print()
        
        print("4. Run UVM tests:")
        print("   make -C uvm_tb TEST=coherency_test")
        print()
        
        print("Files created in:")
        print(f"   {self.cva6_rtl_dest}/")
        print()

def main():
    print("="*70)
    print("CVA6 Real Core Integration Tool")
    print("="*70 + "\n")
    
    integrator = CVA6Integrator()
    
    # Check for git
    if not integrator.check_git():
        print("✗ Git not found. Install git and try again.")
        print("\nManual integration:")
        print("1. Clone: git clone https://github.com/openhwgroup/cva6.git cva6_repo")
        print("2. Run this script again")
        return 1
    
    # Steps
    if not integrator.clone_cva6():
        return 1
    
    if not integrator.copy_cva6_files():
        return 1
    
    integrator.create_adapter()
    integrator.create_file_list()
    integrator.show_instructions()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
