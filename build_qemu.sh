# Build qemu on macOS
#
# This script assume that ninja https://github.com/ninja-build/ninja/releases is downloaded and is accessible in $PATH.
# You can simply do
#     curl -L -o ninja-mac.zip https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-mac.zip
#     unzip ninja-mac.zip
#     mv ninja $HOME/usr/bin/
# Note that due to macOS security preventing opening unsigned Internet downloaded executable, you must open the folder
# where you extracted the ninja executable in Finder and double click on ninja.

buildDir=`pwd`
installDir=$HOME/usr   # Might make this script argument

# We are going to install all tools in `$HOME/usr` so first let us export PATH and other variables.
# It might be desirable to put the following two lines in `.zshrc`.

export PATH=$installDir/bin:$PATH
export PKG_CONFIG_PATH=$installDir/lib/pkgconfig
export CFLAGS="-isystem $installDir/include -L$installDir/usr/lib"
export CXXFLAGS="-isystem $installDir/include -L$installDir/usr/lib"
export LDFLAGS="-L$installDir/lib"

# Grab the sources
getSources() {
    curl -L -o pkgconfig-0.29.2.tar.gz https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz \
        -o libffi-3.4.2.tar.gz https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz \
        -o gettext-0.21.tar.gz https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz \
        -o glib-2.56.3.tar.xz https://download.gnome.org/sources/glib/2.56/glib-2.56.3.tar.xz \
        -o pixman-0.40.0.tar.gz https://cairographics.org/releases/pixman-0.40.0.tar.gz \
        -o qemu-7.1.0.tar.xz https://download.qemu.org/qemu-7.1.0.tar.xz
}

# Common build command for GNU software
configureThenMake() {
    ./configure --prefix=$installDir "$@"
    make && make install
}

getSources

# Extract source
for file in *.tar.*; do tar xzf "$file"; done

# Build and install the libs
cd $buildDir/pkgconfig-0.29.2 && configureThenMake
cd $buildDir/libffi-3.4.2 && configureThenMake
cd $buildDir/gettext-0.21 && configureThenMake
cd $buildDir/glib-2.56.3 && configureThenMake --with-pcre=internal
cd $buildDir/pixman-0.40.0 && configureThenMake
cd $buildDir/qemu-7.1.0 && configureThenMake --target-list=aarch64-softmmu
