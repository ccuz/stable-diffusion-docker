FROM python:3.8.5-buster

## https://docs.nvidia.com/cuda/wsl-user-guide/index.html#getting-started-with-cuda-on-wsl
RUN set -o errexit -o nounset \
    && echo "Downloading cuda" && wget --no-verbose --output-document=cuda-wsl-ubuntu.pin https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin \
    && wget --no-verbose --output-document=cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb \
    && mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600

RUN echo "Installing cuda" \
    && dpkg -i cuda-repo-wsl-ubuntu-11-7-local_11.7.0-1_amd64.deb \
    && cp /var/cuda-repo-wsl-ubuntu-11-7-local/cuda-B81839D3-keyring.gpg /usr/share/keyrings/ && cp /var/cuda-repo-wsl-ubuntu-11-7-local/cuda-B81839D3-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg \
    && apt-get update && apt-get -y install cuda

RUN set -o errexit -o nounset \
    && echo "Adding stablediff user and group" \
    && groupadd --system --gid 1000 stablediff \
    && useradd --system --gid stablediff --uid 1000 --shell /bin/bash --create-home stablediff \
    && mkdir /home/stablediff/.conda && mkdir /home/stablediff/bin \
    && chown --recursive stablediff:stablediff /home/stablediff

ARG MINICONDA_SHA256=3190da6626f86eee8abf1b2fd7a5af492994eb2667357ee4243975cdbb175d7a
RUN set -o errexit -o nounset \
    && echo "Downloading miniconda" && wget --no-verbose --output-document=miniconda3.sh https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh \
    && echo "Checksum miniconda" && echo "${MINICONDA_SHA256} *miniconda3.sh" | sha256sum --check - \
    && echo "Install miniconda" && chmod a+x ./miniconda3.sh && ./miniconda3.sh -b -p /home/stablediff/bin/miniconda \
    && chmod a+rx /home/stablediff/bin/miniconda && chown -R stablediff /home/stablediff/bin

USER stablediff
ENV PATH /home/stablediff/bin/miniconda/bin:$PATH
WORKDIR /home/stablediff

VOLUME /home/stablediff/.conda

COPY environment.yaml /home/stablediff/environment.yaml
COPY setup.py /home/stablediff/setup.py

RUN conda update -n base -c defaults conda \
    && conda env create -f environment.yaml \
    && echo "conda activate ldm" > ~/.bashrc

ENV CONDA_ENV_NAME ldm
#RUN /bin/bash --login -c "/home/stablediff/bin/miniconda/bin/conda init bash && source /home/stablediff/.bashrc && /home/stablediff/bin/miniconda/bin/conda activate ldm"
# see https://pythonspeed.com/articles/activate-conda-dockerfile/

RUN mkdir -p /home/stablediff/code
VOLUME /home/stablediff/code

COPY entrypoint.sh /home/stablediff/entrypoint.sh

CMD ["--web"]
ENTRYPOINT ["/home/stablediff/entrypoint.sh"]
#ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ldm", "python3", "scripts/dream.py"]
#ENTRYPOINT ["/bin/bash"]

## Build using:
# docker build -t stable-diffusion-wonder -f ./Dockerfile .
## Run using either
# docker run -it -u stablediff -v ${PWD}:/home/stablediff/code -w /home/stablediff/code stable-diffusion-wonder --web