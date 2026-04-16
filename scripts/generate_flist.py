#!/usr/bin/env python3
"""
Generate Flist for CVA6 from official Flist.cva6
Converts absolute paths to relative paths for our project
"""

import os
import re
from pathlib import Path

def generate_flist():
    project_root = Path("c:\\Users\\rafae\\Documents\\trabalho final")
    cva6_root = project_root / "rtl" / "cores" / "cva6-master"
    cva6_core_dir = cva6_root / "core"
    
    output_file = project_root / "rtl" / "cores" / "cva6" / "files.f"
    
    # Ler arquivo Flist.cva6
    input_file = cva6_core_dir / "Flist.cva6"
    
    if not input_file.exists():
        print(f"❌ Arquivo não encontrado: {input_file}")
        return False
    
    lines = []
    with open(input_file, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            
            # Pular comentários completos e linhas vazias
            if not line.strip() or line.strip().startswith('//'):
                continue
            
            # Processar keep lines (ex: -F, -v, etc)
            if line.startswith('-'):
                lines.append(line)
                continue
            
            # Processar incdir
            if line.startswith('+incdir+'):
                # Substituir variáveis
                line = line.replace('${CVA6_REPO_DIR}', str(cva6_root))
                line = line.replace('${HPDCACHE_DIR}', str(cva6_root / 'vendor' / 'pulp-platform' / 'hpdcache'))
                lines.append(line)
                continue
            
            # Processar -F (nested Flists)
            if line.startswith('-F '):
                path_str = line[3:].strip()
                path_str = path_str.replace('${CVA6_REPO_DIR}', str(cva6_root))
                path_str = path_str.replace('${HPDCACHE_DIR}', str(cva6_root / 'vendor' / 'pulp-platform' / 'hpdcache'))
                
                # Verificar se arquivo existe
                if Path(path_str).exists():
                    # Converter para relativo
                    rel_path = os.path.relpath(path_str, project_root)
                    lines.append(f"-F {rel_path}")
                continue
            
            # Processar caminhos de arquivo
            if '${' in line:
                line = line.replace('${CVA6_REPO_DIR}', str(cva6_root))
                line = line.replace('${HPDCACHE_DIR}', str(cva6_root / 'vendor' / 'pulp-platform' / 'hpdcache'))
            
            # Se for um caminho absoluto, converter para relativo
            if '\\' in line or ':' in line:
                full_path = Path(line)
                if full_path.exists():
                    rel_path = os.path.relpath(full_path, project_root)
                    lines.append(rel_path)
                    continue
            
            # Caso contrário, assumir que é relativo
            lines.append(line)
    
    # Remover duplicatas mantendo ordem
    seen = set()
    unique_lines = []
    for line in lines:
        if line not in seen:
            unique_lines.append(line)
            seen.add(line)
    
    # Criar arquivo de saída
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w') as f:
        # Header
        f.write("# CVA6 Compilation File List\n")
        f.write("# Generated from Flist.cva6\n")
        f.write("# Date: 2026-04-08\n\n")
        
        # Escrever linhas
        for line in unique_lines:
            f.write(line + '\n')
    
    print(f"✅ Arquivo gerado: {output_file}")
    print(f"   Total de linhas: {len(unique_lines)}")
    return True

if __name__ == "__main__":
    generate_flist()
