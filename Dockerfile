FROM jupyter/scipy-notebook:ubuntu-22.04
LABEL maintainer="Alice Lepissier <alice.lepissier@gmail.com>"


###### START Binder code ######
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

# Copy contents to work directory
COPY . ${HOME}/work
USER root
RUN chown -R ${NB_UID} ${HOME}
###### END Binder code ######


USER root


###### START R code ######
# R pre-requisites
# https://cloud.r-project.org/bin/linux/ubuntu/
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    gnupg \
    ca-certificates \
    software-properties-common \
    dirmngr \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    # Add the signing key (by Michael Rutter) for these repos
    # To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
    # Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    # Add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
    # Here $(lsb_release -cs) detects version of Linux that is running
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Install R
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    r-recommended \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
###### END R code ######


###### Start RStudio code ######
# Install RStudio Server and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    psmisc \
    libssl-dev \
    libclang-dev \
    libpq5 \
    wget && \
    wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.06.1-524-amd64.deb && \
    dpkg -i rstudio-server-2023.06.1-524-amd64.deb && \
    apt-get install -f && \
    rm rstudio-server-2023.06.1-524-amd64.deb

# Set up RStudio Server configuration
RUN echo "www-port=8787" >> /etc/rstudio/rserver.conf && \
    echo "auth-none=1" >> /etc/rstudio/rserver.conf && \
    echo "server-user=${NB_USER}" >> /etc/rstudio/rserver.conf

# Ensure the RStudio Server runs as the notebook user
RUN usermod -aG sudo ${NB_USER} && \
    echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Expose RStudio on port 8787
EXPOSE 8787
##### END RStudio code ######


###### Start Jupyter code ######
# Configure R to work with Jupyter
# https://irkernel.github.io/installation/
RUN R -e "install.packages(c('IRkernel', 'ggplot2', 'dplyr', 'tidyr', 'shiny', 'rmarkdown'), repos='http://cran.rstudio.com/')" \
    && R -e "IRkernel::installspec(user = FALSE)"


# Jupyter Server & RStudio configuration
RUN pip install jupyter-server-proxy jupyter-rsession-proxy && \
    # Remove cache
    rm -rf ~/.cache/pip ~/.cache/matplotlib ~/.cache/yarn && \
    \
    conda clean --all -f -y && \
    fix-permissions ${CONDA_DIR} && \
    fix-permissions /home/${NB_USER}
##### END Jupyter code ######


# # Start RStudio server
# CMD ["sh", "-c", "jupyter notebook & rstudio-server start && tail -f /dev/null"]
# Run RStudio Server as the main command
# CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]

# Final setup
USER ${NB_USER}