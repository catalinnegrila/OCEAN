#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

typedef uint64_t uint64;
typedef uint32_t uint32;
typedef int32_t int32;

#pragma pack(push)
#pragma pack(1)
struct rheader {
    uint64 size;
    uint64 rec_size;
    uint64 id;
    uint64 timemark;
    uint32 status;
    uint32 quality;
    uint32 hdss_mru_recs_cnt;
    uint32 ship_nav_recs_cnt;
    uint32 sbe38fwd_recs_cnt;
    uint32 sbe38aft_recs_cnt;
};

struct fheader_param {
    uint32 seq_length;
    uint32 samples_to_acquire;
    uint32 n_channels;
    uint32 sample_period;
    uint32 fclk0_freq;
    uint32 tx_map_period;
    uint32 n_tx_specs;
    uint32 rly_control;
    uint32 sync_mode;
    uint32 sync_modulus;
    uint32 mix_freq;
    uint32 n_power_amps;
    uint32 rx_hdf_deci_pin_slct;
    uint32 rx_hsp_card_slots;
    uint32 set_time_on_run;
    uint32 detect_flood;
    uint32 clk_wiz_phase;
    uint32 clk_wiz_duty_cycle;
};

struct fheader_txspecs {
    uint32 tx_num;
    uint32 start_time;
    uint32 carrier_freq0;
    uint32 carrier_freq1;
    uint32 tx_reps;
    uint32 tx_rep_period;
    uint32 bit_length;
    uint32 code_nbits;
    int32 code[32];
    uint32 code_reps;
    uint32 bit_smoothing_fact;
    uint32 power_stg_out_slct;
    uint32 dac_slct;
    uint32 gate_slct;
    uint32 tx_pre_gate_delay;
    uint32 tx_post_gate_delay;
    uint32 power_level;
};

struct fheader_fwriter {
    uint64 size;
    uint64 max_file_size;
    uint32 max_rec_num;
    uint32 raw1_rec_enable;
    uint32 raw2_rec_enable;
    uint32 log_rec_enable;
    uint64 log_file_size;
    char raw1_path[256];
    char raw2_path[256];
    char log_path[256];
    uint32 raw1_recs_written;
    uint32 raw2_recs_written;
};

struct fheader {
    uint64 size;
    char app_ver[64];
    char header_ver[32];
    char setup_ver[32];
    uint32 cntrl_ser_num;
    char runname[256];
    char runnotes[1024];
    fheader_param param;
    uint32 dummy;

    fheader_txspecs txspecs0;
    fheader_txspecs txspecs1;

    fheader_fwriter fwriter;
    
    
    uint64 rec_size;
    uint64 rec_header_size;
    
    //uint32 rec_count;
    uint64 rec_count;
    
    uint64 file_size;
    uint64 setup_file_size;
};
#pragma pack(pop)
//char setup_file

int main(int argc, const char * argv[]) {
    FILE* fp = fopen("/Users/catalin/Downloads/sonar/HDSS_50k_RR2403_20240415_231038.hdss_raw", "rb");
    //rheader rh;
    //fread(&rh, sizeof(rh), 1, fp);
    fheader fh;
    fread(&fh, sizeof(fh), 1, fp);
    size_t pos = ftell(fp);
    char* setup_file = (char*)malloc(fh.setup_file_size);
    fread(setup_file, fh.setup_file_size, 1, fp);
    free(setup_file);
    fclose(fp);
    return 0;
}
