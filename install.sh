cd TauP-0.01
perl Makefile.PL
make
make test
sudo make install
cd ../Seismogram-1.02
perl Makefile.PL
make
make test
sudo make install
cd ../Seed-Response-0.01
perl Makefile.PL
make
make test
sudo make install
cd ..

installpath='/usr/local/bin/sac2mt5'
pwd
sudo mkdir $installpath
sudo cp -r * $installpath

sudo mkdir -p /usr/local/share/man/man1/
sudo cp sac2mt5.1.gz /usr/local/share/man/man1/

if [[ ":$PATH:" == *":$installpath:"* || ":$PATH:" == *":$installpath"* ]]; then
  echo "Your path is already set"
else
  echo "Adding $installpath to environment $PATH";
  echo "export PATH=\$PATH:$installpath" >> ~/.bashrc
  echo 
  echo 
  echo "Please run $(tput setaf 1)source ~/.bashrc$(tput sgr0) after this script stops running to finish installation." 

fi