@echo off
set mydate=%date:/=%
set logfile=p:\ping\%COMPUTERNAME%_storage_%mydate: =%.txt

for /L %%A in (1,1,86400) do (
 	call :loop
	timeout 1 > NUL  
 
)
:loop
echo %date% %time% >> %logfile%