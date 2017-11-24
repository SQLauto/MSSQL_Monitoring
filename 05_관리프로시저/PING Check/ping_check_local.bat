@echo off
set mydate=%date:/=%
set logfile=d:\ping\%COMPUTERNAME%_local_%mydate: =%.txt


for /L %%A in (1,1,86400) do (
 	call :loop
	timeout 1 > NUL  
 
)
:loop
echo %date% %time% >> %logfile%