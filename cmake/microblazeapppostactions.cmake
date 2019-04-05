################################################################################
#
# CMake file for microblaze post build actions
#
# Copyright (c) 2016, Kalycito Infotech Private Limited.
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
# U S E R   O P T I O N S

# Elf verify enable
OPTION(XIL_VERIFY_ELF "Verify the executable after download" OFF)
MARK_AS_ADVANCED(XIL_VERIFY_ELF)

##############################################################################
# Set paths
SET(XIL_HW_SPEC ${CFG_HW_LIB_DIR}/hw_platform)

##############################################################################
# Demo post build action
ADD_CUSTOM_COMMAND(
    TARGET ${EXECUTABLE_NAME}
    POST_BUILD
    COMMAND mb-size ${EXECUTABLE_NAME} | tee "${PROJECT_NAME}.size"
    COMMAND arm-none-eabi-objcopy -I elf32-little -O elf32-little -R .local_memory -R .vectors.* ${EXECUTABLE_NAME} ${PROJECT_BINARY_DIR}/oplkdrv_daemon_o.elf
    COMMAND make create-bit
)

SET_DIRECTORY_PROPERTIES(PROPERTIES
                         ADDITIONAL_MAKE_CLEAN_FILES "${EXECUTABLE_NAME};${PROJECT_NAME}.size;${PROJECT_NAME}.elfcheck;${PROJECT_NAME}.mem;${PROJECT_NAME}.map"
                        )
################################################################################
# Set list of additional make clean files
SET(ADD_CLEAN_FILES ${ADD_CLEAN_FILES}
                    ${EXECUTABLE_NAME}
                    ${PROJECT_NAME}.size
                    ${PROJECT_BINARY_DIR}/oplkdrv_daemon_o.elf
   )

##############################################################################
# Add targets for the generating bitstream
ADD_CUSTOM_TARGET(
    create-bit
    COMMAND data2mem -bm ${XIL_HW_SPEC}/system_wrapper_bd.bmm -bt ${XIL_HW_SPEC}/system_wrapper.bit -bd ${PROJECT_BINARY_DIR}/oplkdrv_daemon.elf tag system_i_pcp -o b ${XIL_HW_SPEC}/download.bit
    WORKING_DIRECTORY ${XIL_HW_SPEC}
)

################################################################################
# Set architecture specific installation files
INSTALL(FILES ${XIL_HW_SPEC}/download.bit
              ${PROJECT_BINARY_DIR}/oplkdrv_daemon_o.elf
        DESTINATION ${ARCH_INSTALL_POSTFIX}
       )
