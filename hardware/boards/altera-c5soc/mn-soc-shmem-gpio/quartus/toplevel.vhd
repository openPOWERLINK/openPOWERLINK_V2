
------------------------------------------------------------------------------
--Copyright (c) 2014, Kalycito Infotech Pvt Ltd
--All rights reserved.
--
--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:
--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of the copyright holders nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.
--
--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library libcommon;
use libcommon.global.all;

entity toplevel is
    generic (
        gBoardRev               :       string := "D"
    );
    port (
        -- FPGA peripherals ports
        fpga_dipsw_pio          : in    std_logic_vector (3 downto 0);
        fpga_button_pio         : in    std_logic_vector (1 downto 0);
        -- HPS memory controller ports
        hps_memory_mem_a        : out   std_logic_vector (14 downto 0);
        hps_memory_mem_ba       : out   std_logic_vector (2 downto 0);
        hps_memory_mem_ck       : out   std_logic;
        hps_memory_mem_ck_n     : out   std_logic;
        hps_memory_mem_cke      : out   std_logic;
        hps_memory_mem_cs_n     : out   std_logic;
        hps_memory_mem_ras_n    : out   std_logic;
        hps_memory_mem_cas_n    : out   std_logic;
        hps_memory_mem_we_n     : out   std_logic;
        hps_memory_mem_reset_n  : out   std_logic;
        hps_memory_mem_dq       : inout std_logic_vector (39 downto 0);
        hps_memory_mem_dqs      : inout std_logic_vector (4 downto 0);
        hps_memory_mem_dqs_n    : inout std_logic_vector (4 downto 0);
        hps_memory_mem_odt      : out   std_logic;
        hps_memory_mem_dm       : out   std_logic_vector (4 downto 0);
        hps_memory_oct_rzqin    : in    std_logic;
        -- HPS peripherals
        hps_emac1_TX_CLK        : out   std_logic;
        hps_emac1_TXD0          : out   std_logic;
        hps_emac1_TXD1          : out   std_logic;
        hps_emac1_TXD2          : out   std_logic;
        hps_emac1_TXD3          : out   std_logic;
        hps_emac1_RXD0          : in    std_logic;
        hps_emac1_MDIO          : inout std_logic;
        hps_emac1_MDC           : out   std_logic;
        hps_emac1_RX_CTL        : in    std_logic;
        hps_emac1_TX_CTL        : out   std_logic;
        hps_emac1_RX_CLK        : in    std_logic;
        hps_emac1_RXD1          : in    std_logic;
        hps_emac1_RXD2          : in    std_logic;
        hps_emac1_RXD3          : in    std_logic;
        hps_qspi_IO0            : inout std_logic;
        hps_qspi_IO1            : inout std_logic;
        hps_qspi_IO2            : inout std_logic;
        hps_qspi_IO3            : inout std_logic;
        hps_qspi_SS0            : out   std_logic;
        hps_qspi_CLK            : out   std_logic;
        hps_sdio_CMD            : inout std_logic;
        hps_sdio_D0             : inout std_logic;
        hps_sdio_D1             : inout std_logic;
        hps_sdio_CLK            : out   std_logic;
        hps_sdio_D2             : inout std_logic;
        hps_sdio_D3             : inout std_logic;
        hps_usb1_D0             : inout std_logic;
        hps_usb1_D1             : inout std_logic;
        hps_usb1_D2             : inout std_logic;
        hps_usb1_D3             : inout std_logic;
        hps_usb1_D4             : inout std_logic;
        hps_usb1_D5             : inout std_logic;
        hps_usb1_D6             : inout std_logic;
        hps_usb1_D7             : inout std_logic;
        hps_usb1_CLK            : in    std_logic;
        hps_usb1_STP            : out   std_logic;
        hps_usb1_DIR            : in    std_logic;
        hps_usb1_NXT            : in    std_logic;
        hps_spim0_CLK           : out   std_logic;
        hps_spim0_MOSI          : out   std_logic;
        hps_spim0_MISO          : in    std_logic;
        hps_spim0_SS0           : out   std_logic;
        hps_uart0_RX            : in    std_logic;
        hps_uart0_TX            : out   std_logic;
        hps_i2c0_SDA            : inout std_logic;
        hps_i2c0_SCL            : inout std_logic;
        hps_can0_RX             : in    std_logic;
        hps_can0_TX             : out   std_logic;
        hps_trace_CLK           : out   std_logic;
        hps_trace_D0            : out   std_logic;
        hps_trace_D1            : out   std_logic;
        hps_trace_D2            : out   std_logic;
        hps_trace_D3            : out   std_logic;
        hps_trace_D4            : out   std_logic;
        hps_trace_D5            : out   std_logic;
        hps_trace_D6            : out   std_logic;
        hps_trace_D7            : out   std_logic;
        hps_gpio_GPIO09         : inout std_logic;
        hps_gpio_GPIO35         : inout std_logic;
        hps_gpio_GPIO41         : inout std_logic;
        hps_gpio_GPIO42         : inout std_logic;
        hps_gpio_GPIO43         : inout std_logic;
        hps_gpio_GPIO44         : inout std_logic;
        -- FPGA SDRAM
       fpga_memory_mem_a        : out   std_logic_vector (14 downto 0);
       fpga_memory_mem_ba       : out   std_logic_vector (2 downto 0);
       fpga_memory_mem_ck       : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_ck_n     : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_cke      : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_cs_n     : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_dm       : out   std_logic_vector (3 downto 0);
       fpga_memory_mem_ras_n    : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_cas_n    : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_we_n     : out   std_logic_vector (0 downto 0);
       fpga_memory_mem_reset_n  : out   std_logic;
       fpga_memory_mem_dq       : inout std_logic_vector (31 downto 0);
       fpga_memory_mem_dqs      : inout std_logic_vector (3 downto 0);
       fpga_memory_mem_dqs_n    : inout std_logic_vector (3 downto 0);
       fpga_memory_mem_odt      : out   std_logic_vector (0 downto 0);
       fpga_oct_rzqin           : in    std_logic;
       -- FPGA clock and reset
       fpga_clk_50              : in    std_logic;
       PLNK_MII_TXEN            : out   std_logic_vector(1 downto 0);-- txEnable
       PLNK_MII_TXD             : out   std_logic_vector(7 downto 0);-- txData
       PLNK_PHY_CLK             : in    std_logic;
       PLNK_MII_TXCLK           : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- txClk
       PLNK_MII_RXERR           : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- rxError
       PLNK_MII_RXDV            : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- rxDataValid
       PLNK_MII_RXD             : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- rxData
       PLNK_MII_RXCLK           : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- rxClk
       PLNK_SMI_PHYRSTN         : out   std_logic_vector(0 downto 0);-- nPhyRst
       PLNK_SMI_CLK             : out   std_logic_vector(0 downto 0);-- clk
       PLNK_SMI_DIO             : inout std_logic_vector(0 downto 0)  := (others => 'X');-- dio
       -- POWERLINK LED module
       pcp_led                  : out   std_logic_vector (1 downto 0)
    );
end toplevel;

architecture rtl of toplevel is
  signal hps_fpga_reset_n       : std_logic;
  signal ddr3_afi_resetn        : std_logic;
  signal fpga_memory_mem_addr :  std_logic_vector (12 downto 0);

  signal clk50                  : std_logic;
  signal clk100                 : std_logic;
  signal pllLocked              : std_logic;

  signal h2f_cold_reset_n       : std_logic;
  signal h2f_gp_in              : std_logic_vector(31 downto 0);
  signal h2f_gp_out             : std_logic_vector(31 downto 0);

  signal miiTxClk               : std_logic_vector(1 downto 0);

  component mnSocShmemGpio is
        port (
            memory_mem_a                                        : out   std_logic_vector(14 downto 0);
            memory_mem_ba                                       : out   std_logic_vector(2 downto 0);
            memory_mem_ck                                       : out   std_logic;
            memory_mem_ck_n                                     : out   std_logic;
            memory_mem_cke                                      : out   std_logic;
            memory_mem_cs_n                                     : out   std_logic;
            memory_mem_ras_n                                    : out   std_logic;
            memory_mem_cas_n                                    : out   std_logic;
            memory_mem_we_n                                     : out   std_logic;
            memory_mem_reset_n                                  : out   std_logic;
            memory_mem_dq                                       : inout std_logic_vector(39 downto 0) := (others => 'X');
            memory_mem_dqs                                      : inout std_logic_vector(4 downto 0)  := (others => 'X');
            memory_mem_dqs_n                                    : inout std_logic_vector(4 downto 0)  := (others => 'X');
            memory_mem_odt                                      : out   std_logic;
            memory_mem_dm                                       : out   std_logic_vector(4 downto 0);
            memory_oct_rzqin                                    : in    std_logic := 'X';
            memory_fpga_mem_a                                   : out   std_logic_vector(12 downto 0);
            memory_fpga_mem_ba                                  : out   std_logic_vector(2 downto 0);
            memory_fpga_mem_ck                                  : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_ck_n                                : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_cke                                 : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_cs_n                                : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_dm                                  : out   std_logic_vector(3 downto 0);
            memory_fpga_mem_ras_n                               : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_cas_n                               : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_we_n                                : out   std_logic_vector(0 downto 0);
            memory_fpga_mem_reset_n                             : out   std_logic;
            memory_fpga_mem_dq                                  : inout std_logic_vector(31 downto 0) := (others => 'X');
            memory_fpga_mem_dqs                                 : inout std_logic_vector(3 downto 0)  := (others => 'X');
            memory_fpga_mem_dqs_n                               : inout std_logic_vector(3 downto 0)  := (others => 'X');
            memory_fpga_mem_odt                                 : out   std_logic_vector(0 downto 0);
            oct_rzqin                                           : in    std_logic := 'X';
            clk_50_clk                                          : in    std_logic := 'X';
            clk_100_clk                                         : in    std_logic := 'X';
            reset_reset_n                                       : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_TX_CLK                     : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD0                       : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD1                       : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD2                       : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD3                       : out   std_logic;
            hps_io_hps_io_emac1_inst_RXD0                       : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_MDIO                       : inout std_logic := 'X';
            hps_io_hps_io_emac1_inst_MDC                        : out   std_logic;
            hps_io_hps_io_emac1_inst_RX_CTL                     : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_TX_CTL                     : out   std_logic;
            hps_io_hps_io_emac1_inst_RX_CLK                     : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_RXD1                       : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_RXD2                       : in    std_logic := 'X';
            hps_io_hps_io_emac1_inst_RXD3                       : in    std_logic := 'X';
            hps_io_hps_io_qspi_inst_IO0                         : inout std_logic := 'X';
            hps_io_hps_io_qspi_inst_IO1                         : inout std_logic := 'X';
            hps_io_hps_io_qspi_inst_IO2                         : inout std_logic := 'X';
            hps_io_hps_io_qspi_inst_IO3                         : inout std_logic := 'X';
            hps_io_hps_io_qspi_inst_SS0                         : out   std_logic;
            hps_io_hps_io_qspi_inst_CLK                         : out   std_logic;
            hps_io_hps_io_sdio_inst_CMD                         : inout std_logic := 'X';
            hps_io_hps_io_sdio_inst_D0                          : inout std_logic := 'X';
            hps_io_hps_io_sdio_inst_D1                          : inout std_logic := 'X';
            hps_io_hps_io_sdio_inst_CLK                         : out   std_logic;
            hps_io_hps_io_sdio_inst_D2                          : inout std_logic := 'X';
            hps_io_hps_io_sdio_inst_D3                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D0                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D1                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D2                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D3                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D4                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D5                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D6                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_D7                          : inout std_logic := 'X';
            hps_io_hps_io_usb1_inst_CLK                         : in    std_logic := 'X';
            hps_io_hps_io_usb1_inst_STP                         : out   std_logic;
            hps_io_hps_io_usb1_inst_DIR                         : in    std_logic := 'X';
            hps_io_hps_io_usb1_inst_NXT                         : in    std_logic := 'X';
            hps_io_hps_io_spim0_inst_CLK                        : out   std_logic;
            hps_io_hps_io_spim0_inst_MOSI                       : out   std_logic;
            hps_io_hps_io_spim0_inst_MISO                       : in    std_logic := 'X';
            hps_io_hps_io_spim0_inst_SS0                        : out   std_logic;
            hps_io_hps_io_uart0_inst_RX                         : in    std_logic := 'X';
            hps_io_hps_io_uart0_inst_TX                         : out   std_logic;
            hps_io_hps_io_i2c0_inst_SDA                         : inout std_logic := 'X';
            hps_io_hps_io_i2c0_inst_SCL                         : inout std_logic := 'X';
            hps_io_hps_io_can0_inst_RX                          : in    std_logic := 'X';
            hps_io_hps_io_can0_inst_TX                          : out   std_logic;
            hps_io_hps_io_trace_inst_CLK                        : out   std_logic;
            hps_io_hps_io_trace_inst_D0                         : out   std_logic;
            hps_io_hps_io_trace_inst_D1                         : out   std_logic;
            hps_io_hps_io_trace_inst_D2                         : out   std_logic;
            hps_io_hps_io_trace_inst_D3                         : out   std_logic;
            hps_io_hps_io_trace_inst_D4                         : out   std_logic;
            hps_io_hps_io_trace_inst_D5                         : out   std_logic;
            hps_io_hps_io_trace_inst_D6                         : out   std_logic;
            hps_io_hps_io_trace_inst_D7                         : out   std_logic;
            hps_io_hps_io_gpio_inst_GPIO09                      : inout std_logic := 'X';
            hps_io_hps_io_gpio_inst_GPIO35                      : inout std_logic := 'X';
            hps_io_hps_io_gpio_inst_GPIO41                      : inout std_logic := 'X';
            hps_io_hps_io_gpio_inst_GPIO42                      : inout std_logic := 'X';
            hps_io_hps_io_gpio_inst_GPIO43                      : inout std_logic := 'X';
            hps_io_hps_io_gpio_inst_GPIO44                      : inout std_logic := 'X';
            hps_0_f2h_cold_reset_req_reset_n                    : in    std_logic := 'X';
            hps_0_f2h_debug_reset_req_reset_n                   : in    std_logic := 'X';
            hps_0_f2h_warm_reset_req_reset_n                    : in    std_logic := 'X';
            dipsw_pio_external_connection_export                : in    std_logic_vector(3 downto 0)  := (others => 'X');
            button_pio_external_connection_export               : in    std_logic_vector(1 downto 0)  := (others => 'X');
            ddr3_emif_0_status_local_init_done                  : out   std_logic;
            ddr3_emif_0_status_local_cal_success                : out   std_logic;
            ddr3_emif_0_status_local_cal_fail                   : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_mem_clk                 : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_write_clk               : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_locked                  : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_write_clk_pre_phy_clk   : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_addr_cmd_clk            : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_avl_clk                 : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_config_clk              : out   std_logic;
            --ddr3_emif_0_pll_sharing_pll_dr_clk                  : out   std_logic;
            --ddr3_emif_0_pll_sharing_pll_dr_clk_pre_phy_clk      : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_mem_phy_clk             : out   std_logic;
            ddr3_emif_0_pll_sharing_afi_phy_clk                 : out   std_logic;
            ddr3_emif_0_pll_sharing_pll_avl_phy_clk             : out   std_logic;
            ddr3_emif_0_global_reset_reset_n                    : in    std_logic := 'X';
            ddr3_emif_0_afi_reset_export_reset_n                : out   std_logic;
            ddr3_emif_0_pll_ref_clk_clk                         : in    std_logic := 'X';
            ddr3_emif_0_soft_reset_reset_n                      : in    std_logic := 'X';
            openmac_0_mii_txEnable                              : out   std_logic_vector(1 downto 0);
            openmac_0_mii_txData                                : out   std_logic_vector(7 downto 0);
            openmac_0_mii_txClk                                 : in    std_logic_vector(1 downto 0) := (others => 'X');
            openmac_0_mii_rxError                               : in    std_logic_vector(1 downto 0) := (others => 'X');
            openmac_0_mii_rxDataValid                           : in    std_logic_vector(1 downto 0) := (others => 'X');
            openmac_0_mii_rxData                                : in    std_logic_vector(7 downto 0) := (others => 'X');
            openmac_0_mii_rxClk                                 : in    std_logic_vector(1 downto 0) := (others => 'X');
            openmac_0_smi_nPhyRst                               : out   std_logic_vector(0 downto 0);
            openmac_0_smi_clk                                   : out   std_logic_vector(0 downto 0);
            openmac_0_smi_dio                                   : inout std_logic_vector(0 downto 0)  := (others => 'X');
            host_0_hps_0_h2f_gp_gp_in                           : in    std_logic_vector(31 downto 0) := (others => 'X');
            host_0_hps_0_h2f_gp_gp_out                          : out   std_logic_vector(31 downto 0);
            host_0_hps_0_h2f_cold_reset_reset_n                 : out   std_logic;
            pcp_0_cpu_resetrequest_resetrequest                 : in    std_logic                     := 'X';
            pcp_0_cpu_resetrequest_resettaken                   : out   std_logic;
            pcp_0_benchmark_pio_export                          : out   std_logic_vector(7 downto 0);
            powerlink_led_export                                : out   std_logic_vector(1 downto 0)
        );
    end component mnSocShmemGpio;

    -- PLL
    component pll
    PORT
    (
        refclk      : in  std_logic := '0';
        rst         : in  std_logic := '0';
        outclk_0    : out std_logic;
        outclk_1    : out std_logic;
        locked      : out std_logic
    );
   end component pll;

 begin

  -- Append 0 for MSB bits of DDR Memory
  fpga_memory_mem_a <= "00" & fpga_memory_mem_addr;

    soc_inst: component mnSocShmemGpio
        port map (
            --HPS External Memory
            memory_mem_a                          =>  hps_memory_mem_a,
            memory_mem_ba                         =>  hps_memory_mem_ba,
            memory_mem_ck                         =>  hps_memory_mem_ck,
            memory_mem_ck_n                       =>  hps_memory_mem_ck_n,
            memory_mem_cke                        =>  hps_memory_mem_cke,
            memory_mem_cs_n                       =>  hps_memory_mem_cs_n,
            memory_mem_ras_n                      =>  hps_memory_mem_ras_n,
            memory_mem_cas_n                      =>  hps_memory_mem_cas_n,
            memory_mem_we_n                       =>  hps_memory_mem_we_n,
            memory_mem_reset_n                    =>  hps_memory_mem_reset_n,
            memory_mem_dq                         =>  hps_memory_mem_dq,
            memory_mem_dqs                        =>  hps_memory_mem_dqs,
            memory_mem_dqs_n                      =>  hps_memory_mem_dqs_n,
            memory_mem_odt                        =>  hps_memory_mem_odt,
            memory_mem_dm                         =>  hps_memory_mem_dm,
            memory_oct_rzqin                      =>  hps_memory_oct_rzqin,
            --DIP Switch FPGA
            dipsw_pio_external_connection_export  =>  fpga_dipsw_pio,
            button_pio_external_connection_export =>  fpga_button_pio,
            hps_io_hps_io_emac1_inst_TX_CLK =>  hps_emac1_TX_CLK,
            hps_io_hps_io_emac1_inst_TXD0   =>  hps_emac1_TXD0,
            hps_io_hps_io_emac1_inst_TXD1   =>  hps_emac1_TXD1,
            hps_io_hps_io_emac1_inst_TXD2   =>  hps_emac1_TXD2,
            hps_io_hps_io_emac1_inst_TXD3   =>  hps_emac1_TXD3,
            hps_io_hps_io_emac1_inst_RXD0   =>  hps_emac1_RXD0,
            hps_io_hps_io_emac1_inst_MDIO   =>  hps_emac1_MDIO,
            hps_io_hps_io_emac1_inst_MDC    =>  hps_emac1_MDC,
            hps_io_hps_io_emac1_inst_RX_CTL =>  hps_emac1_RX_CTL,
            hps_io_hps_io_emac1_inst_TX_CTL =>  hps_emac1_TX_CTL,
            hps_io_hps_io_emac1_inst_RX_CLK =>  hps_emac1_RX_CLK,
            hps_io_hps_io_emac1_inst_RXD1   =>  hps_emac1_RXD1,
            hps_io_hps_io_emac1_inst_RXD2   =>  hps_emac1_RXD2,
            hps_io_hps_io_emac1_inst_RXD3   =>  hps_emac1_RXD3,
            hps_io_hps_io_qspi_inst_IO0     =>  hps_qspi_IO0,
            hps_io_hps_io_qspi_inst_IO1     =>  hps_qspi_IO1,
            hps_io_hps_io_qspi_inst_IO2     =>  hps_qspi_IO2,
            hps_io_hps_io_qspi_inst_IO3     =>  hps_qspi_IO3,
            hps_io_hps_io_qspi_inst_SS0     =>  hps_qspi_SS0,
            hps_io_hps_io_qspi_inst_CLK     =>  hps_qspi_CLK,
            hps_io_hps_io_sdio_inst_CMD     =>  hps_sdio_CMD,
            hps_io_hps_io_sdio_inst_D0      =>  hps_sdio_D0,
            hps_io_hps_io_sdio_inst_D1      =>  hps_sdio_D1,
            hps_io_hps_io_sdio_inst_CLK     =>  hps_sdio_CLK,
            hps_io_hps_io_sdio_inst_D2      =>  hps_sdio_D2,
            hps_io_hps_io_sdio_inst_D3      =>  hps_sdio_D3,
            hps_io_hps_io_usb1_inst_D0      =>  hps_usb1_D0,
            hps_io_hps_io_usb1_inst_D1      =>  hps_usb1_D1,
            hps_io_hps_io_usb1_inst_D2      =>  hps_usb1_D2,
            hps_io_hps_io_usb1_inst_D3      =>  hps_usb1_D3,
            hps_io_hps_io_usb1_inst_D4      =>  hps_usb1_D4,
            hps_io_hps_io_usb1_inst_D5      =>  hps_usb1_D5,
            hps_io_hps_io_usb1_inst_D6      =>  hps_usb1_D6,
            hps_io_hps_io_usb1_inst_D7      =>  hps_usb1_D7,
            hps_io_hps_io_usb1_inst_CLK     =>  hps_usb1_CLK,
            hps_io_hps_io_usb1_inst_STP     =>  hps_usb1_STP,
            hps_io_hps_io_usb1_inst_DIR     =>  hps_usb1_DIR,
            hps_io_hps_io_usb1_inst_NXT     =>  hps_usb1_NXT,
            hps_io_hps_io_spim0_inst_CLK    =>  hps_spim0_CLK,
            hps_io_hps_io_spim0_inst_MOSI   =>  hps_spim0_MOSI,
            hps_io_hps_io_spim0_inst_MISO   =>  hps_spim0_MISO,
            hps_io_hps_io_spim0_inst_SS0    =>  hps_spim0_SS0,
            hps_io_hps_io_uart0_inst_RX     =>  hps_uart0_RX,
            hps_io_hps_io_uart0_inst_TX     =>  hps_uart0_TX,
            hps_io_hps_io_i2c0_inst_SDA     =>  hps_i2c0_SDA,
            hps_io_hps_io_i2c0_inst_SCL     =>  hps_i2c0_SCL,
            hps_io_hps_io_can0_inst_RX      =>  hps_can0_RX,
            hps_io_hps_io_can0_inst_TX      =>  hps_can0_TX,
            hps_io_hps_io_trace_inst_CLK    =>  hps_trace_CLK,
            hps_io_hps_io_trace_inst_D0     =>  hps_trace_D0,
            hps_io_hps_io_trace_inst_D1     =>  hps_trace_D1,
            hps_io_hps_io_trace_inst_D2     =>  hps_trace_D2,
            hps_io_hps_io_trace_inst_D3     =>  hps_trace_D3,
            hps_io_hps_io_trace_inst_D4     =>  hps_trace_D4,
            hps_io_hps_io_trace_inst_D5     =>  hps_trace_D5,
            hps_io_hps_io_trace_inst_D6     =>  hps_trace_D6,
            hps_io_hps_io_trace_inst_D7     =>  hps_trace_D7,
            hps_io_hps_io_gpio_inst_GPIO09  =>  hps_gpio_GPIO09,
            hps_io_hps_io_gpio_inst_GPIO35  =>  hps_gpio_GPIO35,
            hps_io_hps_io_gpio_inst_GPIO41  =>  hps_gpio_GPIO41,
            hps_io_hps_io_gpio_inst_GPIO42  =>  hps_gpio_GPIO42,
            hps_io_hps_io_gpio_inst_GPIO43  =>  hps_gpio_GPIO43,
            hps_io_hps_io_gpio_inst_GPIO44  =>  hps_gpio_GPIO44,
            clk_50_clk                            =>  clk50,
            clk_100_clk                           =>  clk100,
            reset_reset_n                         =>  hps_fpga_reset_n,
            hps_0_f2h_cold_reset_req_reset_n      =>  cnInactivated,
            hps_0_f2h_debug_reset_req_reset_n     =>  cnInactivated,
            hps_0_f2h_warm_reset_req_reset_n      =>  cnInactivated,
            memory_fpga_mem_a                     =>  fpga_memory_mem_addr,
            memory_fpga_mem_ba                    =>  fpga_memory_mem_ba,
            memory_fpga_mem_ck                    =>  fpga_memory_mem_ck,
            memory_fpga_mem_ck_n                  =>  fpga_memory_mem_ck_n,
            memory_fpga_mem_cke                   =>  fpga_memory_mem_cke,
            memory_fpga_mem_cs_n                  =>  fpga_memory_mem_cs_n,
            memory_fpga_mem_dm                    =>  fpga_memory_mem_dm,
            memory_fpga_mem_ras_n                 =>  fpga_memory_mem_ras_n,
            memory_fpga_mem_cas_n                 =>  fpga_memory_mem_cas_n,
            memory_fpga_mem_we_n                  =>  fpga_memory_mem_we_n,
            memory_fpga_mem_reset_n               =>  fpga_memory_mem_reset_n,
            memory_fpga_mem_dq                    =>  fpga_memory_mem_dq,
            memory_fpga_mem_dqs                   =>  fpga_memory_mem_dqs,
            memory_fpga_mem_dqs_n                 =>  fpga_memory_mem_dqs_n,
            memory_fpga_mem_odt                   =>  fpga_memory_mem_odt,
            ddr3_emif_0_global_reset_reset_n      =>  cnInactivated,
            ddr3_emif_0_soft_reset_reset_n        =>  cnInactivated,
            ddr3_emif_0_afi_reset_export_reset_n  =>  ddr3_afi_resetn,
            ddr3_emif_0_pll_ref_clk_clk           =>  fpga_clk_50,
            oct_rzqin                             =>  fpga_oct_rzqin,
            openmac_0_mii_txEnable                =>  PLNK_MII_TXEN,
            openmac_0_mii_txData                  =>  PLNK_MII_TXD,
            openmac_0_mii_txClk                   =>  miiTxClk,
            openmac_0_mii_rxError                 =>  PLNK_MII_RXERR,
            openmac_0_mii_rxDataValid             =>  PLNK_MII_RXDV,
            openmac_0_mii_rxData                  =>  PLNK_MII_RXD,
            openmac_0_mii_rxClk                   =>  PLNK_MII_RXCLK,
            openmac_0_smi_nPhyRst                 =>  PLNK_SMI_PHYRSTN,
            openmac_0_smi_clk                     =>  PLNK_SMI_CLK,
            openmac_0_smi_dio                     =>  PLNK_SMI_DIO,
            host_0_hps_0_h2f_gp_gp_in             =>  h2f_gp_in,
            host_0_hps_0_h2f_gp_gp_out            =>  h2f_gp_out,
            host_0_hps_0_h2f_cold_reset_reset_n   =>  h2f_cold_reset_n,
            pcp_0_cpu_resetrequest_resetrequest   => not(hps_fpga_reset_n and h2f_gp_out(0)),
            pcp_0_cpu_resetrequest_resettaken     => h2f_gp_in(0),
            pcp_0_benchmark_pio_export            => open,
            powerlink_led_export                  => pcp_led
        );

    -- Remove NIOS out of reset after DDR3 and PLL ready to operate
    hps_fpga_reset_n <= pllLocked and ddr3_afi_resetn and h2f_cold_reset_n;

    -- Select Phy Tx clock source
    process(PLNK_PHY_CLK, PLNK_MII_TXCLK)
    begin
        case gBoardRev is
            when "C" =>
                miiTxClk    <= PLNK_MII_TXCLK;

            when "D" =>
                miiTxClk    <= PLNK_PHY_CLK & PLNK_PHY_CLK;

            when others =>
                assert (false) report "The board revision is unknown!" severity failure;
        end case;
    end process;

    -- PLL for Qsys
    pllInst : pll
        port map
        (
            refclk      => fpga_clk_50,
            rst         => cInactivated,
            outclk_0    => clk50,
            outclk_1    => clk100,
            locked      => pllLocked
        );
end rtl;
