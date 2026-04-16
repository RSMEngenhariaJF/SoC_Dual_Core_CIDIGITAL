#!/usr/bin/env python3
"""
Script de Build para Síntese com Vivado (Xilinx)

Este script automatiza o processo de síntese e implementação
do SoC dual-core em FPGA.

Uso:
    python vivado_build.py --project <name> --device <device> --synth
"""

import os
import sys
import argparse
import subprocess

class VivadoBuilder:
    def __init__(self, project_name="soc_dualcore", device="xc7z020clg400-1", output_dir="vivado"):
        self.project_name = project_name
        self.device = device
        self.output_dir = output_dir
        self.project_file = f"{output_dir}/{project_name}/{project_name}.xpr"
        
    def create_project(self):
        """Cria um novo projeto Vivado"""
        print(f"[INFO] Criando projeto Vivado: {self.project_name}")
        
        tcl_cmd = f"""
create_project -force {self.project_name} {self.output_dir}/{self.project_name}
set_property device {self.device} [current_project]
set_property board_part xilinx.com:zc702:part0:1.3 [current_project]
"""
        
        # Adiciona arquivos RTL
        rtl_files = [
            "../rtl/axi4/axi4_defines.sv",
            "../rtl/ace/ace_bus.sv",
            "../rtl/cores/core_simple.sv",
            "../rtl/ccu/ccu.sv",
            "../rtl/llc/llc.sv",
            "../rtl/top/soc_top.sv",
        ]
        
        for f in rtl_files:
            tcl_cmd += f'add_files {f}\n'
        
        tcl_cmd += """
update_compile_order -fileset sources_1
save_project_as -force {self.project_name} {self.output_dir}/{self.project_name}
"""
        
        # Escreve arquivo TCL
        tcl_file = f"{self.output_dir}/create_project.tcl"
        os.makedirs(self.output_dir, exist_ok=True)
        with open(tcl_file, 'w') as f:
            f.write(tcl_cmd)
        
        # Executa Vivado
        try:
            subprocess.run([
                "vivado", "-mode", "batch",
                "-source", tcl_file
            ], check=True)
            print("[OK] Projeto criado com sucesso!")
        except subprocess.CalledProcessError as e:
            print(f"[ERRO] Falha ao criar projeto: {e}")
            return False
        
        return True
    
    def run_synthesis(self):
        """Executa síntese"""
        print(f"[INFO] Executando síntese...")
        
        tcl_cmd = f"""
open_project {self.project_file}
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
report_timing_summary -file {self.output_dir}/{self.project_name}/synth_timing.txt
report_utilization -file {self.output_dir}/{self.project_name}/synth_utilization.txt
save_project_as {self.project_file}
"""
        
        tcl_file = f"{self.output_dir}/synthesis.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_cmd)
        
        try:
            subprocess.run([
                "vivado", "-mode", "batch",
                "-source", tcl_file
            ], check=True)
            print("[OK] Síntese concluída!")
        except subprocess.CalledProcessError as e:
            print(f"[ERRO] Falha na síntese: {e}")
            return False
        
        return True
    
    def run_implementation(self):
        """Executa implementação"""
        print(f"[INFO] Executando implementação...")
        
        tcl_cmd = f"""
open_project {self.project_file}
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary -file {self.output_dir}/{self.project_name}/impl_timing.txt
report_utilization -file {self.output_dir}/{self.project_name}/impl_utilization.txt
report_drc -file {self.output_dir}/{self.project_name}/impl_drc.txt
save_project_as {self.project_file}
"""
        
        tcl_file = f"{self.output_dir}/implementation.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_cmd)
        
        try:
            subprocess.run([
                "vivado", "-mode", "batch",
                "-source", tcl_file
            ], check=True)
            print("[OK] Implementação concluída!")
        except subprocess.CalledProcessError as e:
            print(f"[ERRO] Falha na implementação: {e}")
            return False
        
        return True
    
    def generate_bitstream(self):
        """Gera bitstream"""
        print(f"[INFO] Gerando bitstream...")
        
        tcl_cmd = f"""
open_project {self.project_file}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
"""
        
        tcl_file = f"{self.output_dir}/bitstream.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_cmd)
        
        try:
            subprocess.run([
                "vivado", "-mode", "batch",
                "-source", tcl_file
            ], check=True)
            print("[OK] Bitstream gerado!")
        except subprocess.CalledProcessError as e:
            print(f"[ERRO] Falha ao gerar bitstream: {e}")
            return False
        
        return True


def main():
    parser = argparse.ArgumentParser(
        description="Script de build para SoC dual-core com ACE"
    )
    parser.add_argument("--project", default="soc_dualcore",
                        help="Nome do projeto")
    parser.add_argument("--device", default="xc7z020clg400-1",
                        help="Dispositivo Xilinx")
    parser.add_argument("--output", default="vivado",
                        help="Diretório de saída")
    parser.add_argument("--synth", action="store_true",
                        help="Executa síntese")
    parser.add_argument("--impl", action="store_true",
                        help="Executa implementação")
    parser.add_argument("--bitstream", action="store_true",
                        help="Gera bitstream")
    parser.add_argument("--all", action="store_true",
                        help="Executa tudo (criar → síntese → impl → bitstream)")
    
    args = parser.parse_args()
    
    builder = VivadoBuilder(args.project, args.device, args.output)
    
    if args.all or args.synth or args.impl or args.bitstream:
        if args.all:
            if not builder.create_project():
                sys.exit(1)
            if not builder.run_synthesis():
                sys.exit(1)
            if not builder.run_implementation():
                sys.exit(1)
            if not builder.generate_bitstream():
                sys.exit(1)
        else:
            if args.synth:
                if not builder.run_synthesis():
                    sys.exit(1)
            if args.impl:
                if not builder.run_implementation():
                    sys.exit(1)
            if args.bitstream:
                if not builder.generate_bitstream():
                    sys.exit(1)
    else:
        if not builder.create_project():
            sys.exit(1)
    
    print("\n[OK] Fluxo de build concluído com sucesso!")


if __name__ == "__main__":
    main()
