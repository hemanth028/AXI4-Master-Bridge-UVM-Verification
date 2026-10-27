class m_axi_cov extends uvm_subscriber #(m_axi_tx);

    `uvm_component_utils(m_axi_cov)

    m_axi_tx tx;

    covergroup m_axi_cg;

        cp_rnw: coverpoint tx.user_rnw {
            bins write_trans = {1'b0};
            bins read_trans  = {1'b1};
        }

        cp_burst: coverpoint tx.user_burst {
            bins fixed_mode = {2'b00};
            bins incr_mode  = {2'b01};
            bins wrap_mode  = {2'b10};
        }

        cp_total_bytes: coverpoint tx.user_total_bytes {
            bins tiny_payload   = {[1:4]};
            bins small_payload  = {[5:16]};
            bins medium_payload = {[17:64]};
            bins large_payload  = {[65:128]};
        }

        cp_bresp: coverpoint tx.m_axi_bresp {
            bins okay_resp   = {2'b00};
            bins slverr_resp = {2'b10};
            bins decerr_resp = {2'b11};
        }

        cp_rresp: coverpoint tx.m_axi_rresp {
            bins okay_resp   = {2'b00};
            bins slverr_resp = {2'b10};
            bins decerr_resp = {2'b11};
        }
         cp_align: coverpoint tx.user_start_addr[1:0] {
            bins aligned   = {2'b00};
            bins unaligned = {[2'b01:2'b11]};
        }

        cp_cross4k: coverpoint ((tx.user_start_addr[11:0] + tx.user_total_bytes) > 4096) {
            bins no_cross = {1'b0};
            bins crosses  = {1'b1};
        }

        cp_wstrb: coverpoint tx.user_tx_wstrb iff (!tx.user_rnw) {
            bins all_bytes = {4'hF};
            bins partial   = {[4'h1:4'hE]};
            bins none      = {4'h0};
        }


        rnw_x_burst: cross cp_rnw, cp_burst;
        rnw_x_bytes: cross cp_rnw, cp_total_bytes;
        rnw_x_4k    : cross cp_rnw, cp_cross4k;
        burst_x_4k  : cross cp_burst, cp_cross4k;
        wr_x_bresp  : cross cp_rnw, cp_bresp { ignore_bins rd = binsof(cp_rnw.read_trans);  }
        rd_x_rresp  : cross cp_rnw, cp_rresp { ignore_bins wr = binsof(cp_rnw.write_trans); }

    endgroup : m_axi_cg


    // Constructor
    function new(string name = "m_axi_cov", uvm_component parent = null);
        super.new(name, parent);
        m_axi_cg = new();
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("COV",
                  "build_phase of coverage",
                  UVM_HIGH)
    endfunction


    virtual function void write(m_axi_tx t);
        tx = t;
        m_axi_cg.sample();

        `uvm_info("COV_SAMPLE",
                  $sformatf("Sampled coverage = %0.2f%%",
                            m_axi_cg.get_inst_coverage()),
                  UVM_HIGH)
    endfunction

endclass
