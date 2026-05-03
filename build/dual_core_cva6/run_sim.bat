@echo off
REM run_sim.bat — elabora (se necessário) e simula tb_soc_dual_core
REM Uso: run_sim.bat  (duplo-clique ou no terminal)

set ROOT=%~dp0
set VIVADO=C:\Xilinx\2025.1\Vivado\bin
set SIM_DIR=%ROOT%work\sim
set TOP=tb_soc_dual_core

echo === Copiando boot.hex para diretorio de simulacao ===
copy /Y "%ROOT%tb\boot.hex" "%SIM_DIR%\boot.hex" >nul

echo === Elaborando ===
cd /d "%SIM_DIR%"
"%VIVADO%\vivado.bat" -mode batch -source "%ROOT%driver.tcl"
if errorlevel 1 goto :err

echo === Simulando ===
"%VIVADO%\xsim.bat" "work.%TOP%" -runall -log simulate.log
if errorlevel 1 goto :err

echo.
echo === Resultado ===
findstr /C:"PASS" /C:"FAIL" /C:"TIMEOUT" simulate.log
goto :end

:err
echo ERRO durante o flow — verifique os logs.
:end
pause
