#!/usr/bin/env python3
"""
UVM Test Environment Structure Validator
"""

import os
from pathlib import Path

def validate_uvm_structure():
    """Validate UVM environment structure"""
    
    root = Path(".")
    
    required_files = {
        "agents/ace_master_agent.sv": "ACE Master Agent",
        "agents/ace_slave_agent.sv": "ACE Slave/Snoop Agent",
        "agents/memory_agent.sv": "Memory Model",
        
        "monitors/ace_monitor.sv": "ACE Protocol Monitor",
        "monitors/coherency_monitor.sv": "Coherency Validator",
        
        "sequences/ace_sequences.sv": "ACE Test Sequences",
        "sequences/coherency_sequences.sv": "Coherency Test Patterns",
        
        "scoreboards/coherency_sb.sv": "Coherency Scoreboard",
        
        "env/soc_env.sv": "UVM Environment",
        "env/soc_virtual_sequencer.sv": "Virtual Sequencer",
        
        "tests/soc_tests.sv": "Test Cases",
        "lib/soc_uvm_pkg.sv": "UVM Package",
        "tb_soc_uvm.sv": "Main Testbench",
        "README.md": "Documentation",
        "files.f": "Compilation List",
        "scripts/Makefile": "Build Script",
    }
    
    print("\n" + "="*70)
    print("UVM TEST ENVIRONMENT STRUCTURE VALIDATION")
    print("="*70 + "\n")
    
    total_files = len(required_files)
    found_files = 0
    total_lines = 0
    
    for file_path, description in required_files.items():
        full_path = root / file_path
        
        if full_path.exists():
            found_files += 1
            size = full_path.stat().st_size
            lines = len(open(full_path).readlines())
            total_lines += lines
            
            status = "✓"
            print(f"[{status}] {file_path:<45} {lines:4d} lines  ({description})")
        else:
            status = "✗"
            print(f"[{status}] {file_path:<45}  MISSING  ({description})")
    
    print("\n" + "-"*70)
    print(f"Total: {found_files}/{total_files} files found")
    print(f"Total Lines of Code: {total_lines}")
    print("-"*70 + "\n")
    
    # Structure analysis
    print("UVM HIERARCHY:\n")
    
    components = {
        "Agents": ["ACE Master (2x)", "ACE Slave (2x)", "Memory"],
        "Monitors": ["ACE Monitor (2x)", "Coherency Monitor"],
        "Sequences": ["Read/Write/Mixed", "Coherency Patterns", "Stress"],
        "Scoreboards": ["Coherency Verification"],
        "Environment": ["Multi-Agent Coordination", "Virtual Sequencer"],
        "Tests": [
            "base_test",
            "read_test",
            "write_test", 
            "mixed_test",
            "coherency_test",
            "stress_test"
        ]
    }
    
    for component_type, items in components.items():
        print(f"\n{component_type}:")
        for item in items:
            print(f"  • {item}")
    
    print("\n" + "="*70)
    print("VERIFICATION STRATEGY\n")
    
    strategies = [
        ("Functional Verification", "Agents drive design with diverse transactions"),
        ("Protocol Compliance", "Monitors verify ACE protocol rules"),
        ("Coherency Verification", "Coherency scoreboard validates MOESI protocol"),
        ("Performance Analysis", "Track latency, throughput, cache efficiency"),
        ("Stress Testing", "Dual-core simultaneous transactions"),
        ("Coverage Collection", "Ready for coverage model integration"),
    ]
    
    for i, (strategy, description) in enumerate(strategies, 1):
        print(f"{i}. {strategy}")
        print(f"   → {description}\n")
    
    print("="*70 + "\n")
    
    print("TEST EXECUTION FLOW:\n")
    print("""
    tb_soc_uvm (Testbench)
        ↓
    UVM Test (e.g., coherency_test)
        ↓
    Virtual Sequencer
        ├─→ Core0 Agent Sequencer ─→ Driver → DUT
        ├─→ Core1 Agent Sequencer ─→ Driver → DUT
        └─→ Memory Agent → Driver (Memory Model)
        
    Monitors (Passive)
        ├─→ ACE Monitor 0
        ├─→ ACE Monitor 1
        └─→ Coherency Monitor
                ↓
            Coherency Scoreboard
                ↓
            Coverage Collection
                ↓
            Violation Reporting
    """)
    
    print("="*70)
    print("QUICK START\n")
    
    commands = [
        ("make compile TEST=read_test", "Compile testbench"),
        ("make simulate TEST=read_test", "Run read test"),
        ("make TEST=coherency_test test_with_vcd", "Run with VCD dump"),
        ("make test_all", "Run all tests"),
        ("make wave", "View waveforms in GTKWave"),
    ]
    
    for cmd, desc in commands:
        print(f"$ cd uvm_tb/scripts && make {cmd:<40} # {desc}")
    
    print("\n" + "="*70 + "\n")
    
    return found_files == total_files

if __name__ == "__main__":
    success = validate_uvm_structure()
    exit(0 if success else 1)
