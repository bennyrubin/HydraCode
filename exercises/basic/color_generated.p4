header eth_type2_t {
  bit<16> value;
}
header variables_t {
  
}
header slices_preamble_t {
  bit<8> num_items_slices;
}
header slices_item_t {
  bit<32> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  hops_preamble_t hops_preamble;
  hops_item_t[4] hops;
  slices_preamble_t slices_preamble;
  slices_item_t[3] slices;
}
struct hydra_metadata_t {
  bit<8> num_list_items;
}
parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  state parse_eth_type {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition parse_hops_preamble;
  }
  state parse_hops_preamble
    {
    packet.extract(hydra_header.hops_preamble);
    hydra_metadata.num_list_items =
    hydra_header.hops_preamble.num_hops_items;
    transition select(hydra_metadata.num_list_items) {
      0: parse_slices_preamble;
      default: parse_hops;
    }
  }
  state parse_slices_preamble
    {
    packet.extract(hydra_header.slices_preamble);
    hydra_metadata.num_list_items =
    hydra_header.slices_preamble.num_slices_items;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_slices;
    }
  }
  state parse_hops
    {
    packet.extract(hydra_header.hops.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: parse_slices_preamble;
      default: parse_hops;
    }
  }
  state parse_slices
    {
    packet.extract(hydra_header.slices.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_slices;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              out hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.hops_preamble);
    packet.emit(hydra_header.hops);
    packet.emit(hydra_header.slices_preamble);
    packet.emit(hydra_header.slices);
  }
}
control initControl(in ingress_headers_t hdr,
                    inout checker_header_t checker_header,
                    inout checker_metadata_t checker_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    checker_metadata.variables.switch_slice = switch_slice;
  }
  table tb_init_cp_vars {
    key = {
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.checker_header_types.setValid();
    hydra_header.hydra_header_types.variables = 1w1;
    hydra_header.variables.setValid();
    hydra_header.variables.slices = 0;
  }
}
control telemetryControl(in ingress_headers_t hdr,
                         inout checker_header_t checker_header,
                         inout checker_metadata_t checker_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    checker_metadata.variables.switch_slice = switch_slice;
  }
  table tb_init_cp_vars {
    key = {
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.slicess.push_front(1);
    hydra_header.slicess[0].setValid();
    hydra_header.slicess[0].slices = 1;
  }
}
control checkerControl(in ingress_headers_t hdr,
                       inout checker_header_t checker_header,
                       inout checker_metadata_t checker_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    checker_metadata.variables.switch_slice = switch_slice;
  }
  table tb_init_cp_vars {
    key = {
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.eth_typ.setInvalid();
    hydra_header.hydra_header_types.setInvalid();
    hydra_header.hops_preamble.setInvalid();
    hydra_header.variables.setInvalid();
    bit<32> prev_slice = hydra_header.slices[0];
    bit<32> slice;
    if (hydra_header.slices[0].isValid())
      {
      slice = hydra_header.slices[0];
      if (prev_slice!=slice) {
        checker_metadata.reject0 = true;
      }
      prev_slice = slice;
      if (hydra_header.slices[1].isValid())
        {
        slice = hydra_header.slices[1];
        if (prev_slice!=slice) {
          checker_metadata.reject0 = true;
        }
        prev_slice = slice;
        if (hydra_header.slices[2].isValid())
          {
          slice = hydra_header.slices[2];
          if (prev_slice!=slice) {
            checker_metadata.reject0 = true;
          }
          prev_slice = slice;
        }
      }
    }
  }
}
