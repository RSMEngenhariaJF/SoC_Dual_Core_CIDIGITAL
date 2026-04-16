# UVM Test Environment - CVA6 Dual-Core SoC with ACE Coherency

## Overview

This directory contains a complete UVM (Universal Verification Methodology) test environment for verifying the dual-core CVA6 SoC with AMBA ACE coherency extensions.

## Directory Structure

```
uvm_tb/
├── agents/
│   ├── ace_master_agent.sv    # ACE master transactions (cores)
│   ├── ace_slave_agent.sv     # Snoop responder agent
│   └── memory_agent.sv        # External memory model
├── env/
│   ├── soc_env.sv             # UVM environment with all agents
│   └── soc_virtual_sequencer.sv  # Coordinates multi-core sequences
├── monitors/
│   ├── ace_monitor.sv         # Captures ACE transactions
│   └── coherency_monitor.sv   # Tracks coherency protocol
├── sequences/
│   ├── ace_sequences.sv       # Read/Write/Mixed test sequences
│   └── coherency_sequences.sv # Coherency-specific test patterns
├── scoreboards/
│   └── coherency_sb.sv        # Verifies coherency correctness
├── tests/
│   └── soc_tests.sv           # Test cases (read, write, stress, etc)
├── lib/
│   └── soc_uvm_pkg.sv         # UVM package
├── scripts/
│   ├── run_tests.py           # Test runner
│   └── Makefile               # Build commands
└── tb_soc_uvm.sv              # Main UVM testbench

sim/                           # Simulation artifacts (generated)
```

## Test Cases

### 1. **base_test**
   - Minimal test to verify UVM environment connectivity
   - No transactions generated

### 2. **read_test**
   - Generates read-only transactions from single core
   - Tests ACE read address and read data channels
   - Verifies read responses

### 3. **write_test**
   - Generates write-only transactions from single core
   - Tests ACE write address, write data, write response channels
   - Verifies write completion

### 4. **mixed_test**
   - Random mix of read and write transactions
   - Single core operation
   - Tests AXI4 protocol arbitration

### 5. **coherency_test**
   - Tests cache coherency between two cores
   - Verifies write invalidation protocol
   - Monitors snoop broadcasts and responses

### 6. **stress_test**
   - Both cores running random transactions simultaneously
   - Tests arbitration, prioritization, and snoop handling
   - Stress tests CCU and LLC components

## Components

### Agents

#### ace_master_agent
- **Sequencer**: Accepts sequence items
- **Driver**: Drives ACE master signals (read/write requests)
- **Monitor**: Captures all master transactions

#### ace_slave_agent
- **Driver**: Responds to snoop requests (AC channel)
- **Monitor**: Captures snoop activity

#### memory_agent
- **Driver**: Simulates external DDR memory
- **Monitor**: Tracks memory transactions

### Monitors

#### ace_monitor
- Tracks all ACE protocol phases (AW, W, B, AR, R, AC, CR, CD)
- Reports transactions with timing information
- Per-core monitoring with master ID tracking

#### coherency_monitor
- Analyzes cache coherency state transitions
- Detects coherency violations
- Tracks snoop broadcasts and responses

### Scoreboards

#### coherency_sb
- Collects coherency monitor events
- Verifies proper coherency protocol execution
- Reports violations and successful sequences

## Running Tests

### Using Python script
```bash
cd scripts
python run_tests.py read_test              # Run read test
python run_tests.py coherency_test --dump  # Run with VCD dump
```

### Using Makefile
```bash
cd scripts
make compile TEST=read_test                # Compile
make simulate TEST=read_test               # Run
make all TEST=stress_test                  # Complete flow
```

### Manual VCS execution
```bash
vcs -sverilog -f files.f -top tb_soc_uvm +UVM_TESTNAME=coherency_test
./simv +UVM_VERBOSITY=UVM_MEDIUM
```

## Test Methodology

### Addressing
- Each test generates random addresses in range: 0x00000000 - 0x0FFFFFFF
- Data is constrained or randomized through sequence randomization

### Randomization
- Sequence items use `rand` constraints for:
  - Address field (memory range bounded)
  - Data patterns (32-bit or 64-bit)
  - Snoop types (0-7 range)
  - Cache domains and states

### Coverage
- Functional coverage TBD
- Can be added via `covergroup` in agents/monitors
- Track snoop response types, cache state transitions

### Assertions
- Protocol assertions can be added to ace_bus interface
- Valid signal timing assertions
- Handshake protocol verification

## Performance Metrics

After simulation, review:
- **Throughput**: Transactions per 100ns cycle
- **Latency**: Transaction initiation to completion time
- **Cache Hit Rate**: Requests serviced from LLC vs memory
- **Snoop Efficiency**: Snoop broadcasts vs actual updates
- **Coherency Violations**: Should be 0

## Debugging

### Enable detailed logging
```bash
./simv +UVM_VERBOSITY=UVM_FULL +UVM_DEBUG
```

### View waveforms
```bash
gtkwave uvm_sim.vcd &
```

### Monitor specific signals
```bash
./simv +uvm_set_type_override=ace_master_driver,debug_ace_master_driver
```

## Common Issues

### 1. Virtual Interface Not Found
Ensure `uvm_config_db` settings match the path in build_phase.

### 2. Simulation Hangs
Check if:
- Clock is toggling (`clk` signal in VCD)
- Reset properly released
- Ready/Valid handshakes complete

### 3. Coherency Violations
Verify:
- Snoop responses are being generated
- Cache state machine is advancing correctly
- Write invalidations reach all cores

## Future Enhancements

- [ ] Functional coverage model
- [ ] Assertions library
- [ ] Power analysis
- [ ] Performance monitoring
- [ ] AXI4 protocol checker
- [ ] ACE protocol compliance checks
- [ ] Master-slave relationship tracking
- [ ] Transaction logging to CSV

## References

- UVM 1.2 LRM
- AMBA AXI4 Specification
- AMBA ACE Specification
- SystemVerilog IEEE 1800-2017

