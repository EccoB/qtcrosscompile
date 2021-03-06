# Dockerfile for building a cross developing environment for Qt
# targeting Windows. It also builds the application in the current
# directory. The application will be statically linked against
# Qt.
#
# To build the environment invoke
#  docker build -t qt .
# in the directory of this file. This creates a docker image
# called "qt". Note that it will take a while if you are building
# this image the first time. The contained application will also
# be compiled (in principle the last step could be done within
# the running container).
#
# Once build, you can enter the container via
#  docker run qt -ti bash
#
# (c) 2014-2019 by Sebastian Bauer
#
# Note that Docker requires a relatively recent Linux kernel.
# 3.8 is the current minimum.
#


FROM debian:stable-slim

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
	autoconf \
	automake \
	autopoint \
	binutils \
	bison \
	build-essential \
	ca-certificates \
	clzip \
	cmake \
	debhelper \
	devscripts \
	fakeroot \
	flex \
	gcc \
	git \
	gperf \
	intltool \
	libgdk-pixbuf2.0-dev \
	libffi-dev \
	libgmp-dev \
	libmpc-dev \
	libmpfr-dev \
	libtool \
	libtool-bin \
	libz-dev \
	openssl \
	patch \
	pkg-config \
	p7zip-full \
	ruby \
	scons \
	subversion \
	texinfo \
	unzip \
	wget \
	lzip \
	unzip \
	curl \
	libssl-dev

# see http://stackoverflow.com/questions/10934683/how-do-i-configure-qt-for-cross-compilation-from-linux-to-windows-target

# Preapre and download cross development environment
RUN mkdir /build
WORKDIR  /build
RUN git clone https://github.com/mxe/mxe.git

#-------  Build cross environment --------------
# make qt MXE_TARGETS=i686-w64-mingw32.static   # MinGW-w64, 32-bit, static libs
# Other targets you can use:
# make qt MXE_TARGETS=x86_64-w64-mingw32.static # MinGW-w64, 64-bit, static libs
# make qt MXE_TARGETS=i686-w64-mingw32.shared   # MinGW-w64, 32-bit, shared libs
# https://stackoverflow.com/questions/10934683/how-do-i-configure-qt-for-cross-compilation-from-linux-to-windows-target

# This fails atm due to missing OpenSSL
# Configure with -DCMAKE_USE_OPENSSL=OFF to solve or install openSSL by libssl-dev
ARG shared

RUN if [ "e$shared" = "e" ] ; then \
	echo "Static Branch" && cd mxe && make qtbase ; else \
	echo "Shared Branch" && cd mxe && make qtbase MXE_TARGETS=i686-w64-mingw32.shared ; \
	fi

RUN if [ "e$shared" = "e" ] ; then \
	echo "static Branch" && cd mxe && make qtmultimedia ; else \
	echo "Shared Branch" && cd mxe && make qtmultimedia MXE_TARGETS=i686-w64-mingw32.shared ; \
	fi

# TODO: Cleanup all unneeded stuff to make a slim image

# Enhance path
ENV PATH /build/mxe/usr/bin:$PATH

# Add a qmake alias
RUN if [ "e$shared" = "e" ] ; then \
	echo "Static Branch" && ln -s /build/mxe/usr/bin/i686-w64-mingw32.static-qmake-qt5 /build/mxe/usr/bin/qmake ; else \
	echo "Shared Branch" && ln -s /build/mxe/usr/bin/i686-w64-mingw32.shared-qmake-qt5 /build/mxe/usr/bin/qmake ; \
	fi

##########################################################################
# Here the project specific workflow starts.
#
# Now copy the sources. They will become part of the image.

# Build qserialport

RUN mkdir /qtserialport
WORKDIR /qtserialport
RUN git clone git://code.qt.io/qt/qtserialport.git
RUN mkdir build
WORKDIR /qtserialport/build
RUN qmake ../qtserialport/qtserialport.pro

RUN if [ "e$shared" = "e" ] ; then \
	echo "Static Branch" && make && make install ; else \
	echo "Shared Branch" && make MXE_TARGETS=i686-w64-mingw32.shared && make install ; \
	fi

RUN mkdir /src
WORKDIR /src
