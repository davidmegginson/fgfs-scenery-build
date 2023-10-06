@echo off
echo Linking to TerraSync directories for osm2city...

for %%d in (Buildings Details Models Objects Pylons Roads) do (
    mklink /j %%d "%USERPROFILE%\FlightGear\Downloads\TerraSync\%%d"
)

echo done
exit /b 0
