`include "uvm_pkg.sv"
import uvm_pkg::*;

`include "m_axi_common.sv"
`include "master_top.v"
`include "m_axi_intf.sv"

typedef class m_axi_tx;
typedef class base_seq;
typedef class seq_wr;
typedef class m_axi_driver;
typedef class m_axi_mon;       
typedef class m_axi_sbd;
typedef class m_axi_agent;
typedef class m_axi_env;

`include "m_axi_tx.sv"
`include "m_axi_seq_lib.sv"
`include "m_axi_seq.sv"
`include "m_axi_driver.sv"
`include "m_axi_monitor.sv"
`include "m_axi_cov.sv"
`include "m_axi_sbd.sv"
`include "m_axi_agent.sv"
`include "m_axi_env.sv"
`include "m_axi_sva.sv" 
`include "test_lib.sv"
`include "top_tb.sv"
