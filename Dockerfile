# syntax=docker/dockerfile:1
FROM ubuntu:20.04
ARG username
WORKDIR /home/${username}
CMD ["bash"]
COPY . .

RUN apt-get update && \
    (apt-get install -y --no-install-recommends ansible apt-utils coreutils || \
    (apt-get clean && apt-get update && apt-get install -y --no-install-recommends ansible apt-utils coreutils)) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#RUN apt-get update
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -o Debug::pkgProblemResolver=yes qt5-default && apt-get clean && rm -rf /var/lib/apt/lists/*
#
#RUN apt-get update && apt-get install -y -o Debug::pkgProblemResolver=yes libboost-all-dev cmake && apt-get clean && rm -rf /var/lib/apt/lists/*
#
#RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
#    apt-get install -y -o Debug::pkgProblemResolver=yes python3-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
#
#RUN apt-get update && apt-get install -y -o Debug::pkgProblemResolver=yes libeigen3-dev bash tmux  && apt-get clean && rm -rf /var/lib/apt/lists/*
#RUN apt-get update && apt-get install -y -o Debug::pkgProblemResolver=yes gtkwave udev xsel && apt-get clean && rm -rf /var/lib/apt/lists/*
#
#RUN apt-get update && \
#    apt-get -y install build-essential clang curl python3.10 libserialport-dev bison flex libreadline-dev gawk tcl-dev libffi-dev git mercurial graphviz xdot pkg-config libftdi-dev && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


RUN ansible-playbook --extra-vars "username=${username}" ./playbook.yml
RUN echo 'alias radiant="LM_LICENSE_FILE=~/license.dat ~/lscc/radiant/2022.1/bin/lin64/radiant"' >> $HOME/.bashrc

RUN mkdir ~/github

# Install yosys
RUN cd github && git clone https://github.com/YosysHQ/yosys
RUN cd github/yosys && make config-gcc && make -j$(nproc)
USER root
RUN make install 
USER ${username}

# Install Amaranth
RUN pip3 install --user --upgrade pip
RUN cd ~/github
# slagernate repo includes CrossLink-NX vendor file:
RUN git clone https://github.com/slagernate/amaranth 
RUN cd amaranth && pip3 install --user --editable . 

# Rust
# Get Ubuntu packages
USER root
USER ${username}
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc

# ecpprog
RUN cd ~/github
RUN git clone https://github.com/gregdavill/ecpprog ecpprog
RUN cd ecpprog/ecpprog
RUN make
USER root
RUN make install
USER ${username}

# prjoxide
RUN git clone --recursive https://github.com/gatecat/prjoxide
RUN cd libprjoxide && cargo install --path prjoxide

# Nextpnr-nexus
RUN cd ~/github
RUN git clone --recursive https://github.com/YosysHQ/nextpnr
RUN cd nextpnr
RUN cmake -DARCH=nexus -DOXIDE_INSTALL_PREFIX=$HOME/.cargo .
RUN make -j8
USER root
RUN make install
USER ${username}


