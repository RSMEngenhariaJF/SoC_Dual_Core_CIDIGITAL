#!/usr/bin/env python3
"""
SoC Structure Validator and Documentation Generator
Validates the dual-core CVA6 SoC with ACE coherency structure
"""

import os
import sys
from pathlib import Path

class SoCValidator:
    def __init__(self, root_path):
        self.root = Path(root_path)
        self.errors = []
        self.warnings = []
        self.info = []
    
    def validate_structure(self):
        """Validate project structure"""
        required_files = {
            'rtl/axi4/axi4_defines.sv': 'AXI4 Protocol Definitions',
            'rtl/ace/ace_bus.sv': 'ACE Bus Interface',
            'rtl/cores/cva6_wrapper.sv': 'CVA6 Dual-Core Wrapper',
            'rtl/ccu/ccu.sv': 'Cache Coherency Unit',
            'rtl/llc/llc.sv': 'Last Level Cache',
            'rtl/top/soc_top.sv': 'SoC Top-Level Integration',
            'tb/tb_soc_top.sv': 'SoC Testbench',
            'scripts/Makefile': 'Build Script'
        }
        
        print("=" * 70)
        print("CVA6 Dual-Core SoC with ACE Coherency - Structure Validation")
        print("=" * 70)
        print()
        
        # Check each required file
        for file_path, description in required_files.items():
            full_path = self.root / file_path
            
            if full_path.exists():
                size = full_path.stat().st_size
                lines = len(open(full_path).readlines())
                status = "✓ FOUND"
                print(f"[{status}] {file_path:<40} ({lines:4d} lines, {size:6d} bytes)")
                self.info.append(f"{file_path}: {description}")
            else:
                status = "✗ MISSING"
                print(f"[{status}] {file_path:<40} - ERROR: File not found!")
                self.errors.append(f"Missing file: {file_path}")
        
        print()
        print("=" * 70)
        print("Project Summary")
        print("=" * 70)
        print()
        
        # Project structure
        print("Main Components:")
        print("  1. CVA6 Wrapper (2x) - RISC-V processor with ACE interface")
        print("  2. Cache Coherency Unit (CCU) - Snoop broadcast and arbitration")
        print("  3. Last Level Cache (LLC) - Shared L2 cache (4KB)")
        print("  4. ACE Bus Interface - AMBA ACE protocol implementation")
        print()
        
        print("Features:")
        print("  • Dual-core RISC-V architecture (CVA6)")
        print("  • AMBA AXI4 + ACE coherency extensions")
        print("  • Snoop-based cache coherency (MOESI compatible)")
        print("  • Shared L2 cache with 4-way associativity")
        print("  • Comprehensive testbench with memory model")
        print()
        
        # Report validation results
        if self.errors:
            print(f"Errors ({len(self.errors)}):")
            for err in self.errors:
                print(f"  ✗ {err}")
            print()
        
        if self.warnings:
            print(f"Warnings ({len(self.warnings)}):")
            for warn in self.warnings:
                print(f"  ⚠ {warn}")
            print()
        
        print("=" * 70)
        if not self.errors:
            print("✓ VALIDATION SUCCESSFUL - Project structure is complete!")
            print("=" * 70)
            print()
            print("Next steps:")
            print("  1. Review generated RTL files in rtl/ directory")
            print("  2. Run: make -C scripts compile")
            print("  3. Run: make -C scripts simulate")
            print("  4. Open waveforms: make -C scripts wave")
            return 0
        else:
            print("✗ VALIDATION FAILED - Please fix the errors above!")
            print("=" * 70)
            return 1

    def generate_block_diagram(self):
        """Generate ASCII block diagram"""
        diagram = """
        ┌─────────────────────────────────────────────────────────┐
        │           CVA6 Dual-Core SoC with ACE                  │
        ├─────────────────────────────────────────────────────────┤
        │                                                         │
        │    ┌──────────┐              ┌──────────┐              │
        │    │  CVA6    │              │  CVA6    │              │
        │    │ Core 0   │              │ Core 1   │              │
        │    │(Master)  │              │(Master)  │              │
        │    └─────┬────┘              └────┬─────┘              │
        │          │                         │                   │
        │          │     ACE Interface       │                   │
        │          └──────────┬──────────────┘                   │
        │                     │                                  │
        │                ┌────▼─────┐                            │
        │                │    CCU    │                            │
        │                │(Coherency │                            │
        │                │   Unit)   │                            │
        │                └────┬─────┘                            │
        │                     │                                  │
        │                ┌────▼─────┐                            │
        │                │    LLC    │                            │
        │                │(4KB L2)   │                            │
        │                └────┬─────┘                            │
        │                     │                                  │
        │                ┌────▼─────────────┐                   │
        │                │  External Memory │                    │
        │                │   (DDR Model)    │                    │
        │                └──────────────────┘                   │
        │                                                         │
        └─────────────────────────────────────────────────────────┘

        Coherency Protocol: MOESI (Modified, Owned, Exclusive, Shared, Invalid)
        """
        return diagram

def main():
    if len(sys.argv) < 2:
        root_path = os.getcwd()
    else:
        root_path = sys.argv[1]
    
    validator = SoCValidator(root_path)
    result = validator.validate_structure()
    
    print()
    print(validator.generate_block_diagram())
    
    return result

if __name__ == "__main__":
    sys.exit(main())
