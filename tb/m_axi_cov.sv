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

        rnw_x_burst: cross cp_rnw, cp_burst;
        rnw_x_bytes: cross cp_rnw, cp_total_bytes;

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
