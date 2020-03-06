sudo sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list'
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install r-base libapparmor1 libcurl4-gnutls-dev libxml2-dev libssl-dev gdebi-core
sudo apt-get install libcairo2-dev
sudo apt-get install libxt-dev
sudo apt-get install git-core

sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
sudo /sbin/mkswap /var/swap.1
sudo /sbin/swapon /var/swap.1
sudo sh -c 'echo "/var/swap.1 swap swap defaults 0 0 " >> /etc/fstab'

sudo su - -c "R -e \"install.packages('devtools', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('Rcpp', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('RcppEigen', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('ggplot2', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('Cairo', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('evaluate', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('formatR', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('highr', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('markdown', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('yaml', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('htmltools', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('knitr', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('rmarkdown', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('RColorBrewer', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('easypackages', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('BiocParallel')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('Biobase')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('EBSeq')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('monocle')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('sincell')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('scde')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('scran')\""
sudo su - -c "R -e \"source('http://bioconductor.org/biocLite.R'); biocLite('scater')\""
sudo su - -c "R -e \"devtools::install_github('kdkorthauer/scDD')\""

wget https://download2.rstudio.org/rstudio-server-0.99.903-amd64.deb

sudo gdebi rstudio-server-0.99.903-amd64.deb

# Setting up local R environment to connect to Github

touch $HOME/.Renviron

echo 'GITHUB_PAT=1dbd984bbfd5436b3021a6a5d0ed0fb4d2a6c7c9' >> ~/.Renviron

sudo rstudio-server restart
