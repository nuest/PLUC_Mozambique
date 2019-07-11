FROM python:3.7 AS builder

ENV PCRASTER_VERSION=4.2.1

RUN apt-get update \ 
  && apt-get install -y --no-install-recommends \
    cmake \
    gcc \
    g++ \
    git \
    qtbase5-dev \
    libncurses5-dev \
    libqwt-qt5-dev \
    libxerces-c-dev \
    libboost-all-dev \
    libgdal-dev \
    python3-numpy \
    python3-docopt

RUN pip install numpy docopt

# https://stackoverflow.com/a/51737820/261210
#RUN cd /usr/lib/x86_64-linux-gnu \
#  && ln -s libboost_python-py.so libboost_python-py3.so

# http://pcraster.geo.uu.nl/getting-started/pcraster-on-linux/
# starting from 4.2.x there are no more binaries - need to build here
WORKDIR /opt
RUN curl -LO http://pcraster.geo.uu.nl/pcraster/$PCRASTER_VERSION/pcraster-$PCRASTER_VERSION.tar.bz2 \
  && tar xf pcraster-$PCRASTER_VERSION.tar.bz2 && cd pcraster-$PCRASTER_VERSION \
  && mkdir build \
  && cd build \
  && cmake -DFERN_BUILD_ALGORITHM:BOOL=TRUE -DCMAKE_INSTALL_PREFIX:PATH=/opt/pcraster -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python .. \
  && cmake --build . \
  && make install

FROM python:3

COPY --from=builder /opt/pcraster /opt/pcraster

# Prerequisites > http://pcraster.geo.uu.nl/getting-started/pcraster-on-linux/prerequisites/
RUN apt-get update \ 
  && apt-get install -y --force-yes --no-install-recommends \
    lsb \
    libjpeg62 \
    ffmpeg \
  && apt-get clean

RUN pip install numpy matplotlib

ENV PATH=/opt/pcraster/bin:$PATH
ENV PYTHONPATH=/opt/pcraster/python:$PYTHONPATH

WORKDIR /pluc
COPY model/ .
COPY README.md README.md

ARG VERSION=dev
ARG VCS_URL
ARG VCS_REF
ARG BUILD_DATE

# Metadata http://label-schema.org/rc1/
LABEL name=PLUC_MOZAMBIQUE \
      version=2 \
      maintainer="Daniel Nüst <daniel.nuest@uni-muenster.de>" \
      org.label-schema.vendor="Judith Verstegen, Daniel Nüst" \
      org.label-schema.url="http://o2r.info" \
      org.label-schema.name="PLUC Mozambique" \
      org.label-schema.description="PCRaster Land Use Change model (PLUC) for Mozambique, created in PCRaster (http://pcraster.geo.uu.nl/) in Python. \
      Results of the model are published in Verstegen et al. 2012 and van der Hilst et al. 2012." \
      org.label-schema.usage="/pluc/README.md" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="rc1" \
      org.label-schema.docker.cmd="docker run -it --name lu-moz pcraster-pluc"

ENTRYPOINT ["python"]
CMD ["LU_Moz.py"]
