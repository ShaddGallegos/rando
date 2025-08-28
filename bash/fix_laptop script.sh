#!/bin/bash
set -e

echo "🔧 Fixing SBC_EXPORT macro in all headers..."
find . -name '*.h' -exec sed -i '/#define SBC_EXPORT/d' {} \;
find . -name '*.h' -exec sed -i '1i#ifndef SBC_EXPORT\n#if defined(_WIN32)\n#define SBC_EXPORT __declspec(dllexport)\n#else\n#define SBC_EXPORT __attribute__((visibility("default")))\n#endif\n#endif\n' {} \;

echo "🧼 Rebuilding libsbc..."
make clean
./configure
make
sudo make install

echo "📦 Installing build dependencies..."
sudo dnf install -y meson ninja-build gcc pkgconf-pkg-config wayland-devel libdrm-devel systemd-devel

echo "📚 Installing inih library..."
git clone https://github.com/benhoyt/inih.git
cd inih
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
cd ..

echo "📁 Cloning Wayland protocols..."
git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git

echo "📄 Copying missing protocol files..."
sudo mkdir -p /usr/share/wayland-protocols/staging/ext-image-capture-source
sudo cp wayland-protocols/staging/ext-image-capture-source/ext-image-capture-source-v1.xml /usr/share/wayland-protocols/staging/ext-image-capture-source/

sudo mkdir -p /usr/share/wayland-protocols/staging/ext-image-copy-capture
sudo cp wayland-protocols/staging/ext-image-copy-capture/ext-image-copy-capture-v1.xml /usr/share/wayland-protocols/staging/ext-image-copy-capture/

sudo mkdir -p /usr/share/wayland-protocols/staging/ext-foreign-toplevel-list
sudo cp wayland-protocols/staging/ext-foreign-toplevel-list/ext-foreign-toplevel-list-v1.xml /usr/share/wayland-protocols/staging/ext-foreign-toplevel-list/

echo "🧱 Building xdg-desktop-portal-wlr..."
cd xdg-desktop-portal-wlr
sed -i '/#include/s/^/#include <unistd.h>\n/' src/screencast/wlr_screencast.c
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
cd ..

echo "✅ All done! xdg-desktop-portal-wlr is installed and ready to use."

