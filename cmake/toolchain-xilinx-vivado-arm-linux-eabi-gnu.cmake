################################################################################
#
# CMake target configuration file for Xilinx ARM Linux Eabihf
#
# Copyright (c) 2016, Kalycito Infotech Pvt. Ltd.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holders nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
################################################################################

SET(XILINX_SDK_DIR /opt/Xilinx/SDK/2018.2 CACHE STRING "Xilinx SDK toolchain path")

################################################################################
# Name of the target platform
SET(CMAKE_SYSTEM ARM-linux-eabihf)
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR arm)

# Version of the system
SET(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
SET(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
SET(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
SET(CMAKE_ASM-ATT_COMPILER arm-linux-gnueabihf-as)

SET(CMAKE_FIND_ROOT_PATH ${XILINX_SDK_DIR}/gnu/aarch32/lin/gcc-arm-linux-gnueabi/arm-linux-gnueabihf/libc)
# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries in the target and build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
# for headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# cross compiler directives
SET(MAKE_KERNEL_ARCH arm)
SET(MAKE_KERNEL_CROSS_COMPILE ${XILINX_SDK_DIR}/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin/arm-linux-gnueabihf-)
