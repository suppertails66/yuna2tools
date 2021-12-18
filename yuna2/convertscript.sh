set -o errexit

#soffice --headless --convert-to ods --infilter=CSV:44,34,64 $file

#mkdir -p test
#soffice --headless --convert-to csv --infilter=CSV:44,34,64 "yuna_script.ods" 
#soffice --headless --convert-to csv:"Text - txt - csv (StarCalc)" "yuna_script.ods"
#soffice --headless --convert-to xlsx --outdir test yuna_script.ods

cd script
#soffice --headless --convert-to csv --infilter=CSV:44,34,76 --outdir test yuna_script.ods
#soffice --headless --convert-to csv --infilter=CSV:44,34,76 script.xlsx
soffice --headless --convert-to csv --infilter=CSV:44,34,76 script_main.ods
soffice --headless --convert-to csv --infilter=CSV:44,34,76 script_battle.ods
soffice --headless --convert-to csv --infilter=CSV:44,34,76 script_scene.ods
