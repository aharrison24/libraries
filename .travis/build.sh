#!/bin/bash
set -x

function logical_cpu_count() {
  if [[ $(uname) == 'Darwin' ]]; then
    local cpu_count=$(sysctl -n hw.ncpu)
  else
    local cpu_count=$(nproc)
  fi
  echo ${cpu_count}
}

if [ "$TRAVIS_OS_NAME" = "linux" ]; then
  sudo update-alternatives \
    --install /usr/bin/gcc gcc /usr/bin/gcc-5 90 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-5 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-5
  sudo update-alternatives \
    --install /usr/bin/clang clang /usr/bin/clang-3.8 90 \
    --slave /usr/bin/clang++ clang++ /usr/bin/clang++-3.8
  sudo update-alternatives --config gcc
  sudo update-alternatives --config clang
  if [ "$CXX" = "clang++" ]; then
      export PATH=/usr/bin:$PATH
  fi
fi

if [ -z "${coverage+xxx}" ]; then export coverage=FALSE; fi

mkdir build
cd build
conan install ./.. --build=missing

if [ ! -z "$flags" ]; then extra_flags="-D stlab_appended_flags=$flags"; fi
    
cmake -D CMAKE_BUILD_TYPE=$build_type $options $extra_flags ..
if [ $? -ne 0 ]; then exit 1; fi

make VERBOSE=1 -j$(logical_cpu_count)
if [ $? -ne 0 ]; then exit 1; fi

if $coverage; then lcov -c -i -b .. -d . -o Coverage.baseline; fi

ctest --output-on-failure -j$(logical_cpu_count)
if [ $? -ne 0 ]; then exit 1; fi

if $coverage; then
  lcov -c -d . -b .. -o Coverage.out
  lcov -a Coverage.baseline -a Coverage.out -o Coverage.lcov
fi;
