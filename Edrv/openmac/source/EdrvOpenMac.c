/*----------------------------------------------------------------------------
Copyright (c) 2009, B&R
Copyright (c) 2009, SYSTEC electronic GmbH
All rights reserved.

Redistribution and use in source and binary forms,
with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer
      in the documentation and/or other materials provided with the distribution.
    * Neither the name of the B&R nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
------------------------------------------------------------------------------

  Project:          openPOWERLINK with openMAC

  Description:      Ethernet Driver for openMAC

  $Revision$  $Date$

  Author:           Joerg Zelenka (zelenkaj)
                    D. Krueger, completely reworked

  State:            tested on openPOWERLINK V1.5.9

------------------------------------------------------------------------------
  History

 2009/03/24     zelenkaj    V1.0 implementation finished
 2009/03/26     zelenkaj    revised
 2009/08/14     d.k.        adapted to new Ethernet driver interface

----------------------------------------------------------------------------*/


#include "global.h"
#include "EplInc.h"
#include "edrv.h"
#include "Benchmark.h"

#include "system.h"     // FPGA system definitions
#include "omethlib.h"   // openMAC header

#include <sys/alt_cache.h>
#include <sys/alt_irq.h>
#include <alt_types.h>


//---------------------------------------------------------------------------
// defines
//---------------------------------------------------------------------------

//------------------------------------------------------
//--- set the system's base adr ---
// MAC / MII IP CORE
#define EDRV_MAC_BASE                   (void *)OPENMAC_0_REG_BASE
#define EDRV_MII_BASE                   (void *)OPENMAC_0_MII_BASE
#define EPL_MAC_TX_IRQ                  OPENMAC_0_REG_IRQ
#define EPL_MAC_RX_IRQ                  OPENMAC_0_RX_IRQ
//--- set the system's base adr ---


//--- set driver's MTU ---
#define EDRV_MAX_BUFFER_SIZE        1518
//--- set driver's MTU ---

//--- set driver's hooks pendings ---
//RX hook buffer pendings
// set to 0 if no buffer-pending is allowed
// set 1..n the max pending RX buffers
#define EDRV_MAX_PEN_SOA            0 //1 buffer (no pending)
#define EDRV_MAX_PEN_SOC            0 //1 buffer (no pending)
#define EDRV_MAX_PEN_PREQ           0 //1 buffer (no pending)
#define EDRV_MAX_PEN_ASND           12 //13 buffers (with pending)
#define EDRV_MAX_PEN_TOME           0 //1 buffer (no pending)
//--- set driver's hooks pendings ---
// 1 + 1 + 1 + 12 + 1 = 16
// so you need 16 buffers set next definition to the sum

//--- set driver's RX buffers ---
#define EDRV_MAX_RX_BUFFERS         16
//--- set driver's RX buffers ---

//--- set driver's filters ---
#define EDRV_MAX_FILTERS            16
//--- set driver's filters ---

//--- set driver's auto-response frames ---
#define EDRV_MAX_AUTO_RESPONSES     14
//--- set driver's auto-response frames ---

//RX FIFO (for executing ASnd RX frames)
//--- set FIFO size ---
#define EDRV_MAX_RX_FIFO_SIZE       16 //should be 2^n not bigger than 32 and
                                       //bigger than EDRV_MAX_PEN_ASND
//--- set FIFO size ---
//------------------------------------------------------

#define EDRV_RAM_BASE (void *)(EDRV_MAC_BASE + 0x0800)

#if EPL_MAC_RX_IRQ > EPL_MAC_TX_IRQ
    #warning RX IRQ should have a higher IRQ priority than TX!!!
#endif

#if EPL_MAC_RX_IRQ > 0
    #warning RX IRQ should have the highest IRQ priority!!!
#endif

#if (EDRV_MAX_RX_BUFFERS > 16)
	#error This MAC version can handle 16 rx buffers, not more!
#endif

#if (EDRV_MAX_RX_FIFO_SIZE < EDRV_MAX_PEN_ASND)
	#error The FIFO size was set to small. FIFO size > ASnd pendings
#endif

#if (EDRV_MAX_RX_FIFO_SIZE > 32)
    #undef EDRV_MAX_RX_FIFO_SIZE
    #define EDRV_MAX_RX_FIFO_SIZE 32 //FIFO max. 32 entries!
#endif

#define EDRV_MASK_RX_FIFO (EDRV_MAX_RX_FIFO_SIZE - 1) //for masking the indices



#if (EDRV_AUTO_RESPONSE == FALSE)
    #error Please enable EDRV_AUTO_RESPONSE in EplCfg.h!
#endif


// borrowed from omethlibint.h
#define GET_TYPE_BASE(typ, element, ptr)    \
    ((typ*)( ((size_t)ptr) - (size_t)&((typ*)0)->element ))


//---------------------------------------------------------------------------
// local types
//---------------------------------------------------------------------------

typedef struct _tEdrvInstance
{
    //EPL spec
    tEdrvInitParam          m_InitParam;

    //openMAC HAL Ethernet Driver
    ometh_config_typ        m_EthConf;
    OMETH_H                 m_hOpenMac;
    OMETH_HOOK_H            m_hHook;
    OMETH_FILTER_H          m_ahFilter[EDRV_MAX_FILTERS];

    phy_reg_typ*            m_pPhy;

    // auto-response Tx buffers
    tEdrvTxBuffer*          m_apTxBuffer[EDRV_MAX_FILTERS];

    //tx msg counter
    DWORD                     msgfree;
    DWORD                     msgsent;
    DWORD                     fulltxqueue;

    //tx space
/*
    //RX ASnd FIFO
    struct {
        tEdrvRxBuffer           fifo[EDRV_MAX_RX_FIFO_SIZE];
        DWORD                     i_wr;
        DWORD                     i_rd;
        DWORD                     mask;
        DWORD                     full;
        BYTE                      size;
    } RXFIFO;
*/

} tEdrvInstance;

//---------------------------------------------------------------------------
// prototypes
//---------------------------------------------------------------------------


// RX Hook function
static int EdrvRxHook(void *arg, ometh_packet_typ  *pPacket, OMETH_BUF_FREE_FCT  *pFct);

static void EdrvCbSendAck(ometh_packet_typ *pPacket, void *arg, unsigned long time);

static void EdrvRxInterruptHandler (void* pArg_p, alt_u32 dwInt_p);
static void EdrvTxInterruptHandler (void* pArg_p, alt_u32 dwInt_p);


//void asyncCall(void);


//---------------------------------------------------------------------------
// module globale vars
//---------------------------------------------------------------------------


static tEdrvInstance EdrvInstance_l;




//---------------------------------------------------------------------------
//
// Function:    EdrvInit
//
// Description:
//
// Parameters:  pEdrvInitParam_p    = pointer to struct including the init-parameters
//
// Returns:     Errorcode           = kEplSuccessful
//                                  = kEplNoResource
//
// State:
//
//---------------------------------------------------------------------------

tEplKernel EdrvInit(tEdrvInitParam * pEdrvInitParam_p)
{
tEplKernel      Ret = kEplSuccessful;
int             iRet;
int             i;
BYTE            abFilterMask[31],
                abFilterValue[31];


    printf("initalize Ethernet Driver for openMAC\n");
    memset(&EdrvInstance_l, 0, sizeof(EdrvInstance_l)); //reset driver struct

    EdrvInstance_l.m_InitParam = *pEdrvInitParam_p;

    printf("MAC adr: %.2X-%.2X-%.2X-%.2X-%.2X-%.2X\n",
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[0],
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[1],
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[2],
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[3],
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[4],
        EdrvInstance_l.m_InitParam.m_abMyMacAddr[5]);

    printf("init openMAC...");

    ////////////////////
    // initialize phy //
    ////////////////////
    EdrvInstance_l.m_pPhy = omethPhyInfo(EdrvInstance_l.m_hOpenMac, 0);
    //printf("Phy activation ... ");
    omethMiiControl(EDRV_MII_BASE, MII_CTRL_RESET);
    for(i=0;i<1000;i++);
    omethMiiControl(EDRV_MII_BASE, MII_CTRL_ACTIVE);
    for(i=0;i<1000;i++);
    omethMiiControl(EDRV_MII_BASE, MII_CTRL_RESET);
    for(i=0;i<1000;i++);
    omethMiiControl(EDRV_MII_BASE, MII_CTRL_ACTIVE);
    for(i=0;i<1000;i++);
    //printf("done\n");

    ////////////////////////////////
    // initialize ethernet driver //
    ////////////////////////////////
    omethInit();

    EdrvInstance_l.m_EthConf.adapter = 0; //adapter number
    EdrvInstance_l.m_EthConf.macType = OMETH_MAC_TYPE_01;    // more info in omethlib.h
    EdrvInstance_l.m_EthConf.mode = /*OMETH_MODE_FULLDUPLEX +*/
                       OMETH_MODE_HALFDUPLEX;   // supported modes

    EdrvInstance_l.m_EthConf.pPhyBase = EDRV_MII_BASE;
    EdrvInstance_l.m_EthConf.pRamBase = EDRV_RAM_BASE;
    EdrvInstance_l.m_EthConf.pRegBase = EDRV_MAC_BASE;

    EdrvInstance_l.m_EthConf.rxBuffers = EDRV_MAX_RX_BUFFERS;
    EdrvInstance_l.m_EthConf.rxMtu = EDRV_MAX_BUFFER_SIZE;

    EdrvInstance_l.m_hOpenMac = omethCreate(&EdrvInstance_l.m_EthConf);

    if (EdrvInstance_l.m_hOpenMac == 0)
    {
        Ret = kEplNoResource;
        printf(" error!\n");
        goto Exit;
    }

    //init driver struct
    EdrvInstance_l.fulltxqueue = 0;
    EdrvInstance_l.msgfree = 0;
    EdrvInstance_l.msgsent = 0;

/*
    //init RX FIFO
    EdrvInstance_l.RXFIFO.full = 0;
    EdrvInstance_l.RXFIFO.i_rd = 0;
    EdrvInstance_l.RXFIFO.i_wr = 0;
    EdrvInstance_l.RXFIFO.mask = EDRV_MASK_RX_FIFO;
    EdrvInstance_l.RXFIFO.size = EDRV_MAX_RX_FIFO_SIZE;
    for(i=0; i<EdrvInstance_l.RXFIFO.size; i++) {
        EdrvInstance_l.RXFIFO.fifo[i].m_BufferInFrame = kEdrvBufferLastInFrame;
        EdrvInstance_l.RXFIFO.fifo[i].m_NetTime.m_dwNanoSec = 0;
        EdrvInstance_l.RXFIFO.fifo[i].m_NetTime.m_dwSec = 0;
        EdrvInstance_l.RXFIFO.fifo[i].m_uiRxMsgLen = 0;
        EdrvInstance_l.RXFIFO.fifo[i].m_pbBuffer = NULL;
    }
*/

    // initialize the filters, so that they won't match any normal Ethernet frame
    EPL_MEMSET(abFilterMask, 0, sizeof(abFilterMask));
    EPL_MEMSET(abFilterMask, 0xFF, 6);
    EPL_MEMSET(abFilterValue, 0, sizeof(abFilterValue));

    // initialize RX hook
    EdrvInstance_l.m_hHook = omethHookCreate(EdrvInstance_l.m_hOpenMac, EdrvRxHook, 0); //last argument max. pending
    if (EdrvInstance_l.m_hHook == 0)
    {
        Ret = kEplNoResource;
        goto Exit;
    }

    for (i = 0; i < EDRV_MAX_FILTERS; i++)
    {
        EdrvInstance_l.m_ahFilter[i] = omethFilterCreate(EdrvInstance_l.m_hHook, (void*) i, abFilterMask, abFilterValue);
        if (EdrvInstance_l.m_ahFilter[i] == 0)
        {
            Ret = kEplNoResource;
            goto Exit;
        }

        omethFilterDisable(EdrvInstance_l.m_ahFilter[i]);

        if (i < EDRV_MAX_AUTO_RESPONSES)
        {
            // initialize the auto response for each filter ...
            iRet = omethResponseInit(EdrvInstance_l.m_ahFilter[i]);
            if (iRet != 0)
            {
                Ret = kEplNoResource;
                goto Exit;
            }

            // ... but disable it
            omethResponseDisable(EdrvInstance_l.m_ahFilter[i]);
        }
    }

    //Hook for all Packets addressed to this mac and not hooked by the others
    /* to configer a hook to get all packets that had not been hooked by the others
     *  set all filter mask bytes to zero and don't care the filter values
     */

    // $$$ d.k. this Filter will be necessary, if Virtual Ethernet driver is available
/*
    printf("Hook for this MAC...");
    memset(abFilterMask, 0, sizeof(abFilterMask));
    abFilterMask[0] = 0xFF; abFilterMask[1] = 0xFF; abFilterMask[2] = 0xFF;
	abFilterMask[3] = 0xFF; abFilterMask[4] = 0xFF; abFilterMask[5] = 0xFF;
    abFilterValue[0] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[0];
	abFilterValue[1] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[1];
	abFilterValue[2] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[2];
	abFilterValue[3] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[3];
	abFilterValue[4] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[4];
	abFilterValue[5] = EdrvInstance_l.m_InitParam.m_abMyMacAddr[5];

    Ret = initHook(&EdrvInstance_l.EthHooks.tome, tome_Hook, &EdrvInstance_l.EthFilters.tome,
                    abFilterMask, abFilterValue, EdrvInstance_l.EthHooksMaxPendings.tome);
    if(Ret == kEplSuccessful)
        printf(" done\n");
    else
        printf(" error!\n");
*/

    ///////////////////////////
    // start Ethernet Driver //
    ///////////////////////////
    omethStart(EdrvInstance_l.m_hOpenMac, TRUE);
    printf("Ethernet Driver started\n");

    ////////////////////
    // link NIOS' irq //
    ////////////////////
    if (alt_irq_register(EPL_MAC_RX_IRQ, EdrvInstance_l.m_hOpenMac, EdrvRxInterruptHandler))
    {
        Ret = kEplNoResource;
    }

    if (alt_irq_register(EPL_MAC_TX_IRQ, EdrvInstance_l.m_hOpenMac, EdrvTxInterruptHandler))
    {
        Ret = kEplNoResource;
    }

Exit:
    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:    receive Hook functions
//
// Description: these functions will be called out of the Interrupt, when the
//				received packet fits to the filter
//
// Parameters:  *arg (don't care)
//              *pPacket pointer to received packet
//              *pointer to free function (don't care)
//
// Returns:     0 if frame was used
//              -1 if frame was not used
//
// State:
//
//---------------------------------------------------------------------------

static int EdrvRxHook(void *arg, ometh_packet_typ  *pPacket, OMETH_BUF_FREE_FCT  *pFct)
{
tEdrvRxBuffer       rxBuffer;
unsigned int        uiIndex;

    BENCHMARK_MOD_01_SET(6);
    rxBuffer.m_BufferInFrame = kEdrvBufferLastInFrame;
    rxBuffer.m_pbBuffer = (BYTE *) &pPacket->data;
    rxBuffer.m_uiRxMsgLen = pPacket->length;
    rxBuffer.m_NetTime.m_dwNanoSec = 0;
    rxBuffer.m_NetTime.m_dwSec = 0;

    EdrvInstance_l.m_InitParam.m_pfnRxHandler(&rxBuffer); //pass frame to Powerlink Stack

    uiIndex = (unsigned int) arg;

    if (EdrvInstance_l.m_apTxBuffer[uiIndex] != NULL)
    {   // filter with auto-response frame triggered
        BENCHMARK_MOD_01_SET(5);
        // call Tx handler function from DLL
        EdrvInstance_l.m_InitParam.m_pfnTxHandler(EdrvInstance_l.m_apTxBuffer[uiIndex]);
        BENCHMARK_MOD_01_RESET(5);
    }

    BENCHMARK_MOD_01_RESET(6);

    return 0;
}

/*
//---------------------------------------------------------------------------
//
// Function:    asyncCall
//
// Description: This function should be called ot of a while loop
//				in the main-function. It executes the packets in the FIFO and
//				lets them free (buffer will be returned to the MAC).
//
// Parameters:  void
//
// Returns:     void
//
// State:
//
//---------------------------------------------------------------------------
void asyncCall(void) {
    while(EdrvInstance_l.RXFIFO.i_wr - EdrvInstance_l.RXFIFO.i_rd) {
        //pass frame to EPL Stack
        EdrvInstance_l.m_InitParam.m_pfnRxHandler(&EdrvInstance_l.RXFIFO.fifo[EdrvInstance_l.RXFIFO.i_rd & EdrvInstance_l.RXFIFO.mask]);
        //ack frame in MAC
        omethPacketFree( (ometh_packet_typ*)(EdrvInstance_l.RXFIFO.fifo[EdrvInstance_l.RXFIFO.i_rd & EdrvInstance_l.RXFIFO.mask].m_pbBuffer) - 4 );

        EdrvInstance_l.RXFIFO.i_rd++;
    }

    omethPeriodic();
}
*/

//---------------------------------------------------------------------------
//
// Function:    EdrvAllocTxMsgBuffer
//
// Description:
//
// Parameters:  pBuffer_p   = pointer to Buffer structure
//
// Returns:     Errorcode   = kEplSuccessful
//                          = kEplEdrvNoFreeBufEntry
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvAllocTxMsgBuffer       (tEdrvTxBuffer * pBuffer_p)
{
tEplKernel          Ret = kEplSuccessful;
ometh_packet_typ*   pPacket = NULL;

    if (pBuffer_p->m_uiMaxBufferLen > EDRV_MAX_BUFFER_SIZE)
    {
        Ret = kEplEdrvNoFreeBufEntry;
        goto Exit;
    }

    // malloc aligns each allocated buffer so every type fits into this buffer.
    // this means 8 Byte alignment.
    pPacket = (ometh_packet_typ*) alt_uncached_malloc(pBuffer_p->m_uiMaxBufferLen + sizeof (pPacket->length));
    if (pPacket == NULL)
    {
        Ret = kEplEdrvNoFreeBufEntry;
        goto Exit;
    }

    pPacket->length = pBuffer_p->m_uiMaxBufferLen;

    pBuffer_p->m_uiBufferNumber = EDRV_MAX_FILTERS;

    pBuffer_p->m_pbBuffer = (BYTE*) &pPacket->data;

Exit:
    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:    EdrvReleaseTxMsgBuffer
//
// Description:
//
// Parameters:  pBuffer_p   = pointer to Buffer structure
//
// Returns:     Errorcode   = kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvReleaseTxMsgBuffer     (tEdrvTxBuffer * pBuffer_p)
{
tEplKernel          Ret = kEplSuccessful;
ometh_packet_typ*   pPacket = NULL;

    if (pBuffer_p->m_uiBufferNumber < EDRV_MAX_FILTERS)
    {
        // disable auto-response
        omethResponseDisable(EdrvInstance_l.m_ahFilter[pBuffer_p->m_uiBufferNumber]);
    }

    if (pBuffer_p->m_pbBuffer == NULL)
    {
        Ret = kEplEdrvInvalidParam;
        goto Exit;
    }

    pPacket = GET_TYPE_BASE(ometh_packet_typ, data, pBuffer_p->m_pbBuffer);

    // mark buffer as free, before actually freeing it
    pBuffer_p->m_pbBuffer = NULL;

    alt_uncached_free(pPacket);

Exit:
    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:    EdrvUpdateTxMsgBuffer
//
// Description:
//
// Parameters:  pBuffer_p   = pointer to Buffer structure
//
// Returns:     Errorcode   = kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvUpdateTxMsgBuffer     (tEdrvTxBuffer * pBuffer_p)
{
tEplKernel          Ret = kEplSuccessful;
ometh_packet_typ*   pPacket = NULL;

    if (pBuffer_p->m_uiBufferNumber >= EDRV_MAX_FILTERS)
    {
        Ret = kEplEdrvInvalidParam;
        goto Exit;
    }

    pPacket = GET_TYPE_BASE(ometh_packet_typ, data, pBuffer_p->m_pbBuffer);

    pPacket->length = pBuffer_p->m_uiTxMsgLen;

    pPacket = omethResponseSet(EdrvInstance_l.m_ahFilter[pBuffer_p->m_uiBufferNumber], pPacket);
    if (pPacket == OMETH_INVALID_PACKET)
    {
        Ret = kEplNoResource;
        goto Exit;
    }

Exit:
    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:    EdrvSendTxMsg
//
// Description:
//
// Parameters:  pBuffer_p   = buffer descriptor to transmit
//
// Returns:     Errorcode   = kEplSuccessful
//                          = kEplEdrvNoFreeBufEntry
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvSendTxMsg              (tEdrvTxBuffer * pBuffer_p)
{
tEplKernel          Ret = kEplSuccessful;
ometh_packet_typ*   pPacket = NULL;
unsigned long       ulTxLength;

    if (pBuffer_p->m_uiBufferNumber < EDRV_MAX_FILTERS)
    {
        Ret = kEplEdrvInvalidParam;
        goto Exit;
    }

    pPacket = GET_TYPE_BASE(ometh_packet_typ, data, pBuffer_p->m_pbBuffer);

    pPacket->length = pBuffer_p->m_uiTxMsgLen;

    ulTxLength = omethTransmitArg(EdrvInstance_l.m_hOpenMac, pPacket,
                        EdrvCbSendAck, pBuffer_p);
    if (ulTxLength > 0)
    {
        EdrvInstance_l.msgsent++;
        Ret = kEplSuccessful;
    }
    else
    {
        Ret = kEplEdrvNoFreeBufEntry;
    }

Exit:
    return Ret;
}


tEplKernel EdrvChangeFilter(tEdrvFilter*    pFilter_p,
                            unsigned int    uiCount_p,
                            unsigned int    uiEntryChanged_p,
                            unsigned int    uiChangeFlags_p)
{
tEplKernel      Ret = kEplSuccessful;
unsigned int    uiIndex;
unsigned int    uiEntry;

    if (((uiCount_p != 0) && (pFilter_p == NULL))
        || (uiCount_p >= EDRV_MAX_AUTO_RESPONSES))
    {
        Ret = kEplEdrvInvalidParam;
        goto Exit;
    }

    if (uiEntryChanged_p >= uiCount_p)
    {   // no specific entry changed
        // -> all entries changed

        // at first, disable all filters in openMAC
        for (uiEntry = 0; uiEntry < EDRV_MAX_FILTERS; uiEntry++)
        {
            omethFilterDisable(EdrvInstance_l.m_ahFilter[uiEntry]);
            omethResponseDisable(EdrvInstance_l.m_ahFilter[uiEntry]);
        }

        for (uiEntry = 0; uiEntry < uiCount_p; uiEntry++)
        {
            // set filter value and mask
            for (uiIndex = 0; uiIndex < sizeof (pFilter_p->m_abFilterValue); uiIndex++)
            {
                omethFilterSetByteValue(EdrvInstance_l.m_ahFilter[uiEntry],
                                        uiIndex,
                                        pFilter_p[uiEntry].m_abFilterValue[uiIndex]);

                omethFilterSetByteMask(EdrvInstance_l.m_ahFilter[uiEntry],
                                       uiIndex,
                                       pFilter_p[uiEntry].m_abFilterMask[uiIndex]);
            }

            // set auto response
            if (pFilter_p[uiEntry].m_pTxBuffer != NULL)
            {
                EdrvInstance_l.m_apTxBuffer[uiEntry] = pFilter_p[uiEntry].m_pTxBuffer;

                // set buffer number of TxBuffer to filter entry
                pFilter_p[uiEntry].m_pTxBuffer->m_uiBufferNumber = uiEntry;
                EdrvUpdateTxMsgBuffer(pFilter_p[uiEntry].m_pTxBuffer);
                omethResponseEnable(EdrvInstance_l.m_ahFilter[uiEntry]);
            }

            if (pFilter_p[uiEntry].m_fEnable != FALSE)
            {   // enable the filter
                omethFilterEnable(EdrvInstance_l.m_ahFilter[uiEntry]);
            }
        }

    }
    else
    {   // specific entry should be changed

        if (((uiChangeFlags_p & (EDRV_FILTER_CHANGE_VALUE | EDRV_FILTER_CHANGE_MASK)) != 0)
            || (pFilter_p[uiEntryChanged_p].m_fEnable == FALSE))
        {   // disable this filter entry
            omethFilterDisable(EdrvInstance_l.m_ahFilter[uiEntryChanged_p]);

            if ((uiChangeFlags_p & EDRV_FILTER_CHANGE_VALUE) != 0)
            {   // filter value has changed
                for (uiIndex = 0; uiIndex < sizeof (pFilter_p->m_abFilterValue); uiIndex++)
                {
                    omethFilterSetByteValue(EdrvInstance_l.m_ahFilter[uiEntryChanged_p],
                                            uiIndex,
                                            pFilter_p[uiEntryChanged_p].m_abFilterValue[uiIndex]);
                }
            }

            if ((uiChangeFlags_p & EDRV_FILTER_CHANGE_MASK) != 0)
            {   // filter mask has changed
                for (uiIndex = 0; uiIndex < sizeof (pFilter_p->m_abFilterMask); uiIndex++)
                {
                    omethFilterSetByteMask(EdrvInstance_l.m_ahFilter[uiEntryChanged_p],
                                           uiIndex,
                                           pFilter_p[uiEntryChanged_p].m_abFilterMask[uiIndex]);
                }
            }
        }

        if (pFilter_p[uiEntryChanged_p].m_fEnable != FALSE)
        {   // enable the filter
            omethFilterEnable(EdrvInstance_l.m_ahFilter[uiEntryChanged_p]);
        }
    }

Exit:
    return Ret;
}



//---------------------------------------------------------------------------
//
// Function:    fctFree
//
// Description: function is needed by openMAC
//
// Parameters:  *pPacket ... packet which should be released
//
// Returns:     void
//
// State:
//
//---------------------------------------------------------------------------
static void EdrvCbSendAck(ometh_packet_typ *pPacket, void *arg, unsigned long time) {
    EdrvInstance_l.msgfree++;
    BENCHMARK_MOD_01_SET(1);
    EdrvInstance_l.m_InitParam.m_pfnTxHandler(arg);
    BENCHMARK_MOD_01_RESET(1);
}

//---------------------------------------------------------------------------
//
// Function:    EdrvShutdown
//
// Description: Shutdown the Ethernet controller
//
// Parameters:  void
//
// Returns:     Errorcode   = kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvShutdown(void) {
    printf("Shutdown Ethernet Driver... ");
    if(omethDestroy(EdrvInstance_l.m_hOpenMac) != 0) {
        printf("error\n");
        return kEplNoResource;
    }
    printf("done\n");

    return kEplSuccessful;
}

//---------------------------------------------------------------------------
//
// Function:    EdrvDefineRxMacAddrEntry
//
// Description: Set a multicast entry into the Ethernet controller
//
// Parameters:  pbMacAddr_p     = pointer to multicast entry to set
//
// Returns:     Errorcode       = kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvDefineRxMacAddrEntry (BYTE * pbMacAddr_p) {
    tEplKernel  Ret = kEplSuccessful;

    return Ret;
}

//---------------------------------------------------------------------------
//
// Function:    EdrvUndefineRxMacAddrEntry
//
// Description: Reset a multicast entry in the Ethernet controller
//
// Parameters:  pbMacAddr_p     = pointer to multicast entry to reset
//
// Returns:     Errorcode       = kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvUndefineRxMacAddrEntry (BYTE * pbMacAddr_p) {
tEplKernel  Ret = kEplSuccessful;

    return Ret;
}

//---------------------------------------------------------------------------
//
// Function:    EdrvTxMsgReady
//
// Description: starts copying the buffer to the ethernet controller's FIFO
//
// Parameters:  pbBuffer_p - bufferdescriptor to transmit
//
// Returns:     Errorcode - kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvTxMsgReady              (tEdrvTxBuffer * pBuffer_p)
{
    tEplKernel Ret = kEplSuccessful;

    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:    EdrvTxMsgStart
//
// Description: starts transmission of the ethernet controller's FIFO
//
// Parameters:  pbBuffer_p - bufferdescriptor to transmit
//
// Returns:     Errorcode - kEplSuccessful
//
// State:
//
//---------------------------------------------------------------------------
tEplKernel EdrvTxMsgStart              (tEdrvTxBuffer * pBuffer_p)
{
    tEplKernel Ret = kEplSuccessful;


    return Ret;
}


//---------------------------------------------------------------------------
//
// Function:     EdrvInterruptHandler
//
// Description:  interrupt handler
//
// Parameters:   void
//
// Returns:      void
//
// State:
//
//---------------------------------------------------------------------------

static void EdrvRxInterruptHandler (void* pArg_p, alt_u32 dwInt_p)
{
    omethRxIrqHandler(pArg_p);
}

static void EdrvTxInterruptHandler (void* pArg_p, alt_u32 dwInt_p)
{
    omethTxIrqHandler(pArg_p);
}

