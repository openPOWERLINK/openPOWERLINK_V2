/**
********************************************************************************
\file   system-c5socarm.c

\brief  System specific functions for Altera Cyclone-V ARM

The file implements the system specific functions for ARM on Altera Cyclone-V
used by the openPOWERLINK demo applications.

\ingroup module_app_common
*******************************************************************************/

/*------------------------------------------------------------------------------
Copyright (c) 2016, B&R Industrial Automation GmbH
Copyright (c) 2015, Kalycito Infotech Private Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holders nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
------------------------------------------------------------------------------*/

//------------------------------------------------------------------------------
// includes
//------------------------------------------------------------------------------
#include <sys/unistd.h>
#include <alt_timers.h>
#include <alt_globaltmr.h>
#include <alt_interrupt.h>
#include <alt_cache.h>
#include <alt_fpga_manager.h>
#include <alt_bridge_manager.h>
#include <alt_address_space.h>
#include <alt_mpu_registers.h>
#include <alt_clock_manager.h>

#include <system.h>

#include <oplk/oplk.h>
#include <trace/trace.h>
#include <system/system.h>
#include <sleep.h>

#if defined(CONFIG_USE_SYNCTHREAD)
#error "Sync thread is not supported on this target!"
#endif

//============================================================================//
//            G L O B A L   D E F I N I T I O N S                             //
//============================================================================//

//------------------------------------------------------------------------------
// const defines
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// module global vars
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// global function prototypes
//------------------------------------------------------------------------------

//============================================================================//
//            P R I V A T E   D E F I N I T I O N S                           //
//============================================================================//

//------------------------------------------------------------------------------
// const defines
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// local types
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// local vars
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// local function prototypes
//------------------------------------------------------------------------------
static int initializeFpga(void);
static int initializeTimer(void);
static int cleanupTimer(void);
#if defined(CONFIG_BOOT_FROM_SD)
static int initializeDriver(void);
#endif

//============================================================================//
//            P U B L I C   F U N C T I O N S                                 //
//============================================================================//

//------------------------------------------------------------------------------
/**
\brief  Initialize system

The function initializes important stuff on the system for openPOWERLINK to
work correctly.

\ingroup module_app_common
*/
//------------------------------------------------------------------------------
int system_init(void)
{
    tOplkError  oplkRet = kErrorOk;

    if (initializeTimer() != 0)
    {
        TRACE("General purpose timer module initialization failed!!\n");
        oplkRet = kErrorGeneralError;
        goto Exit;
    }

    // Initialize the HPS to FPGA bridges alone and not initializeFpga()
    if (alt_bridge_init(ALT_BRIDGE_LWH2F, NULL, NULL) != ALT_E_SUCCESS)
    {
        oplkRet = kErrorGeneralError;
        TRACE("LWH2F initialization failed!!\n");
        goto Exit;
    }

    if (alt_bridge_init(ALT_BRIDGE_H2F, NULL, NULL) != ALT_E_SUCCESS)
    {
        oplkRet = kErrorGeneralError;
        TRACE("H2F initialization failed!!\n");
        goto Exit;
    }

#if defined(CONFIG_BOOT_FROM_SD)
    // Initialize the driver processor
    if (initializeDriver() != 0)
    {
        TRACE("Initializing the driver failed!!\n");
        return -1;
    }
#endif

Exit:
    return oplkRet;
}

//------------------------------------------------------------------------------
/**
\brief  Shutdown system

The function shuts-down the system.

\ingroup module_app_common
*/
//------------------------------------------------------------------------------
void system_exit(void)
{
    alt_bridge_uninit(ALT_BRIDGE_H2F, NULL, NULL);
    alt_bridge_uninit(ALT_BRIDGE_LWH2F, NULL, NULL);
    cleanupTimer();
}

//------------------------------------------------------------------------------
/**
\brief  Return true if a termination signal has been received

The function can be used by the application to react on termination request.
On cyclone V ARM, this function only implemented as a stub.

\ingroup module_app_common
*/
//------------------------------------------------------------------------------
BOOL system_getTermSignalState(void)
{
    return FALSE;
}

//------------------------------------------------------------------------------
/**
\brief Sleep for the specified number of milliseconds

The function makes the calling thread sleep until the number of specified
milliseconds have elapsed.

\param[in]      milliSeconds_p      Number of milliseconds to sleep

\ingroup module_app_common
*/
//------------------------------------------------------------------------------
void system_msleep(unsigned int milliSeconds_p)
{
    msleep(milliSeconds_p);
}

//============================================================================//
//            P R I V A T E   F U N C T I O N S                               //
//============================================================================//
/// \name Private Functions
/// \{
//------------------------------------------------------------------------------
/**
\brief Initialize the FPGA from the hard processor system

The function initializes the FPGA, manager interface, data bridges and
configures the FPGA for operation.

\return The function returns an integer.
\retval 0                   Success
\retval -1                  Failure
*/
//------------------------------------------------------------------------------
static int initializeFpga(void)
{
    int             ret = 0;
    ALT_STATUS_CODE halRet = ALT_E_SUCCESS;

    /* initialize the FPGA control */
    if (alt_fpga_init() != ALT_E_SUCCESS)                       // initialize the FPGA manager
    {
        TRACE("FPGA interface initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    if (alt_fpga_state_get() == ALT_FPGA_STATE_POWER_OFF)   // check the FPGA state
    {
        TRACE("FPGA is powered off!!\n");
        ret = -1;
        goto Exit;
    }

    if (!alt_fpga_control_is_enabled())                     // check if CPU has the control of the FPGA control block
    {
        // if not acquire control
        halRet = alt_fpga_control_enable();
    }

    if (halRet != ALT_E_SUCCESS)
    {
        TRACE("FPGA interface control could not be acquired\n");
        ret = -1;
        goto Exit;
    }

    /* Program FPGA here if required */

    /* Enable the HPS-FPGA bridge */
    if (alt_bridge_init(ALT_BRIDGE_F2H, NULL, NULL) != ALT_E_SUCCESS)
    {
        TRACE("F2H initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    if (alt_bridge_init(ALT_BRIDGE_H2F, NULL, NULL) != ALT_E_SUCCESS)
    {
        TRACE("H2F initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    if (alt_bridge_init(ALT_BRIDGE_LWH2F, NULL, NULL) != ALT_E_SUCCESS)
    {
        TRACE("LWH2F initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    if (alt_addr_space_remap(ALT_ADDR_SPACE_MPU_ZERO_AT_BOOTROM,
                             ALT_ADDR_SPACE_NONMPU_ZERO_AT_OCRAM,
                             ALT_ADDR_SPACE_H2F_ACCESSIBLE,
                             ALT_ADDR_SPACE_LWH2F_ACCESSIBLE) != ALT_E_SUCCESS)
    {
        TRACE("FPGA address space remapping failed!!\n");
        ret = -1;
        goto Exit;
    }

Exit:
    return ret;
}

#if defined(CONFIG_BOOT_FROM_SD)
//------------------------------------------------------------------------------
/**
\brief Initialize the openPOWERLINK driver from the hard processor system

The function resets the driver processor, copies the driver binary to the
processor's memory and releases the processor out of reset.

\return The function returns an integer.
\retval 0                   Success
\retval -1                  Failure
*/
//------------------------------------------------------------------------------
static int initializeDriver(void)
{
    ALT_STATUS_CODE halRet = ALT_E_SUCCESS;
    /* Symbol name for the driver binary file contents linked in. */
    extern char     _binary_drv_daemon_bin_start;
    extern char     _binary_drv_daemon_bin_end;
    /* Use the above symbols to extract the driver binary information */
    const char*     driverBinary = &_binary_drv_daemon_bin_start;
    const UINT32    driverBinarySize = &_binary_drv_daemon_bin_end - &_binary_drv_daemon_bin_start;
    char*           driverExecutableStartAddress = (char*)DDR3_EMIF_0_BASE;

    // Trace the driver image information.
    TRACE("INFO: driver Image binary at %p.\n", driverBinary);
    TRACE("INFO: driver Image size is %u bytes.\n", driverBinarySize);
    TRACE("INFO: driver Executable start is %p\n", driverExecutableStartAddress);

    // Reset the driver processor
    halRet = alt_fpga_gpo_write(0x00000001, 0x00000000);
    if (halRet != ALT_E_SUCCESS)
        return -1;

    while (alt_fpga_gpi_read(0x00000001) == 0);

    // Copy the driver image
    memcpy(driverExecutableStartAddress, driverBinary, driverBinarySize);

    // Release the driver processor from reset
    halRet = alt_fpga_gpo_write(0x00000001, 0x00000001);
    if (halRet != ALT_E_SUCCESS)
        return -1;

    while (alt_fpga_gpi_read(0x00000001) != 0);

    return 0;
}
#endif

//------------------------------------------------------------------------------
/**
\brief Initialize the timer module

The function initializes the global timer and configures it to be used as
the user stack generic timer.

\return The function returns an integer.
\retval 0                   Success
\retval -1                  Failure
*/
//------------------------------------------------------------------------------
static int initializeTimer(void)
{
    int             ret = 0;
    ALT_STATUS_CODE halRet = ALT_E_SUCCESS;

    // initialize timer, only the 64 bit global timer is used
    halRet =  alt_globaltmr_init();
    if (halRet != ALT_E_SUCCESS)
    {
        TRACE("General purpose timer module initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    // set the comparator value to the maximum global timer value even though we do not use it
    // the 'alt_gpt_curtime_millisecs_get()' api uses this to determine current time
    if ((alt_globaltmr_autoinc_set(1) != ALT_E_SUCCESS) ||
        (alt_globaltmr_comp_set64(ALT_GLOBALTMR_MAX) != ALT_E_SUCCESS))
    {
        TRACE("Auto increment mode could not be enabled for this timer!\n");
    }

    // Check if the timer  is already running
    halRet = alt_gpt_tmr_is_running(ALT_GPT_CPU_GLOBAL_TMR);
    if (halRet == ALT_E_FALSE)
    {
        TRACE("Timer has to be started!\n");
        // timer is not running, so try to start it
        halRet =  alt_globaltmr_start();
    }
    else
    {
        if (halRet == ALT_E_BAD_ARG)
        {
            // this timer instance does not exist
            ret = -1;
            goto Exit;
        }
        else // if (retStatus == ALT_E_TRUE)
        {
            // timer is already running. try to reset it
            // retStatus = alt_gpt_tmr_reset(ALT_GPT_CPU_GLOBAL_TMR);
            // Do not do it as its not needed and we would require to set its mode
            // configuration again if we did
        }
    }

    // check if any of the previous 2 timer operation failed, it can not be
    // a bad instance as that is covered
    if (halRet != ALT_E_SUCCESS)
    {
        TRACE("Timer initialization failed!!\n");
        ret = -1;
        goto Exit;
    }

    TRACE("Timer Comparator Mode: %u, value: %lu",
          alt_globaltmr_is_comp_mode(),
          alt_globaltmr_comp_get64() - 1);
    TRACE("Timer Auto increment mode: %u, value: %u\n",
          alt_globaltmr_is_autoinc_mode(),
          alt_globaltmr_autoinc_get());

    // stop the comparison function for this timer
    if ((alt_globaltmr_autoinc_mode_stop() != ALT_E_SUCCESS) ||
        (alt_globaltmr_comp_mode_start() != ALT_E_SUCCESS))
    {
        TRACE("Timer mode could not be set\n");
        ret = -1;
        goto Exit;
    }

    TRACE("Timer Comparator Mode: %u, value: %lu",
          alt_globaltmr_is_comp_mode(),
          alt_globaltmr_comp_get64() - 1);
    TRACE("Timer Auto increment mode: %u, value: %u\n",
          alt_globaltmr_is_autoinc_mode(),
          alt_globaltmr_autoinc_get());

    // disable comparator interrupts from this timer
    if ((alt_globaltmr_int_disable() != ALT_E_SUCCESS) ||
        (alt_globaltmr_int_clear_pending() != ALT_E_SUCCESS))
    {
        TRACE("Timer IRQ could not be disabled\n");
        ret = -1;
        goto Exit;
    }

Exit:
    return ret;
}

//------------------------------------------------------------------------------
/**
\brief Uninitialize the timer module

The function uninitializes the global timer.

\return The function returns an integer.
\retval 0                   Success
\retval -1                  Failure
*/
//------------------------------------------------------------------------------
static int cleanupTimer(void)
{
    int             ret = 0;
    ALT_STATUS_CODE halRet = ALT_E_SUCCESS;

    halRet = alt_globaltmr_stop();

    if (halRet == ALT_E_SUCCESS)
        halRet = alt_globaltmr_uninit();

    if (halRet != ALT_E_SUCCESS)
        ret = -1;

    return ret;
}
/// \}
