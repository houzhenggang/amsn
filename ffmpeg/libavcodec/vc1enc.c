/*
 * VC-1 and WMV3 encoder
 * copyright (c) 2007 Denis Fortin
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "avcodec.h"
#include "common.h"
#include "msmpeg4data.h"
#include "vc1.h"
#include "vc1data.h"
#include "vc1enc.h"

#include "simple_idct.h"

/* msmpeg4 externs*/
extern void ff_msmpeg4_encode_block(MpegEncContext * s, DCTELEM * block, int n);
extern void ff_find_best_tables(MpegEncContext * s);
extern void ff_msmpeg4_code012(PutBitContext *pb, int n);

/**
 * Unquantize a block
 *
 * @param s Encoder context
 * @param block Block to quantize
 * @param n index of block
 * @param qscale quantizer scale
 */
void vc1_unquantize_c(MpegEncContext *s, DCTELEM *block, int n, int qscale)
{
    VC1Context * const t= s->avctx->priv_data;
    int i, level, nCoeffs, q;
    ScanTable scantable;

    if(s->pict_type == I_TYPE)
        scantable = s->intra_scantable;
    else {
        scantable = s->inter_scantable;
        if( P_TYPE == s->pict_type )
            for(i=0;i<64;i++)
                block[i] += 128;
    }

    nCoeffs= s->block_last_index[n];

    if (n < 4)
        block[0] *= s->y_dc_scale;
    else
        block[0] *= s->c_dc_scale;

    q = 2 * qscale + t->halfpq;

    for(i=1; i<= nCoeffs; i++) {
        int j= scantable.permutated[i];
        level = block[j];
        if (level) {
            level = level * q + t->pquantizer*(FFSIGN(block[j]) * qscale);
        }
        block[j]=level;
    }

    for(; i< 64; i++) {
        int j= scantable.permutated[i];
        block[j]=0;
    }

}


/**
 * Transform and quantize a block
 *
 * @param s Encoder Context
 * @param block block to encode
 * @param n block index
 * @param qscale quantizer scale
 * @param overflow
 *
 * @return last significant coeff in zz order
 */
int vc1_quantize_c(MpegEncContext *s, DCTELEM *block, int n, int qscale, int *overflow)
{
    VC1Context * const t= s->avctx->priv_data;
    const uint8_t *scantable;
    int q, i, j, level, last_non_zero, start_i;

    if( I_TYPE == s->pict_type ) {
        scantable = s->intra_scantable.scantable;
        last_non_zero = 0;
        start_i = 1;
    } else {
        scantable = s->inter_scantable.scantable;
        last_non_zero = -1;
        start_i = 0;
        if (s->mb_intra){
            for(i=0;i<64;i++)
                block[i] -= 128;
        }
    }

    s->dsp.vc1_fwd_trans_8x8(block);

    if (n < 4)
        q = s->y_dc_scale;
    else
        q = s->c_dc_scale;

    block[0] /= q;
    q = 2 * qscale + t->halfpq;

    for(i=63;i>=start_i;i--) {
        j = scantable[i];
        level =  (block[j] - t->pquantizer*(FFSIGN(block[j]) * qscale)) / q;
        if(level){
            last_non_zero = i;
            break;
        }
    }
    for(i=start_i; i<=last_non_zero; i++) {
        j = scantable[i];
        block[j] =  (block[j] - t->pquantizer*(FFSIGN(block[j]) * qscale)) / q ;
    }
    *overflow = 0;
    return last_non_zero;
}


/**
 * Intra picture MB layer bitstream encoder
 * @param s Mpeg encoder context
 * @param block macroblock to encode
 */
void vc1_intra_picture_encode_mb(MpegEncContext * s, DCTELEM block[6][64])
{
    int cbp, coded_cbp, i;
    uint8_t *coded_block;

    /* compute cbp */
    cbp = 0;
    coded_cbp = 0;
    for (i = 0; i < 6; i++) {
        int val, pred;
        val = (s->block_last_index[i] >= 1);
        cbp |= val << (5 - i);
        if (i < 4) {
            /* predict value for close blocks only for luma */
            pred = vc1_coded_block_pred(s, i, &coded_block);
            *coded_block = val;
            val = val ^ pred;
        }
        coded_cbp |= val << (5 - i);
    }
    put_bits(&s->pb,ff_msmp4_mb_i_table[coded_cbp][1],
             ff_msmp4_mb_i_table[coded_cbp][0]);//CBPCY

    //predict dc_val and dc_direction for each block

    //brute force test to switch ACPRED on/off
    put_bits(&s->pb,1,0);//ACPRED

    for (i = 0; i < 6; i++)
        ff_msmpeg4_encode_block(s, block[i], i);

    s->i_tex_bits += get_bits_diff(s);
    s->i_count++;
}



/**
 * MB layer bitstream encoder
 * @param s Mpeg encoder context
 * @param block macroblock to encode
 * @param motion_x x component of mv's macroblock
 * @param motion_y y component of mv's macroblock
 */
void ff_vc1_encode_mb(MpegEncContext * s, DCTELEM block[6][64],
                   int motion_x, int motion_y)
{
  if ( I_TYPE == s->pict_type ) {
        vc1_intra_picture_encode_mb(s, block);
  }
}




/**
 * Picture layer bitstream encoder for Simple and Main Profile
 * @param s Mpeg encoder context
 * @param picture_number number of the frame to encode
 */
void ff_vc1_encode_picture_header(MpegEncContext * s, int picture_number)
{
    VC1Context * const t= s->avctx->priv_data;

    ff_find_best_tables(s);

    if( t->finterpflag ) {
        t->interpfrm = 0;//INTERPFRM
        put_bits(&s->pb,1,t->interpfrm);
    }

    put_bits(&s->pb,2,picture_number);//FRMCNT

    if( t->rangered ){
        t->rangeredfrm = 0;//RANGEREDFRM
        put_bits(&s->pb,1,t->rangeredfrm);
    }

    if (s->pict_type == I_TYPE)
      put_bits(&s->pb,1,0);//PTYPE
    else if (s->pict_type == P_TYPE)
      put_bits(&s->pb,1,1);//PTYPE

    if (s->pict_type == I_TYPE)
      put_bits(&s->pb,7,50);//BF

    if(s->qscale > 8 ) {
        t->halfpq = 0;
    } else {
        t->halfpq = 1;
    }

    t->pqindex = s->qscale;
    put_bits(&s->pb,5,t->pqindex);//PQINDEX
    if( t->quantizer_mode == QUANT_FRAME_IMPLICIT){
        //TODO create table
    }

    if( t->pqindex <= 8 )
        put_bits(&s->pb,1,t->halfpq);//HALFQP

    t->pquantizer = 1;
    if (t->quantizer_mode == QUANT_FRAME_IMPLICIT)
        t->pquantizer = t->pqindex < 9;
    if (t->quantizer_mode == QUANT_NON_UNIFORM)
        t->pquantizer = 0;

    if( t->quantizer_mode == QUANT_FRAME_EXPLICIT )
        put_bits(&s->pb,1,t->pquantizer);//PQUANTIZER : NON_UNIFOMR 0 / UNIFORM 1

    if( t->extended_mv ) {
        t->mvrange = 0;
        put_bits(&s->pb,1,t->mvrange);//TODO fix this: num bits is not fixed
    }

    if( t->multires ) {
        t->respic = 0;
        put_bits(&s->pb,2,t->respic);
    }


    if (s->pict_type == P_TYPE) {
      /* TODO : Write P_TYPE header info */
      /* is read like this : */
#if 0
        if (v->pq < 5) v->tt_index = 0;
        else if(v->pq < 13) v->tt_index = 1;
        else v->tt_index = 2;

        lowquant = (v->pq > 12) ? 0 : 1;
        v->mv_mode = ff_vc1_mv_pmode_table[lowquant][get_unary(gb, 1, 4)];
        if (v->mv_mode == MV_PMODE_INTENSITY_COMP)
        {
            int scale, shift, i;
            v->mv_mode2 = ff_vc1_mv_pmode_table2[lowquant][get_unary(gb, 1, 3)];
            v->lumscale = get_bits(gb, 6);
            v->lumshift = get_bits(gb, 6);
            v->use_ic = 1;
            /* fill lookup tables for intensity compensation */
            if(!v->lumscale) {
                scale = -64;
                shift = (255 - v->lumshift * 2) << 6;
                if(v->lumshift > 31)
                    shift += 128 << 6;
            } else {
                scale = v->lumscale + 32;
                if(v->lumshift > 31)
                    shift = (v->lumshift - 64) << 6;
                else
                    shift = v->lumshift << 6;
            }
            for(i = 0; i < 256; i++) {
                v->luty[i] = av_clip_uint8((scale * i + shift + 32) >> 6);
                v->lutuv[i] = av_clip_uint8((scale * (i - 128) + 128*64 + 32) >> 6);
            }
        }
        if(v->mv_mode == MV_PMODE_1MV_HPEL || v->mv_mode == MV_PMODE_1MV_HPEL_BILIN)
            v->s.quarter_sample = 0;
        else if(v->mv_mode == MV_PMODE_INTENSITY_COMP) {
            if(v->mv_mode2 == MV_PMODE_1MV_HPEL || v->mv_mode2 == MV_PMODE_1MV_HPEL_BILIN)
                v->s.quarter_sample = 0;
            else
                v->s.quarter_sample = 1;
        } else
            v->s.quarter_sample = 1;
        v->s.mspel = !(v->mv_mode == MV_PMODE_1MV_HPEL_BILIN || (v->mv_mode == MV_PMODE_INTENSITY_COMP && v->mv_mode2 == MV_PMODE_1MV_HPEL_BILIN));

        if ((v->mv_mode == MV_PMODE_INTENSITY_COMP &&
                 v->mv_mode2 == MV_PMODE_MIXED_MV)
                || v->mv_mode == MV_PMODE_MIXED_MV)
        {
            status = bitplane_decoding(v->mv_type_mb_plane, &v->mv_type_is_raw, v);
            if (status < 0) return -1;
            av_log(v->s.avctx, AV_LOG_DEBUG, "MB MV Type plane encoding: "
                   "Imode: %i, Invert: %i\n", status>>1, status&1);
        } else {
            v->mv_type_is_raw = 0;
            memset(v->mv_type_mb_plane, 0, v->s.mb_stride * v->s.mb_height);
        }
        status = bitplane_decoding(v->s.mbskip_table, &v->skip_is_raw, v);
        if (status < 0) return -1;
        av_log(v->s.avctx, AV_LOG_DEBUG, "MB Skip plane encoding: "
               "Imode: %i, Invert: %i\n", status>>1, status&1);

        /* Hopefully this is correct for P frames */
        v->s.mv_table_index = get_bits(gb, 2); //but using ff_vc1_ tables
        v->cbpcy_vlc = &ff_vc1_cbpcy_p_vlc[get_bits(gb, 2)];

        if (v->dquant)
        {
            av_log(v->s.avctx, AV_LOG_DEBUG, "VOP DQuant info\n");
            vop_dquant_decoding(v);
        }

        v->ttfrm = 0; //FIXME Is that so ?
        if (v->vstransform)
        {
            v->ttmbf = get_bits1(gb);
            if (v->ttmbf)
            {
                v->ttfrm = ff_vc1_ttfrm_to_tt[get_bits(gb, 2)];
            }
        } else {
            v->ttmbf = 1;
            v->ttfrm = TT_8X8;
        }
#endif
    }


    if( t->pqindex<=8 ) {
        ff_msmpeg4_code012(&s->pb, s->rl_chroma_table_index%3);//TRANSACFRM (UV)
	if (s->pict_type == I_TYPE)
	  ff_msmpeg4_code012(&s->pb, s->rl_table_index%3); //TRANSACFRM2 (Y)
    } else {
        ff_msmpeg4_code012(&s->pb, s->rl_chroma_table_index);//TRANSACFRM (UV)
	if (s->pict_type == I_TYPE)
	  ff_msmpeg4_code012(&s->pb, s->rl_table_index); //TRANSACFRM2 (Y)
    }

    put_bits(&s->pb, 1, s->dc_table_index);//TRANSDCTAB

    s->esc3_level_length = 0;
    s->esc3_run_length = 0;

}


/**
 * Sequence layer bitstream encoder
 * @param t VC1 context
 */
void vc1_encode_ext_header(AVCodecContext *avctx, VC1Context *t)
{
    MpegEncContext * const s= &t->s;
    PutBitContext pb;
    init_put_bits(&pb, s->avctx->extradata, s->avctx->extradata_size);

    t->profile = PROFILE_SIMPLE;
    put_bits(&pb, 2, t->profile); //Profile
    if(t->profile == PROFILE_ADVANCED) {
        t->level = 2;
        put_bits(&pb, 3, t->level); //Level
        t->chromaformat = 1; //4:2:0
        put_bits(&pb, 2, t->chromaformat);
    } else {
        t->zz_8x4 = ff_vc1_simple_progressive_8x4_zz;
        t->zz_4x8 = ff_vc1_simple_progressive_4x8_zz;

        t->res_sm = 0; //reserved
        put_bits(&pb, 2, t->res_sm); //Unused
    }

    t->frmrtq_postproc = 7;
    put_bits(&pb, 3, t->frmrtq_postproc); //TODO: Q frame rate
    t->bitrtq_postproc = 31;
    put_bits(&pb, 5, t->bitrtq_postproc); //TODO: Q bit rate

    s->loop_filter = 0;//TODO: loop_filter
    put_bits(&pb, 1, s->loop_filter);

    if(t->profile < PROFILE_ADVANCED) {
      t->res_x8 = 0;
      t->multires = 0;
      t->res_fasttx = 1;

        put_bits(&pb, 1, t->res_x8); //Reserved
        put_bits(&pb, 1, t->multires); //Multires
        put_bits(&pb, 1, t->res_fasttx); //Reserved

        s->dsp.vc1_inv_trans_8x8 = ff_simple_idct;
        s->dsp.vc1_inv_trans_8x4 = ff_simple_idct84_add;
        s->dsp.vc1_inv_trans_4x8 = ff_simple_idct48_add;
        s->dsp.vc1_inv_trans_4x4 = ff_simple_idct44_add;
    }

    t->fastuvmc = 1;//TODO : FAST U/V MC
    put_bits(&pb, 1, t->fastuvmc);

    t->extended_mv = 0;//TODO : Extended MV
    put_bits(&pb, 1, t->extended_mv);

    t->dquant = 0;//TODO : MB dequant
    put_bits(&pb, 2, t->dquant);

    t->vstransform = 0;//TODO : Variable size transform
    put_bits(&pb, 1, t->vstransform);

    if (t->profile < PROFILE_ADVANCED) {
      t->res_transtab = 0;
        put_bits(&pb, 1, t->res_transtab); //Reserved
    }

    t->overlap = 0; //TODO : Overlap
    put_bits(&pb, 1, t->overlap);

    if (t->profile < PROFILE_ADVANCED) {
        s->resync_marker = 0;//TODO : Resync marker
        put_bits(&pb, 1, s->resync_marker);
        t->rangered = 0;// TODO: Range red
        put_bits(&pb, 1, t->rangered);
    }

    avctx->max_b_frames = s->max_b_frames = 0;
    put_bits(&pb, 3, s->max_b_frames); //Max B-frames

    t->quantizer_mode = QUANT_FRAME_IMPLICIT;
    put_bits(&pb, 2, t->quantizer_mode); //Quantizer

    if (t->profile < PROFILE_ADVANCED) {
        t->finterpflag = 0; //TODO : Frame interpol
	t->res_rtm_flag = 1;
        put_bits(&pb, 1, t->finterpflag);
        put_bits(&pb, 1, t->res_rtm_flag); //Reserved
    }
    flush_put_bits(&pb);
}


static int vc1_encode_init(AVCodecContext *avctx){
    VC1Context * const t= avctx->priv_data;
    MpegEncContext *s = &t->s;

    if(avctx->idct_algo==FF_IDCT_AUTO)
        avctx->idct_algo=FF_IDCT_VC1;

    if(MPV_encode_init(avctx) < 0)
        return -1;

    avctx->extradata_size = 32;
    avctx->extradata = av_mallocz(avctx->extradata_size + 10);
    s->dct_quantize = vc1_quantize_c;
    s->dct_unquantize_intra =
    s->dct_unquantize_inter = vc1_unquantize_c;

    vc1_encode_ext_header(avctx, t);

    return 0;
fail:
    return 1;

}

AVCodec wmv3_encoder = {
        "wmv3",
        CODEC_TYPE_VIDEO,
        CODEC_ID_WMV3,
        sizeof(VC1Context),
        vc1_encode_init,
        MPV_encode_picture,
        MPV_encode_end,
        .pix_fmts= (enum PixelFormat[]){PIX_FMT_YUV420P, -1},
};
