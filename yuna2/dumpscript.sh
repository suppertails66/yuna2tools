set -o errexit

#mkdir -p script/orig

#make scriptdump
#./scriptdump "yuna_02.iso"

make blackt
make libpce
make yuna2_scriptgen

./yuna2_scriptgen