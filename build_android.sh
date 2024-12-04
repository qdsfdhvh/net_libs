#!/bin/bash

if [ -f .env ]; then
    source .env
fi

ROOT=$PWD
SDK_VER=23

# Uncomment a set of variables to compile for 32bit or 64bit

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "ANDROID_NDK_ROOT is not set"
    exit 1
fi

#ABI="armeabi-v7a"
#BUILD_PATH="$ROOT/build/android32"
#OUT_PATH="$ROOT/out/android32"

ABI="arm64-v8a"
BUILD_PATH="$ROOT/build/android64"
OUT_PATH="$ROOT/out/android64"
DEPS_PATH="$ROOT/deps"

BORINGSSL_VERSION="0.20241203.0"
NGHTTP2_VERSION="v1.64.0"
NGTCP2_VERSION="1.9.1"
NGHTTP3_VERSION="1.6.0"
CURL_VERSION="8.11.0"

# Remove previous output files

rm -rf "$OUT_PATH"

# Build BoringSSL

if [ ! -d "$DEPS_PATH/boringssl-$BORINGSSL_VERSION" ]; then
    git clone --branch $BORINGSSL_VERSION --single-branch --depth 1 https://boringssl.googlesource.com/boringssl "$DEPS_PATH/boringssl-$BORINGSSL_VERSION"
fi

rm -rf "$BUILD_PATH/boringssl"
mkdir -p "$BUILD_PATH/boringssl"
cd "$BUILD_PATH/boringssl"

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUT_PATH" -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$ABI -DANDROID_PLATFORM=android-$SDK_VER "$DEPS_PATH/boringssl-$BORINGSSL_VERSION"
make -j$(nproc)
make install
make clean


# Build nghttp2

if [ ! -d "$DEPS_PATH/nghttp2-$NGHTTP2_VERSION" ]; then
    git clone --branch $NGHTTP2_VERSION --single-branch --depth 1 https://github.com/nghttp2/nghttp2 "$DEPS_PATH/nghttp2-$NGHTTP2_VERSION"
fi

rm -rf "$BUILD_PATH/nghttp2"
mkdir -p "$BUILD_PATH/nghttp2"
cd "$BUILD_PATH/nghttp2"

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUT_PATH" -DENABLE_LIB_ONLY=ON -DENABLE_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$SDK_VER -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON "$DEPS_PATH/nghttp2-$NGHTTP2_VERSION"
make -j$(nproc)
make install
make clean


# Build nghttp3

if [ ! -d "$DEPS_PATH/nghttp3-$NGHTTP3_VERSION" ]; then
    curl -L https://github.com/ngtcp2/nghttp3/releases/download/v$NGHTTP3_VERSION/nghttp3-$NGHTTP3_VERSION.tar.gz -o "$DEPS_PATH/nghttp3-$NGHTTP3_VERSION.tar.gz"
    tar -xvf "$DEPS_PATH/nghttp3-$NGHTTP3_VERSION.tar.gz" -C "$DEPS_PATH"
    rm "$DEPS_PATH/nghttp3-$NGHTTP3_VERSION.tar.gz"
fi

rm -rf "$BUILD_PATH/nghttp3"
mkdir -p "$BUILD_PATH/nghttp3"
cd "$BUILD_PATH/nghttp3"

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUT_PATH" -DENABLE_LIB_ONLY=ON -DENABLE_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$SDK_VER -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON "$DEPS_PATH/nghttp3-$NGHTTP3_VERSION"
make -j$(nproc)
make install
make clean


# Build ngtcp2

if [ ! -d "$DEPS_PATH/ngtcp2-$NGTCP2_VERSION" ]; then
    curl -L https://github.com/ngtcp2/ngtcp2/releases/download/v$NGTCP2_VERSION/ngtcp2-$NGTCP2_VERSION.tar.gz -o "$DEPS_PATH/ngtcp2-$NGTCP2_VERSION.tar.gz"
    tar -xvf "$DEPS_PATH/ngtcp2-$NGTCP2_VERSION.tar.gz" -C "$DEPS_PATH"
    rm "$DEPS_PATH/ngtcp2-$NGTCP2_VERSION.tar.gz"
fi

rm -rf "$BUILD_PATH/ngtcp2"
mkdir -p "$BUILD_PATH/ngtcp2"
cd "$BUILD_PATH/ngtcp2"

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUT_PATH" \
    -DBUILD_TESTING=OFF \
    -DENABLE_OPENSSL=OFF \
    -DENABLE_BORINGSSL=ON \
    -DBORINGSSL_INCLUDE_DIR="$OUT_PATH/include" \
    -DBORINGSSL_LIBRARIES="$OUT_PATH/lib/libcrypto.a;$OUT_PATH/lib/libssl.a" \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$SDK_VER \
    -DENABLE_SHARED_LIB=OFF \
    -DENABLE_STATIC_LIB=ON \
    "$DEPS_PATH/ngtcp2-$NGTCP2_VERSION"
make -j$(nproc) check
make install
make clean


# Build curl

if [ ! -d "$DEPS_PATH/curl-$CURL_VERSION" ]; then
    curl -L https://curl.se/download/curl-$CURL_VERSION.tar.gz -o "$DEPS_PATH/curl-$CURL_VERSION.tar.gz"
    tar -xvf "$DEPS_PATH/curl-$CURL_VERSION.tar.gz" -C "$DEPS_PATH"
    rm "$DEPS_PATH/curl-$CURL_VERSION.tar.gz"
fi

rm -rf "$BUILD_PATH/curl"
mkdir -p "$BUILD_PATH/curl"
cd "$BUILD_PATH/curl"

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUT_PATH" \
    -DBUILD_CURL_EXE=OFF \
    -DCURL_USE_OPENSSL=ON \
    -DOPENSSL_INCLUDE_DIR="$OUT_PATH/include" \
    -DOPENSSL_CRYPTO_LIBRARY="$OUT_PATH/lib/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="$OUT_PATH/lib/libssl.a" \
    -DOPENSSL_LIBRARIES="$OUT_PATH/lib/libcrypto.a;$OUT_PATH/lib/libssl.a" \
    -DUSE_NGHTTP2=ON \
    -DNGHTTP2_INCLUDE_DIR="$OUT_PATH/include" \
    -DNGHTTP2_LIBRARY="$OUT_PATH/lib/libnghttp2.a" \
    -DNGHTTP3_INCLUDE_DIR="$OUT_PATH/include" \
    -DNGHTTP3_LIBRARY="$OUT_PATH/lib/libnghttp3.a" \
    -DUSE_NGTCP2=ON \
    -DNGTCP2_INCLUDE_DIR="$OUT_PATH/include" \
    -DNGTCP2_LIBRARY="$OUT_PATH/lib/libngtcp2.a" \
    -Dngtcp2_crypto_boringssl_LIBRARY="$OUT_PATH/lib/libngtcp2_crypto_boringssl.a" \
    -DNGTCP2_LIBRARIES="$OUT_PATH/lib/libngtcp2.a;$OUT_PATH/lib/libngtcp2_crypto_boringssl.a" \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$SDK_VER \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DCMAKE_EXE_LINKER_FLAGS="-lstdc++" "$DEPS_PATH/curl-$CURL_VERSION"
make -j$(nproc)
make install
make clean
