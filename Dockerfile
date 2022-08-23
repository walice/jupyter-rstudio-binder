FROM jupyter/scipy-notebook:ubuntu-20.04
LABEL maintainer="Alice Lepissier <alice.lepissier@gmail.com>"


###### START Binder code ######
# from https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

COPY . ${HOME}/work
USER root
RUN chown -R ${NB_UID} ${HOME}
###### END Binder code ######


###### START R code ######
# from https://github.com/jupyter/docker-stacks/blob/master/r-notebook/Dockerfile

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc \
    libfontconfig1-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# libfontconfig1-dev is a dependency for kableExtra/systemfonts

# Fix for devtools https://github.com/conda-forge/r-devtools-feedstock/issues/4
RUN ln -s /bin/tar /bin/gtar

USER ${NB_UID}

# R packages including IRKernel which gets installed globally.
# Use older version of R and build from source
# Because R graphics engine version 14 is not supported by this version of RStudio
RUN conda install --quiet --yes \
    'r-base=4.1.0' \
    'r-caret' \
    #'r-crayon' \
    'r-devtools' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    #'r-nycflights13' \
    'r-randomforest' \
    'r-rcurl' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-tidymodels' \
    'r-tidyverse' \
    'r-here' \
    'r-feather' \
    'r-ggridges' \
    'r-janitor' \
    'r-kableExtra' \
    'r-lfe' \
    'r-plm' \
    'r-stargazer' \
    'r-WDI' \
    'unixodbc' && \
    conda clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install e1071 R package (dependency of the caret R package)
RUN conda install --quiet --yes 'r-e1071' && \
    conda clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install R libraries (arrow package)
#COPY ./requirements.R .
#RUN Rscript requirements.R && rm requirements.R
###### END R code ######


###### START RStudio code ######
# from https://github.com/dddlab/docker-notebooks/blob/master/python-rstudio-notebook/Dockerfile
# Latest possible version before RStudio and jupyter-rsession-proxy break as issue described at
# https://github.com/jupyterhub/jupyter-rsession-proxy/issues/93
ENV RSTUDIO_VERSION=2022.07.1+554W
USER root

# RStudio pre-requisites
# from https://github.com/rstudio/rstudio-docker-products/blob/main/r-session-complete/bionic/Dockerfile
# and https://support.rstudio.com/hc/en-us/articles/206794537-Common-dependencies-for-RStudio-Workbench-and-RStudio-Server
# and https://github.com/rocker-org/rocker-versioned/blob/master/rstudio/3.6.3.Dockerfile
# from https://github.com/radiant-rstats/docker/blob/master/files/install-rstudio.sh
# from https://github.com/rstudio/rstudio-docker-products/
# and https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh
# and https://github.com/radiant-rstats/docker/blob/master/files/install-R.sh
# and https://support.rstudio.com/hc/en-us/articles/206794537-Common-dependencies-for-RStudio-Workbench-and-RStudio-Server
# and (v1) https://github.com/rocker-org/rocker-versioned/blob/master/rstudio/3.6.3.Dockerfile
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    gdebi-core \
    libapparmor1 \
    #libgc1c2 \
    libblas-dev \
    libc6 \
    libclang-dev \
    libbz2-* \
    libcurl4 \
    libcurl4-openssl-dev \
    #libcurl4-gnutls-dev \
    libedit2 \
    libicu* \
    libjpeg-turbo* \
    liblapack-dev \
    libobjc4 \
    libpangocairo-* \
    #libpcre2* \
    libpng16* \
    libpq5 \
    #libpq-dev \
    #libssl1.1 \
    libssl-dev \
    libtiff* \
    #libuser \
    #libuser1-dev \
    liblzma* \
    lsb-release \
    procps \
    psmisc \
    python-setuptools \
    rrdtool \
    tree \
    sudo \
    wget \
    zip unzip && \        
    apt-get clean && rm -rf /var/lib/apt/lists/* 
 

ENV PATH=$PATH:/${NB_USER}/lib/rstudio-server/bin \
    R_HOME=/opt/conda/lib/R
ARG LITTLER=${R_HOME}/library/littler

RUN \
    # Download RStudio
    #curl --silent -L --fail https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb > /tmp/rstudio.deb && \
    wget -q https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.07.1-554-amd64.deb > /tmp/rstudio.deb && \
    # Install RStudio
    #sudo apt install gdebi-core && \
    sudo gdebi /tmp/rstudio.deb && \
    #apt-get update && \
    #apt-get install -y --no-install-recommends /tmp/rstudio.deb && \
    rm /tmp/rstudio.deb && \
    #apt-get clean && \
    #rm -rf /var/lib/apt/lists/* && \
    # Set default CRAN mirror
    echo -e "local({\n r <- getOption('repos')\n r['CRAN'] <- 'https://cloud.r-project.org'\n  options(repos = r)\n })" > $R_HOME/etc/Rprofile.site && \
    \
    # Littler provides install2.r script
    R -e "install.packages(c('littler', 'docopt'))" && \
    \
    # Modify littler scripts to conda R location
    sed -i 's/\/${NB_USER}\/local\/lib\/R\/site-library/\/opt\/conda\/lib\/R\/library/g' \
        ${LITTLER}/examples/*.r && \
    ln -s ${LITTLER}/bin/r ${LITTLER}/examples/*.r /usr/local/bin/ && \
    echo "${R_HOME}/lib" | sudo tee -a /etc/ld.so.conf.d/littler.conf && \
    ldconfig && \
    fix-permissions ${CONDA_DIR} && \
    fix-permissions /home/${NB_USER}
###### END RStudio code ######


USER ${NB_USER}


###### START Jupyter code ######
# Jupyter notebook extensions & packages
RUN \
    pip install jupyter_contrib_nbextensions jupyter_nbextensions_configurator && \
    jupyter contrib nbextension install --sys-prefix && \
    jupyter nbextensions_configurator enable --sys-prefix && \
    \
    jupyter nbextension enable toc2/main --sys-prefix && \
    jupyter nbextension enable export_embedded/main --sys-prefix && \
    \
    pip install --pre rise && \
    jupyter nbextension install rise --py --sys-prefix && \
    jupyter nbextension enable rise --py --sys-prefix && \
    \
    pip install nbzip && \
    jupyter serverextension enable nbzip --py --sys-prefix && \
    jupyter nbextension install nbzip --py --sys-prefix && \
    jupyter nbextension enable nbzip --py --sys-prefix && \
    \
    pip install nbdime && \
    jupyter serverextension enable --py nbdime --sys-prefix && \
    jupyter nbextension install --py nbdime --sys-prefix && \
    jupyter nbextension enable --py nbdime --sys-prefix && \
    \
    pip install lightgbm pyarrow feather-format papermill nested-cv \
    openpyxl pyreadr networkx==2.5 joypy
    
RUN conda install -y -c conda-forge cartopy && \
#    conda clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Jupyter Lab extensions
RUN jupyter labextension install nbdime-jupyterlab

# Jupyter & RStudio
# from https://github.com/dddlab/docker-notebooks/blob/master/python-rstudio-notebook/Dockerfile
RUN pip install jupyter-server-proxy jupyter-rsession-proxy && \
    \
    # Remove cache
    rm -rf ~/.cache/pip ~/.cache/matplotlib ~/.cache/yarn && \
    \
#   conda clean --all -f -y && \
    fix-permissions ${CONDA_DIR} && \
    fix-permissions /home/${NB_USER}
###### END Jupyter code ######
