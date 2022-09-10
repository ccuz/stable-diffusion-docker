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

RUN apt-get install -y locales && locale-gen en_US.UTF-8 && \
    apt-get update && \
    apt-get install -y python3-pip python3-venv && \
    /usr/local/bin/python -m pip install --upgrade pip

ENV LANG "en_US.UTF-8"
ENV LANGUAGE "en_US.UTF-8"
#ENV LC_ALL "en_US.UTF-8"

# Make bash default docker shell instead of sh
RUN ["/bin/bash", "-c", "cp /bin/bash /bin/sh"]

USER stablediff
ENV PATH /home/stablediff/.local/bin:$PATH
WORKDIR /home/stablediff

RUN python3 -m venv ~/.venv --prompt stable-diffusion && \
    source ~/.venv/bin/activate

#RUN pip install pipenv -q
COPY requirements.txt /home/stablediff/requirements.txt
COPY constraints.txt /home/stablediff/constraints.txt
RUN pip install -r /home/stablediff/requirements.txt -c /home/stablediff/constraints.txt

VOLUME /home/stablediff/.conda

RUN mkdir -p /home/stablediff/code
VOLUME /home/stablediff/code

CMD ["--web"]
ENTRYPOINT ["python3", "scripts/dream.py"]
#ENTRYPOINT ["/bin/bash"]

## Build using:
# docker build -t stable-diffusion-wonder-venv -f ./venv.dockerfile .
## Run using either
# docker run -it -u stablediff -v ${PWD}:/home/stablediff/code -w /home/stablediff/code stable-diffusion-wonder-venv --web