################################################################################
#
# CMake file for HAL where target is ARM
#
# Copyright (c) 2015, Kalycito Infotech Private Limited
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

################################################################################

################################################################################
# Set architecture specific sources and include directories

UNSET(LIB_HOST_ARCH_HAL_SRCS)
SET(LIB_HOST_ARCH_HAL_SRCS
            src/hwmgr/alt_address_space.c
            src/hwmgr/soc_cv_av/alt_bridge_manager.c
            src/hwmgr/alt_cache.c
            src/hwmgr/soc_cv_av/alt_clock_manager.c
            src/hwmgr/alt_dma_program.c
            src/hwmgr/alt_dma.c

            src/hwmgr/soc_cv_av/alt_fpga_manager.c
            src/hwmgr/alt_generalpurpose_io.c
            src/hwmgr/alt_globaltmr.c
            src/hwmgr/alt_i2c.c
            src/hwmgr/alt_interrupt.c
            src/hwmgr/alt_mmu.c

            src/hwmgr/soc_cv_av/alt_reset_manager.c
            src/hwmgr/soc_cv_av/alt_system_manager.c
            src/hwmgr/alt_timers.c
            src/hwmgr/alt_watchdog.c
    )

UNSET(LIB_HOST_ARCH_HAL_INCS)
SET(LIB_HOST_ARCH_HAL_INCS
            ${HOST_HWLIB_PATH}/include
            ${HOST_HWLIB_PATH}/include/soc_cv_av
    )

UNSET(LIB_HOST_ARCH_HAL_C_FLAGS)
SET(LIB_HOST_ARCH_HAL_C_FLAGS "-D__ALTERA_ARM__ -Dsoc_cv_av -O3 -Ofast -g -Wall -std=c99 " )
UNSET(ARCH_HOST_MODULE_NAME)
SET(ARCH_HOST_MODULE_NAME    ${CFG_HOST_NAME}_arm_a9_0)
