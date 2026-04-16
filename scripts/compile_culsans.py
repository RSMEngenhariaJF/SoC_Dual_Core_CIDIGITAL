#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CULSANS CCU Integration Build Script
Compila projeto com CCU completo do CULSANS

Uso:
    python compile_culsans.py [--test base_test|coherency_test|stress_test]
"""

import os
import subprocess
import sys
from pathlib import Path

# Configuração
PROJECT_ROOT = Path(__file__).parent
RTL_DIR = PROJECT_ROOT / "rtl"
TOP_MODULE = "culsans_top"  # Usando CULSANS como top-level (tem CCU integrado)
SIM_DIR = PROJECT_ROOT / "sim"

# Arquivos RTL em ordem de compilação (includes primeiro!)
RTL_FILES = [
    # CULSANS Package (DEVE SER PRIMEIRO)
    f"{RTL_DIR}/ccu/culsans_rtl/include/culsans_pkg.sv",
    
    # CULSANS Top (contém CCU, LLC, cores, axi_xbar, etc)
    f"{RTL_DIR}/ccu/culsans_rtl/src/culsans_top.sv",
    f"{RTL_DIR}/ccu/culsans_rtl/src/culsans_peripherals.sv",
    
    # CVA6 Cores (do arquivo flist)
    # Os arquivos estão listados em rtl/cores/cva6/files.f
]

# Testbenches disponíveis
TESTBENCHES = {
    "base_test": "tb/base_test.sv",  # Conectividade básica
    "coherency_test": "tb/coherency_test.sv",  # Valida MOESI
    "stress_test": "tb/stress_test.sv",  # 100 transações 2-cores
}

def build_filelist(cva6_flist="rtl/cores/cva6/files.f"):
    """Construir lista de arquivos incluindo CVA6 flist"""
    filelist = RTL_FILES.copy()
    
    # Ler e adicionar arquivos do flist do CVA6
    flist_path = PROJECT_ROOT / cva6_flist
    if flist_path.exists():
        with open(flist_path) as f:
            for line in f:
                line = line. strip()
                if line and not line.startswith("#"):
                    # Converter caminhos relativos
                    filelist.append(f"-f {line}")
    
    return filelist

def compile_vcs(filelist, test_name="base_test", output_dir=None):
    """Compilar com VCS/Verilator"""
    if output_dir is None:
        output_dir = SIM_DIR / test_name
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n{'='*70}")
    print(f"🔧 Compilando com VCS - Teste: {test_name}")
    print(f"{'='*70}\n")
    
    # Comando compilação
    cmd = [
        "vcs",
        "-sverilog",
        "-64bit",
        f"-top {TOP_MODULE}",
        f"-o {output_dir}/simv_culsans",
        "-Mdirectory=" + str(output_dir / "csrc"),
        "-cc gcc",
        "-CFLAGS '-O2'",
        "+incdir+rtl/ccu/culsans_rtl/include",  # Includes CULSANS
        "+incdir+rtl/ace",
        "+incdir+rtl/axi4",
        "+libext+.sv+.v",
    ]
    
    # Adicionar arquivo listado
    for f in filelist:
        cmd.append(str(f))
    
    # Adicionar testbench
    if test_name in TESTBENCHES:
        cmd.append(str(PROJECT_ROOT / TESTBENCHES[test_name]))
    
    print(f"📝 Comando: {' '.join(cmd[:5])} ... ({len(filelist)} arquivos)")
    print(f"📂 Output: {output_dir}/simv_culsans\n")
    
    result = subprocess.run(" ".join(cmd), shell=True, cwd=PROJECT_ROOT)
    return result.returncode == 0

def compile_verilator(filelist, test_name="base_test", output_dir=None):
    """Compilar com Verilator (alternativa lightweight)"""
    if output_dir is None:
        output_dir = SIM_DIR / test_name / "verilator"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n{'='*70}")
    print(f"🟢 Compilando com Verilator - Teste: {test_name}")
    print(f"{'='*70}\n")
    
    cmd = [
        "verilator",
        "--cc",
        "-sv",
        "--trace",
        f"--top-module {TOP_MODULE}",
        f"-Mdir {output_dir}",
        "+incdir+rtl/ccu/culsans_rtl/include",
        "+incdir+rtl/ace",
    ]
    
    for f in filelist:
        cmd.append(str(f))
    
    print(f"📝 Compilando {len(filelist)} arquivos com Verilator...\n")
    result = subprocess.run(" ".join(cmd), shell=True, cwd=PROJECT_ROOT)
    return result.returncode == 0

def run_simulation(test_name="base_test", simulator="vcs"):
    """Executar simulação"""
    print(f"\n{'='*70}")
    print(f"▶️  Executando simulação: {test_name}")
    print(f"{'='*70}\n")
    
    sim_path = SIM_DIR / test_name / f"simv_culsans"
    if not sim_path.exists():
        print(f"❌ Simulador não encontrado: {sim_path}")
        return False
    
    # Rodar simulação
    result = subprocess.run(
        f"{sim_path} -ucli -i run.do",
        shell=True,
        cwd=PROJECT_ROOT / "sim" / test_name
    )
    return result.returncode == 0

def main():
    test_name = "base_test"
    simulator = "vcs"
    
    # Parse argumentos
    for arg in sys.argv[1:]:
        if arg.startswith("--test="):
            test_name = arg.split("=")[1]
        elif arg == "--verilator":
            simulator = "verilator"
    
    if test_name not in TESTBENCHES:
        print(f"❌ Teste desconhecido: {test_name}")
        print(f"   Disponíveis: {', '.join(TESTBENCHES.keys())}")
        sys.exit(1)
    
    # Build filelist
    print(f"\n📋 Preparando filelist...")
    filelist = build_filelist()
    print(f"✅ {len(filelist)} arquivos carregados")
    
    # Compilar
    try:
        if simulator == "vcs":
            success = compile_vcs(filelist, test_name)
        else:
            success = compile_verilator(filelist, test_name)
        
        if not success:
            print(f"\n❌ Compilação falhou!")
            sys.exit(1)
        
        print(f"\n✅ Compilação bem-sucedida!")
        print(f"   Simulador: {SIM_DIR / test_name}")
        
        # Perguntar se quer rodar
        print(f"\n🚀 Deseja rodar a simulação agora? (y/n) ", end="")
        # Se for não-interativo, pular
        # response = input().lower()
        # if response == 'y':
        #     run_simulation(test_name, simulator)
        
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
