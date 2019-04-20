################################################################################
#
# CMake configuration for openPOWERLINK MN application library on Altera ARM
#
# Copyright (c) 2015, Kalycito Infotech Private Limited.
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
# Include board specific settings file
INCLUDE(setalteraarmboardconfig)

# TODO Only source the options set during hardware build
SET_BOARD_CONFIGURATION(${CFG_COMPILE_LIB_MN_HW_LIB_DIR})

################################################################################
# Set paths
SET(ARCH_INSTALL_POSTFIX ${CFG_DEMO_BOARD_NAME}/${CFG_DEMO_NAME})

################################################################################
# Find boards support package
SET(ALT_BSP_DIR ${CFG_COMPILE_LIB_MN_HW_LIB_DIR}/bsp${CFG_HOST_NAME}/${CFG_HOST_NAME})

MESSAGE(STATUS "Searching for the board support package in ${ALT_BSP_DIR}")
IF(EXISTS ${ALT_BSP_DIR})
    SET(ALT_LIB_BSP_INC ${ALT_BSP_DIR}/include)
ELSE()
    MESSAGE(FATAL_ERROR "Board support package for board ${CFG_DEMO_BOARD_NAME} and demo ${CFG_DEMO_NAME} not found!")
ENDIF()

################################################################################
# Set architecture specific sources
SET(LIB_ARCH_SOURCES
                     ${TARGET_ALTERA_ARM_SOURCES}
                     ${TARGET_ALTERA_ARM_DUAL_SOURCES}
                     ${SDO_SOCKETWRAPPER_SOURCES}
   )

################################################################################
# Deactivate optimization for usleep
SET_SOURCE_FILES_PROPERTIES(${ARCH_SOURCE_DIR}/altera-c5socarm/sleep.c
                            PROPERTIES COMPILE_FLAGS "-O0")

################################################################################
# Set architecture specific includes
INCLUDE_DIRECTORIES(
                    ${ALT_LIB_BSP_INC}
                    ${ARCH_SOURCE_DIR}/altera-c5socarm
                    ${CONTRIB_SOURCE_DIR}/socketwrapper
                    ${CONTRIB_SOURCE_DIR}/dualprocshm/include
                    ${CFG_COMPILE_LIB_MN_HW_LIB_DIR}/include
                   )

################################################################################
# Set additional target specific compile flags
SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ALT_HOST_CFLAGS} -fmessage-length=0 -ffunction-sections -fdata-sections -fno-inline")

ADD_DEFINITIONS(-D__C5SOC__ -D__ALTERA_ARM__ -Dsoc_cv_av)
################################################################################


########################################################################
# Eclipse project files
GEN_ECLIPSE_FILE_LIST("${LIB_KERNEL_SOURCES}" "kernel" PART_ECLIPSE_FILE_LIST)
SET(ECLIPSE_FILE_LIST "${ECLIPSE_FILE_LIST} ${PART_ECLIPSE_FILE_LIST}")

GEN_ECLIPSE_FILE_LIST("${LIB_USER_SOURCES}" "user" PART_ECLIPSE_FILE_LIST)
SET(ECLIPSE_FILE_LIST "${ECLIPSE_FILE_LIST} ${PART_ECLIPSE_FILE_LIST}")

GEN_ECLIPSE_FILE_LIST("${LIB_COMMON_SOURCES}" "common" PART_ECLIPSE_FILE_LIST)
SET(ECLIPSE_FILE_LIST "${ECLIPSE_FILE_LIST} ${PART_ECLIPSE_FILE_LIST}")

GEN_ECLIPSE_FILE_LIST("${LIB_ARCH_SOURCES}" "arch" PART_ECLIPSE_FILE_LIST)
SET(ECLIPSE_FILE_LIST "${ECLIPSE_FILE_LIST} ${PART_ECLIPSE_FILE_LIST}")

GET_PROPERTY(LIBRARY_INCLUDES DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
GEN_ECLIPSE_INCLUDE_LIST("${LIBRARY_INCLUDES}" ECLIPSE_INCLUDE_LIST)

GET_PROPERTY(FLAG_LIST DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY COMPILE_DEFINITIONS)
GEN_ECLIPSE_FLAG_LIST("${FLAG_LIST}" ECLIPSE_FLAG_LIST)

CONFIGURE_FILE(${ALT_TOOLS_DIR}/eclipse/libproject.in ${PROJECT_BINARY_DIR}/.project @ONLY)
CONFIGURE_FILE(${ALT_TOOLS_DIR}/eclipse/libcproject.in ${PROJECT_BINARY_DIR}/.cproject @ONLY)
