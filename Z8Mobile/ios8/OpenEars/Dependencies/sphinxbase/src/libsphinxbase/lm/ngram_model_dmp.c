/* -*- c-basic-offset: 4; indent-tabs-mode: nil -*- */
/* ====================================================================
 * Copyright (c) 1999-2007 Carnegie Mellon University.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * This work was supported in part by funding from the Defense Advanced 
 * Research Projects Agency and the National Science Foundation of the 
 * United States of America, and the CMU Sphinx Speech Consortium.
 *
 * THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND 
 * ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
 * NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ====================================================================
 *
 */
/*
 * \file ngram_model_dmp.c DMP format language models
 *
 * Author: David Huggins-Daines <dhuggins@cs.cmu.edu>
 */

#import "oeassert.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

#include "ckd_alloc.h"
#include "pio.h"
#include "err.h"
#include "byteorder.h"
#include "listelem_alloc.h"

#include "ngram_model_dmp.h"

#import "RuntimeVerbosity.h"
#import <CoreFoundation/CoreFoundation.h>

static const char darpa_hdr[] = "Darpa Trigram LM";
static ngram_funcs_t ngram_model_dmp_funcs;
extern int verbose_pocketsphinx;
extern int verbose_cmuclmtk;

#define TSEG_BASE(m,b)		((m)->lm3g.tseg_base[(b)>>LOG_BG_SEG_SZ])
#define FIRST_BG(m,u)		((m)->lm3g.unigrams[u].bigrams)
#define FIRST_TG(m,b)		(TSEG_BASE((m),(b))+((m)->lm3g.bigrams[b].trigrams))

static unigram_t *
new_unigram_table(int32 n_ug)
{
    unigram_t *table;
    int32 i;

    table = ckd_calloc(n_ug, sizeof(unigram_t));
    for (i = 0; i < n_ug; i++) {
        table[i].prob1.f = -99.0;
        table[i].bo_wt1.f = -99.0;
    }
    return table;
}

ngram_model_t *
ngram_model_dmp_read(cmd_ln_t *config,
                     const char *file_name,
                     logmath_t *lmath)
{
    ngram_model_t *base;
    ngram_model_dmp_t *model;
    FILE *fp;
    int do_mmap, do_swap;
    int32 is_pipe;
    int32 i, j, k, vn, n, ts;
    int32 n_unigram;
    int32 n_bigram;
    int32 n_trigram;
    char str[1024];
    unigram_t *ugptr;
    bigram_t *bgptr;
    trigram_t *tgptr;
    char *tmp_word_str;
    char *map_base = NULL;
    size_t offset = 0;

    base = NULL;
    do_mmap = FALSE;
    if (config)
        do_mmap = cmd_ln_boolean_r(config, "-mmap");

    int numberoffails = 0; // we try twice if it doesn't work, but if the first try doesn't fail we don't try a second time.
    
    if ((fp = fopen_comp(file_name, "rb", &is_pipe)) == NULL) { // first try
        numberoffails++; // increment number of fails if we fail.
        CFDictionaryKeyCallBacks keyCallbacks = {0, NULL, NULL, CFCopyDescription, CFEqual, NULL}; 
        CFDictionaryValueCallBacks valueCallbacks  = {0, NULL, NULL, CFCopyDescription, CFEqual};
        CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, 
                                                                      &keyCallbacks, &valueCallbacks);
        
        CFStringRef path_cfstring = CFStringCreateWithCString(NULL, file_name, kCFStringEncodingUTF8) ;
        
        CFDictionaryAddValue(dictionary, CFSTR("Path"), path_cfstring);
        
        CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(), CFSTR("RequestToUnarchive"), NULL, dictionary, TRUE);
        
        CFRelease(path_cfstring);
        CFRelease(dictionary);
        
        usleep(4999); 
    }
    
    if(numberoffails > 0) { // We give this second round a try if the first one failed, but if it didn't, we don't do this.
        if ((fp = fopen_comp(file_name, "rb", &is_pipe)) == NULL) {
            E_ERROR("Dump file %s not found\n", file_name);
            goto error_out;
        }
    }
    
    if (is_pipe && do_mmap) {
        E_WARN("Dump file is compressed, will not use memory-mapped I/O\n");
        do_mmap = 0;
    }

    do_swap = FALSE;
    if (fread(&k, sizeof(k), 1, fp) != 1)
        goto error_out;
    if (k != strlen(darpa_hdr)+1) {
        SWAP_INT32(&k);
        if (k != strlen(darpa_hdr)+1) {
            E_ERROR("Wrong magic header size number %x: %s is not a dump file\n", k, file_name);
            goto error_out;
        }
        do_swap = 1;
    }
    if (fread(str, 1, k, fp) != (size_t) k) {
        E_ERROR("Cannot read header\n");
        goto error_out;
    }
    if (strncmp(str, darpa_hdr, k) != 0) {
        E_ERROR("Wrong header %s: %s is not a dump file\n", darpa_hdr);
        goto error_out;
    }

    if (do_mmap) {
        if (do_swap) {
            E_INFO
                ("Byteswapping required, will not use memory-mapped I/O for LM file\n");
            do_mmap = 0;
        }
        else {
            E_INFO("Will use memory-mapped I/O for LM file\n");
#ifdef __ADSPBLACKFIN__ /* This is true for both VisualDSP++ and uClinux. */
            E_FATAL("memory mapping is not supported at the moment.");
#else
#endif
        }
    }

    if (fread(&k, sizeof(k), 1, fp) != 1)
        goto error_out;
    if (do_swap) SWAP_INT32(&k);
    if (fread(str, 1, k, fp) != (size_t) k) {
        E_ERROR("Cannot read LM filename in header\n");
        goto error_out;
    }

    /* read version#, if present (must be <= 0) */
    if (fread(&vn, sizeof(vn), 1, fp) != 1)
        goto error_out;
    if (do_swap) SWAP_INT32(&vn);
    if (vn <= 0) {
        /* read and don't compare timestamps (we don't care) */
        if (fread(&ts, sizeof(ts), 1, fp) != 1)
            goto error_out;
        if (do_swap) SWAP_INT32(&ts);

        /* read and skip format description */
        for (;;) {
            if (fread(&k, sizeof(k), 1, fp) != 1)
                goto error_out;
            if (do_swap) SWAP_INT32(&k);
            if (k == 0)
                break;
            if (fread(str, 1, k, fp) != (size_t) k) {
                E_ERROR("Failed to read word\n");
                goto error_out;
            }
        }
        /* read model->ucount */
        if (fread(&n_unigram, sizeof(n_unigram), 1, fp) != 1)
            goto error_out;
        if (do_swap) SWAP_INT32(&n_unigram);
    }
    else {
        n_unigram = vn;
    }

    /* read model->bcount, tcount */
    if (fread(&n_bigram, sizeof(n_bigram), 1, fp) != 1)
        goto error_out;
    if (do_swap) SWAP_INT32(&n_bigram);
    if (fread(&n_trigram, sizeof(n_trigram), 1, fp) != 1)
        goto error_out;
    if (do_swap) SWAP_INT32(&n_trigram);
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {   
        E_INFO("ngrams 1=%d, 2=%d, 3=%d\n", n_unigram, n_bigram, n_trigram);
    }
    /* Allocate space for LM, including initial OOVs and placeholders; initialize it */
    model = ckd_calloc(1, sizeof(*model));
    base = &model->base;
    if (n_trigram > 0)
        n = 3;
    else if (n_bigram > 0)
        n = 2;
    else
        n = 1;
    ngram_model_init(base, &ngram_model_dmp_funcs, lmath, n, n_unigram);
    base->n_counts[0] = n_unigram;
    base->n_counts[1] = n_bigram;
    base->n_counts[2] = n_trigram;

    /* read unigrams (always in memory, as they contain dictionary
     * mappings that can't be precomputed, and also could have OOVs added) */
    model->lm3g.unigrams = new_unigram_table(n_unigram + 1);
    ugptr = model->lm3g.unigrams;
    for (i = 0; i <= n_unigram; ++i) {
        /* Skip over the mapping ID, we don't care about it. */
        if (fread(ugptr, sizeof(int32), 1, fp) != 1) {
            E_ERROR("Failed to read maping id %d\n", i);
            goto error_out;
        }
        /* Read the actual unigram structure. */
        if (fread(ugptr, sizeof(unigram_t), 1, fp) != 1)  {
            E_ERROR("Failed to read unigrams data\n");
            ngram_model_free(base);
            fclose_comp(fp, is_pipe);
            return NULL;
        }
        /* Byte swap if necessary. */
        if (do_swap) {
            SWAP_INT32(&ugptr->prob1.l);
            SWAP_INT32(&ugptr->bo_wt1.l);
            SWAP_INT32(&ugptr->bigrams);
        }
        /* Convert values to log. */
        ugptr->prob1.l = logmath_log10_to_log(lmath, ugptr->prob1.f);
        ugptr->bo_wt1.l = logmath_log10_to_log(lmath, ugptr->bo_wt1.f);
        E_DEBUG(2, ("ug %d: prob %d bo %d bigrams %d\n",
                    i, ugptr->prob1.l, ugptr->bo_wt1.l, ugptr->bigrams));
        ++ugptr;
    }
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) { 
        E_INFO("%8d = LM.unigrams(+trailer) read\n", n_unigram);
    }
    /* Now mmap() the file and read in the rest of the (read-only) stuff. */
    if (do_mmap) {
        offset = ftell(fp);

        /* Check for improper word alignment. */
        if (offset & 0x3) {
            E_WARN("-mmap specified, but trigram index is not word-aligned.  Will not memory-map.\n");
            do_mmap = FALSE;
        }
        else {
            model->dump_mmap = mmio_file_read(file_name);
            if (model->dump_mmap == NULL) {
                do_mmap = FALSE;
            }
            else {
                map_base = mmio_file_ptr(model->dump_mmap);
            }
        }
    }
    
    if (n_bigram > 0) {
        /* read bigrams */
	if (do_mmap) {
    	    model->lm3g.bigrams = (bigram_t *) (map_base + offset);
    	    offset += (n_bigram + 1) * sizeof(bigram_t);
	}
	else {
    	    model->lm3g.bigrams =
        	ckd_calloc(n_bigram + 1, sizeof(bigram_t));
    	    if (fread(model->lm3g.bigrams, sizeof(bigram_t), n_bigram + 1, fp)
        	!= (size_t) n_bigram + 1) {
    		E_ERROR("Failed to read bigrams data\n");
        	goto error_out;
    	    }
    	    if (do_swap) {
        	for (i = 0, bgptr = model->lm3g.bigrams; i <= n_bigram;
            	     i++, bgptr++) {
            	    SWAP_INT16(&bgptr->wid);
            	    SWAP_INT16(&bgptr->prob2);
            	    SWAP_INT16(&bgptr->bo_wt2);
            	    SWAP_INT16(&bgptr->trigrams);
        	}
    	    }
        }
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
            E_INFO("%8d = LM.bigrams(+trailer) read\n", n_bigram);
        }       
    }

    /* read trigrams */
    if (n_trigram > 0) {
        if (do_mmap) {
            model->lm3g.trigrams = (trigram_t *) (map_base + offset);
            offset += n_trigram * sizeof(trigram_t);
        }
        else {
            model->lm3g.trigrams =
                ckd_calloc(n_trigram, sizeof(trigram_t));
            if (fread
                (model->lm3g.trigrams, sizeof(trigram_t), n_trigram, fp)
                != (size_t) n_trigram) {
                E_ERROR("Failed to read trigrams data\n");
                goto error_out;
            }
            if (do_swap) {
                for (i = 0, tgptr = model->lm3g.trigrams; i < n_trigram;
                     i++, tgptr++) {
                    SWAP_INT16(&tgptr->wid);
                    SWAP_INT16(&tgptr->prob3);
                }
            }
        }
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {      
            E_INFO("%8d = LM.trigrams read\n", n_trigram);
    }
        /* Initialize tginfo */
        model->lm3g.tginfo = ckd_calloc(n_unigram, sizeof(tginfo_t *));
        model->lm3g.le = listelem_alloc_init(sizeof(tginfo_t));
    }

    if (n_bigram > 0) {
        /* read n_prob2 and prob2 array (in memory) */
	if (do_mmap)
    	    fseek(fp, offset, SEEK_SET);
        if (fread(&k, sizeof(k), 1, fp) != 1)
	    goto error_out;
        if (do_swap) SWAP_INT32(&k);
	model->lm3g.n_prob2 = k;
        model->lm3g.prob2 = ckd_calloc(k, sizeof(*model->lm3g.prob2));
	if (fread(model->lm3g.prob2, sizeof(*model->lm3g.prob2), k, fp) != (size_t) k) {
    	    E_ERROR("fread(prob2) failed\n");
    	    goto error_out;
	}
	for (i = 0; i < k; i++) {
    	    if (do_swap)
        	SWAP_INT32(&model->lm3g.prob2[i].l);
    	    /* Convert values to log. */
    	    model->lm3g.prob2[i].l = logmath_log10_to_log(lmath, model->lm3g.prob2[i].f);
        }
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {       
            E_INFO("%8d = LM.prob2 entries read\n", k);
        }
    }

    /* read n_bo_wt2 and bo_wt2 array (in memory) */
    if (base->n > 2) {
        if (fread(&k, sizeof(k), 1, fp) != 1)
            goto error_out;
        if (do_swap) SWAP_INT32(&k);
        model->lm3g.n_bo_wt2 = k;
        model->lm3g.bo_wt2 = ckd_calloc(k, sizeof(*model->lm3g.bo_wt2));
        if (fread(model->lm3g.bo_wt2, sizeof(*model->lm3g.bo_wt2), k, fp) != (size_t) k) {
            E_ERROR("Failed to read backoff weights\n");
            goto error_out;
        }
        for (i = 0; i < k; i++) {
            if (do_swap)
                SWAP_INT32(&model->lm3g.bo_wt2[i].l);
            /* Convert values to log. */
            model->lm3g.bo_wt2[i].l = logmath_log10_to_log(lmath, model->lm3g.bo_wt2[i].f);
        }
                if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
                    E_INFO("%8d = LM.bo_wt2 entries read\n", k);
                }

    }
    
    /* read n_prob3 and prob3 array (in memory) */
    if (base->n > 2) {
        if (fread(&k, sizeof(k), 1, fp) != 1)
		goto error_out;
	if (do_swap) SWAP_INT32(&k);
    	model->lm3g.n_prob3 = k;
    	model->lm3g.prob3 = ckd_calloc(k, sizeof(*model->lm3g.prob3));
    	if (fread(model->lm3g.prob3, sizeof(*model->lm3g.prob3), k, fp) != (size_t) k) {
    	    E_ERROR("Failed to read trigram probability\n");
    	    goto error_out;
    	}
    	for (i = 0; i < k; i++) {
    	    if (do_swap)
                SWAP_INT32(&model->lm3g.prob3[i].l);
    	    /* Convert values to log. */
    	    model->lm3g.prob3[i].l = logmath_log10_to_log(lmath, model->lm3g.prob3[i].f);
    	}
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {     
            E_INFO("%8d = LM.prob3 entries read\n", k);
        }
    }
#import "OpenEarsStaticAnalysisToggle.h"
#ifdef STATICANALYZEDEPENDENCIES
#define __clang_analyzer__ 1
#endif
#if !defined(__clang_analyzer__) || defined(STATICANALYZEDEPENDENCIES)
#undef __clang_analyzer__ 
    /* read tseg_base size and tseg_base */
    if (do_mmap)
        offset = ftell(fp);
    if (n_trigram > 0) {
        if (do_mmap) {
            memcpy(&k, map_base + offset, sizeof(k));
            offset += sizeof(int32);
            model->lm3g.tseg_base = (int32 *) (map_base + offset);
            offset += k * sizeof(int32);
        }
        else {
            k = (n_bigram + 1) / BG_SEG_SZ + 1;
            if (fread(&k, sizeof(k), 1, fp) != 1)
                goto error_out;
            if (do_swap) SWAP_INT32(&k);
            model->lm3g.tseg_base = ckd_calloc(k, sizeof(int32));
            if (fread(model->lm3g.tseg_base, sizeof(int32), k, fp) !=
                (size_t) k) {
                E_ERROR("Failed to read trigram index\n");
                goto error_out;
            }
            if (do_swap)
                for (i = 0; i < k; i++)
                    SWAP_INT32(&model->lm3g.tseg_base[i]);
        }
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {     
            E_INFO("%8d = LM.tseg_base entries read\n", k);
        }       
    }

    /* read ascii word strings */
     
    if (do_mmap) {
        memcpy(&k, map_base + offset, sizeof(k));
        offset += sizeof(int32);
        tmp_word_str = (char *) (map_base + offset);
        offset += k;
    }
#endif    
    else {
        base->writable = TRUE;
        if (fread(&k, sizeof(k), 1, fp) != 1)
            goto error_out;
        if (do_swap) SWAP_INT32(&k);
        tmp_word_str = ckd_calloc(k, 1);
        if (fread(tmp_word_str, 1, k, fp) != (size_t) k) {
            E_ERROR("Failed to read words\n");
            goto error_out;
        }
    }
 #import "OpenEarsStaticAnalysisToggle.h"
#ifdef STATICANALYZEDEPENDENCIES
#define __clang_analyzer__ 1
#endif
#if !defined(__clang_analyzer__) || defined(STATICANALYZEDEPENDENCIES)
#undef __clang_analyzer__
    /* First make sure string just read contains n_counts[0] words (PARANOIA!!) */
    for (i = 0, j = 0; i < k; i++)
        if (tmp_word_str[i] == '\0')
            j++;
    if (j != n_unigram) {
        E_ERROR("Error reading word strings (%d doesn't match n_unigrams %d)\n",
                j, n_unigram);
        goto error_out;
    }

    /* Break up string just read into words */
    if (do_mmap) {
        j = 0;
        for (i = 0; i < n_unigram; i++) {
            base->word_str[i] = tmp_word_str + j;
            if (hash_table_enter(base->wid, base->word_str[i],
                                 (void *)(long)i) != (void *)(long)i) {
                E_WARN("Duplicate word in dictionary: %s\n", base->word_str[i]);
            }
            j += strlen(base->word_str[i]) + 1;
        }
    }
    else {
        j = 0;
        for (i = 0; i < n_unigram; i++) {
            base->word_str[i] = ckd_salloc(tmp_word_str + j);
            if (hash_table_enter(base->wid, base->word_str[i],
                                 (void *)(long)i) != (void *)(long)i) {
                E_WARN("Duplicate word in dictionary: %s\n", base->word_str[i]);
            }
            j += strlen(base->word_str[i]) + 1;
        }
        free(tmp_word_str);
    }
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
        E_INFO("%8d = ascii word strings read\n", i);
    }
    fclose_comp(fp, is_pipe);
    return base;

error_out:
    if (fp)
        fclose_comp(fp, is_pipe);
    ngram_model_free(base);
    return NULL;
    #endif
}

ngram_model_dmp_t *
ngram_model_dmp_build(ngram_model_t *base)
{
    ngram_model_dmp_t *model;
    ngram_model_t *newbase;
    ngram_iter_t *itor;
    sorted_list_t sorted_prob2;
    sorted_list_t sorted_bo_wt2;
    sorted_list_t sorted_prob3;
    bigram_t *bgptr;
    trigram_t *tgptr;
    int i, bgcount, tgcount, seg;

    if (base->funcs == &ngram_model_dmp_funcs) {
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {   
            E_INFO("Using existing DMP model.\n");
        }       
        return (ngram_model_dmp_t *)ngram_model_retain(base);
    }

    /* Initialize new base model structure with params from base. */
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
        E_INFO("Building DMP model...\n");
    }
    model = ckd_calloc(1, sizeof(*model));
    newbase = &model->base;
    ngram_model_init(newbase, &ngram_model_dmp_funcs,
                     logmath_retain(base->lmath),
                     base->n, base->n_counts[0]);
    /* Copy N-gram counts over. */
    memcpy(newbase->n_counts, base->n_counts,
           base->n * sizeof(*base->n_counts));
    /* Make sure word strings are freed. */
    newbase->writable = TRUE;
    /* Initialize unigram table and string table. */
    model->lm3g.unigrams = new_unigram_table(newbase->n_counts[0] + 1);
    for (itor = ngram_model_mgrams(base, 0); itor;
         itor = ngram_iter_next(itor)) {
        int32 prob1, bo_wt1;
        int32 const *wids;

        /* Can't guarantee they will go in unigram order, so just to
         * be correct, we do this... */
        wids = ngram_iter_get(itor, &prob1, &bo_wt1);
        model->lm3g.unigrams[wids[0]].prob1.l = prob1;
        model->lm3g.unigrams[wids[0]].bo_wt1.l = bo_wt1;
        newbase->word_str[wids[0]] = ckd_salloc(ngram_word(base, wids[0]));
        if ((hash_table_enter_int32(newbase->wid,
                                    newbase->word_str[wids[0]], wids[0]))
            != wids[0]) {
                E_WARN("Duplicate word in dictionary: %s\n", newbase->word_str[wids[0]]);
        }
    }
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
        E_INFO("%8d = #unigrams created\n", newbase->n_counts[0]);
    }
    if (newbase->n < 2) 
        return model;
			 
    /* Construct quantized probability table for bigrams and
     * (optionally) trigrams.  Hesitate to use the "sorted list" thing
     * since it isn't so useful, but it's there already. */
    init_sorted_list(&sorted_prob2);
    if (newbase->n > 2) {
        init_sorted_list(&sorted_bo_wt2);
        init_sorted_list(&sorted_prob3);
    }
    /* Construct bigram and trigram arrays. */
    bgptr = model->lm3g.bigrams = ckd_calloc(newbase->n_counts[1] + 1, sizeof(bigram_t));
    if (newbase->n > 2) {
        tgptr = model->lm3g.trigrams = ckd_calloc(newbase->n_counts[2], sizeof(trigram_t));
        model->lm3g.tseg_base =
            ckd_calloc((newbase->n_counts[1] + 1) / BG_SEG_SZ + 1, sizeof(int32));
    }
    else
        tgptr = NULL;
    /* Since bigrams and trigrams have to be contiguous with others
     * with the same N-1-gram, we traverse them in depth-first order
     * to build the bigram and trigram arrays. */
    for (i = 0; i < newbase->n_counts[0]; ++i) {
        ngram_iter_t *uitor;
        bgcount = bgptr - model->lm3g.bigrams;
        /* First bigram index (same as next if no bigrams...) */
        model->lm3g.unigrams[i].bigrams = bgcount;
        E_DEBUG(2, ("unigram %d: %s => bigram %d\n", i, newbase->word_str[i], bgcount));
        /* All bigrams corresponding to unigram i */
        uitor = ngram_ng_iter(base, i, NULL, 0);
        for (itor = ngram_iter_successors(uitor);
             itor; ++bgptr, itor = ngram_iter_next(itor)) {
            int32 prob2, bo_wt2;
            int32 const *wids;
            ngram_iter_t *titor;

            wids = ngram_iter_get(itor, &prob2, &bo_wt2);

            oe_assert(bgptr - model->lm3g.bigrams < newbase->n_counts[1]);

            bgptr->wid = wids[1];
            bgptr->prob2 = sorted_id(&sorted_prob2, &prob2);
            if (newbase->n > 2) {
                tgcount = (tgptr - model->lm3g.trigrams);
	        bgcount = (bgptr - model->lm3g.bigrams);

                /* Backoff weight (only if there are trigrams...) */
                bgptr->bo_wt2 = sorted_id(&sorted_bo_wt2, &bo_wt2);

                /* Find bigram segment for this bigram (this isn't
                 * used unless there are trigrams) */
                seg = bgcount >> LOG_BG_SEG_SZ;
                /* If we just crossed a bigram segment boundary, then
                 * point tseg_base for the new segment to the current
                 * trigram pointer. */
                if (seg != (bgcount - 1) >> LOG_BG_SEG_SZ)
                    model->lm3g.tseg_base[seg] = tgcount;
                /* Now calculate the trigram offset. */
                bgptr->trigrams = tgcount - model->lm3g.tseg_base[seg];
                E_DEBUG(2, ("bigram %d %s %s => trigram %d:%d\n",
                            bgcount,
                            newbase->word_str[wids[0]],
                            newbase->word_str[wids[1]],
                            seg, bgptr->trigrams));

                /* And fill in successors' trigram info. */
                for (titor = ngram_iter_successors(itor);
                     titor; ++tgptr, titor = ngram_iter_next(titor)) {
                    int32 prob3, dummy;

                    oe_assert(tgptr - model->lm3g.trigrams < newbase->n_counts[2]);
                    wids = ngram_iter_get(titor, &prob3, &dummy);
                    tgptr->wid = wids[2];
                    tgptr->prob3 = sorted_id(&sorted_prob3, &prob3);
                    E_DEBUG(2, ("trigram %d %s %s %s => prob %d\n",
                                tgcount,
                                newbase->word_str[wids[0]],
                                newbase->word_str[wids[1]],
                                newbase->word_str[wids[2]],
                                tgptr->prob3));
                }
            }
        }
        ngram_iter_free(uitor);
    }
    /* Add sentinal unigram and bigram records. */
    bgcount = bgptr - model->lm3g.bigrams;
    tgcount = tgptr - model->lm3g.trigrams;
    seg = bgcount >> LOG_BG_SEG_SZ;
    if (seg != (bgcount - 1) >> LOG_BG_SEG_SZ)
        model->lm3g.tseg_base[seg] = tgcount;
    model->lm3g.unigrams[i].bigrams = bgcount;
    if (newbase->n > 2)
        bgptr->trigrams = tgcount - model->lm3g.tseg_base[seg];

    /* Now create probability tables. */
    model->lm3g.n_prob2 = sorted_prob2.free;
    model->lm3g.prob2 = vals_in_sorted_list(&sorted_prob2);
    if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {    
        E_INFO("%8d = #bigrams created\n", newbase->n_counts[1]);
        E_INFO("%8d = #prob2 entries\n", model->lm3g.n_prob2);
    }
    free_sorted_list(&sorted_prob2);
    if (newbase->n > 2) {
        /* Create trigram bo-wts array. */
        model->lm3g.n_bo_wt2 = sorted_bo_wt2.free;
        model->lm3g.bo_wt2 = vals_in_sorted_list(&sorted_bo_wt2);
        free_sorted_list(&sorted_bo_wt2);
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {
            E_INFO("%8d = #bo_wt2 entries\n", model->lm3g.n_bo_wt2);
        }
        /* Create trigram probability table. */
        model->lm3g.n_prob3 = sorted_prob3.free;
        model->lm3g.prob3 = vals_in_sorted_list(&sorted_prob3);
        if(verbose_cmuclmtk == 1 || verbose_pocketsphinx == 1 ) {   
            E_INFO("%8d = #trigrams created\n", newbase->n_counts[2]);
            E_INFO("%8d = #prob3 entries\n", model->lm3g.n_prob3);
        }
        free_sorted_list(&sorted_prob3);
        /* Initialize tginfo */
        model->lm3g.tginfo = ckd_calloc(newbase->n_counts[0], sizeof(tginfo_t *));
        model->lm3g.le = listelem_alloc_init(sizeof(tginfo_t));
    }

    return model;
}

static void
fwrite_int32(FILE *fh, int32 val)
{
    fwrite(&val, 4, 1, fh);
}

static void
fwrite_ug(FILE *fh, unigram_t *ug, logmath_t *lmath)
{
    int32 bogus = -1;
    float32 log10val;

    /* Bogus dictionary mapping field. */
    fwrite(&bogus, 4, 1, fh);
    /* Convert values to log10. */
    log10val = logmath_log_to_log10(lmath, ug->prob1.l);
    fwrite(&log10val, 4, 1, fh);
    log10val = logmath_log_to_log10(lmath, ug->bo_wt1.l);
    fwrite(&log10val, 4, 1, fh);
    fwrite_int32(fh, ug->bigrams);
}

static void
fwrite_bg(FILE *fh, bigram_t *bg)
{
    fwrite(bg, sizeof(*bg), 1, fh);
}

static void
fwrite_tg(FILE *fh, trigram_t *tg)
{
    fwrite(tg, sizeof(*tg), 1, fh);
}

/** Please look at the definition of 
 */
static char const *fmtdesc[] = {
    "BEGIN FILE FORMAT DESCRIPTION",
    "Header string length (int32) and string (including trailing 0)",
    "Original LM filename string-length (int32) and filename (including trailing 0)",
    "(int32) version number (present iff value <= 0)",
    "(int32) original LM file modification timestamp (iff version# present)",
    "(int32) string-length and string (including trailing 0) (iff version# present)",
    "... previous entry continued any number of times (iff version# present)",
    "(int32) 0 (terminating sequence of strings) (iff version# present)",
    "(int32) log_bg_seg_sz (present iff different from default value of LOG2_BG_SEG_SZ)",
    "(int32) lm_t.ucount (must be > 0)",
    "(int32) lm_t.bcount",
    "(int32) lm_t.tcount",
    "lm_t.ucount+1 unigrams (including sentinel)",
    "lm_t.bcount+1 bigrams (including sentinel 64 bits (bg_t) each if version=-1/-2, 128 bits (bg32_t) each if version=-3",
    "lm_t.tcount trigrams (present iff lm_t.tcount > 0 32 bits (tg_t) each if version=-1/-2, 64 bits (tg32_t) each if version=-3)",
    "(int32) lm_t.n_prob2",
    "(int32) lm_t.prob2[]",
    "(int32) lm_t.n_bo_wt2 (present iff lm_t.tcount > 0)",
    "(int32) lm_t.bo_wt2[] (present iff lm_t.tcount > 0)",
    "(int32) lm_t.n_prob3 (present iff lm_t.tcount > 0)",
    "(int32) lm_t.prob3[] (present iff lm_t.tcount > 0)",
    "(int32) (lm_t.bcount+1)/BG_SEG_SZ+1 (present iff lm_t.tcount > 0)",
    "(int32) lm_t.tseg_base[] (present iff lm_t.tcount > 0)",
    "(int32) Sum(all word string-lengths, including trailing 0 for each)",
    "All word strings (including trailing 0 for each)",
    "END FILE FORMAT DESCRIPTION",
    NULL,
};

static void
ngram_model_dmp_write_header(FILE * fh)
{
    int32 k;
    k = strlen(darpa_hdr) + 1;
    fwrite_int32(fh, k);
    fwrite(darpa_hdr, 1, k, fh);
}

static void
ngram_model_dmp_write_lm_filename(FILE * fh, const char *lmfile)
{
    int32 k;

    k = strlen(lmfile) + 1;
    fwrite_int32(fh, k);
    fwrite(lmfile, 1, k, fh);
}

#define LMDMP_VERSION_TG_16BIT -1 /**< VERSION 1 is the simplest DMP file which
				     is trigram or lower which used 16 bits in
				     bigram and trigram.*/

static void
ngram_model_dmp_write_version(FILE * fh, int32 mtime)
{
    fwrite_int32(fh, LMDMP_VERSION_TG_16BIT);   /* version # */
    fwrite_int32(fh, mtime);
}

static void
ngram_model_dmp_write_ngram_counts(FILE * fh, ngram_model_t *model)
{
    fwrite_int32(fh, model->n_counts[0]);
    fwrite_int32(fh, model->n_counts[1]);
    fwrite_int32(fh, model->n_counts[2]);
}

static void
ngram_model_dmp_write_fmtdesc(FILE * fh)
{
    int32 i, k;
    long pos;

    /* Write file format description into header */
    for (i = 0; fmtdesc[i] != NULL; i++) {
        k = strlen(fmtdesc[i]) + 1;
        fwrite_int32(fh, k);
        fwrite(fmtdesc[i], 1, k, fh);
    }
    /* Pad it out in order to achieve 32-bit alignment */
    pos = ftell(fh);
    k = pos & 3;
    if (k) {
        fwrite_int32(fh, 4-k);
        fwrite("!!!!", 1, 4-k, fh);
    }
    fwrite_int32(fh, 0);
}

static void
ngram_model_dmp_write_unigram(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    for (i = 0; i <= model->n_counts[0]; i++) {
        fwrite_ug(fh, &(lm->lm3g.unigrams[i]), model->lmath);
    }
}


static void
ngram_model_dmp_write_bigram(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    for (i = 0; i <= model->n_counts[1]; i++) {
        fwrite_bg(fh, &(lm->lm3g.bigrams[i]));
    }

}

static void
ngram_model_dmp_write_trigram(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    for (i = 0; i < model->n_counts[2]; i++) {
        fwrite_tg(fh, &(lm->lm3g.trigrams[i]));
    }
}

static void
ngram_model_dmp_write_bgprob(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    fwrite_int32(fh, lm->lm3g.n_prob2);
    for (i = 0; i < lm->lm3g.n_prob2; i++) {
        float32 log10val = logmath_log_to_log10(model->lmath, lm->lm3g.prob2[i].l);
        fwrite(&log10val, 4, 1, fh);
    }
}

static void
ngram_model_dmp_write_tgbowt(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    fwrite_int32(fh, lm->lm3g.n_bo_wt2);
    for (i = 0; i < lm->lm3g.n_bo_wt2; i++) {
        float32 log10val = logmath_log_to_log10(model->lmath, lm->lm3g.bo_wt2[i].l);
        fwrite(&log10val, 4, 1, fh);
    }
}

static void
ngram_model_dmp_write_tgprob(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i;

    fwrite_int32(fh, lm->lm3g.n_prob3);
    for (i = 0; i < lm->lm3g.n_prob3; i++) {
        float32 log10val = logmath_log_to_log10(model->lmath, lm->lm3g.prob3[i].l);
        fwrite(&log10val, 4, 1, fh);
    }
}

static void
ngram_model_dmp_write_tg_segbase(FILE *fh, ngram_model_t *model)
{
    ngram_model_dmp_t *lm = (ngram_model_dmp_t *)model;
    int32 i, k;

    k = (model->n_counts[1] + 1) / BG_SEG_SZ + 1;
    fwrite_int32(fh, k);
    for (i = 0; i < k; i++)
        fwrite_int32(fh, lm->lm3g.tseg_base[i]);
}

static void
ngram_model_dmp_write_wordstr(FILE *fh, ngram_model_t *model)
{
    int32 i, k;

    k = 0;
    for (i = 0; i < model->n_counts[0]; i++)
        k += strlen(model->word_str[i]) + 1;
    fwrite_int32(fh, k);
    for (i = 0; i < model->n_counts[0]; i++)
        fwrite(model->word_str[i], 1,
               strlen(model->word_str[i]) + 1, fh);
}

int
ngram_model_dmp_write(ngram_model_t *base,
                      const char *file_name)
{
    ngram_model_dmp_t *model;
    ngram_model_t *newbase;
    FILE *fh;

    /* First, construct a DMP model from the base model. */
    model = ngram_model_dmp_build(base);
    newbase = &model->base;

    /* Now write it, confident in the knowledge that it's the right
     * kind of language model internally. */
    if ((fh = fopen(file_name, "wb")) == NULL) {
        E_ERROR("Cannot create file %s\n", file_name);
        return -1;
    }
    ngram_model_dmp_write_header(fh);
    ngram_model_dmp_write_lm_filename(fh, file_name);
    ngram_model_dmp_write_version(fh, 0);
    ngram_model_dmp_write_fmtdesc(fh);
    ngram_model_dmp_write_ngram_counts(fh, newbase);
    ngram_model_dmp_write_unigram(fh, newbase);
    if (newbase->n > 1) {
        ngram_model_dmp_write_bigram(fh, newbase);
	if (newbase->n > 2) {
	    ngram_model_dmp_write_trigram(fh, newbase);
	}
	ngram_model_dmp_write_bgprob(fh, newbase);
	if (newbase->n > 2) {
	        ngram_model_dmp_write_tgbowt(fh, newbase);
	        ngram_model_dmp_write_tgprob(fh, newbase);
	        ngram_model_dmp_write_tg_segbase(fh, newbase);
        }
    }
    ngram_model_dmp_write_wordstr(fh, newbase);
    ngram_model_free(newbase);

    return fclose(fh);
}

static int
ngram_model_dmp_apply_weights(ngram_model_t *base, float32 lw,
                              float32 wip, float32 uw)
{
    ngram_model_dmp_t *model = (ngram_model_dmp_t *)base;
    lm3g_apply_weights(base, &model->lm3g, lw, wip, uw);
    return 0;
}

/* Lousy "templating" for things that are largely the same in DMP and
 * ARPA models, except for the bigram and trigram types and some
 * names. */
#define NGRAM_MODEL_TYPE ngram_model_dmp_t























#import "oeassert.h"

/* Locate a specific bigram within a bigram list */
#define BINARY_SEARCH_THRESH	16
static int32
find_bg(bigram_t * bg, int32 n, int32 w)
{
    int32 i, b, e;
    
    /* Binary search until segment size < threshold */
    b = 0;
    e = n;
    while (e - b > BINARY_SEARCH_THRESH) {
        i = (b + e) >> 1;
        if (bg[i].wid < w)
            b = i + 1;
        else if (bg[i].wid > w)
            e = i;
        else
            return i;
    }
    
    /* Linear search within narrowed segment */
    for (i = b; (i < e) && (bg[i].wid != w); i++);
    return ((i < e) ? i : -1);
}

static int32
lm3g_bg_score(NGRAM_MODEL_TYPE *model,
              int32 lw1, int32 lw2, int32 *n_used)
{
    int32 i, n, b, score;
    bigram_t *bg;
    
    if (lw1 < 0 || model->base.n < 2) {
        *n_used = 1;
        return model->lm3g.unigrams[lw2].prob1.l;
    }
    
    b = FIRST_BG(model, lw1);
    n = FIRST_BG(model, lw1 + 1) - b;
    bg = model->lm3g.bigrams + b;
    
    if ((i = find_bg(bg, n, lw2)) >= 0) {
        /* Access mode = bigram */
        *n_used = 2;
        score = model->lm3g.prob2[bg[i].prob2].l;
    }
    else {
        /* Access mode = unigram */
        *n_used = 1;
        score = model->lm3g.unigrams[lw1].bo_wt1.l + model->lm3g.unigrams[lw2].prob1.l;
    }
    
    return (score);
}

static void
load_tginfo(NGRAM_MODEL_TYPE *model, int32 lw1, int32 lw2)
{
    int32 i, n, b, t;
    bigram_t *bg;
    tginfo_t *tginfo;
    
    /* First allocate space for tg information for bg lw1,lw2 */
    tginfo = (tginfo_t *) listelem_malloc(model->lm3g.le);
    tginfo->w1 = lw1;
    tginfo->tg = NULL;
    tginfo->next = model->lm3g.tginfo[lw2];
    model->lm3g.tginfo[lw2] = tginfo;
    
    /* Locate bigram lw1,lw2 */
    b = model->lm3g.unigrams[lw1].bigrams;
    n = model->lm3g.unigrams[lw1 + 1].bigrams - b;
    bg = model->lm3g.bigrams + b;
    
    if ((n > 0) && ((i = find_bg(bg, n, lw2)) >= 0)) {
        tginfo->bowt = model->lm3g.bo_wt2[bg[i].bo_wt2].l;
        
        /* Find t = Absolute first trigram index for bigram lw1,lw2 */
        b += i;                 /* b = Absolute index of bigram lw1,lw2 on disk */
        t = FIRST_TG(model, b);
        
        tginfo->tg = model->lm3g.trigrams + t;
        
        /* Find #tg for bigram w1,w2 */
        tginfo->n_tg = FIRST_TG(model, b + 1) - t;
    }
    else {                      /* No bigram w1,w2 */
        tginfo->bowt = 0;
        tginfo->n_tg = 0;
    }
}

/* Similar to find_bg */
static int32
find_tg(trigram_t * tg, int32 n, int32 w)
{
    int32 i, b, e;
    
    b = 0;
    e = n;
    while (e - b > BINARY_SEARCH_THRESH) {
        i = (b + e) >> 1;
        if (tg[i].wid < w)
            b = i + 1;
        else if (tg[i].wid > w)
            e = i;
        else
            return i;
    }
    
    for (i = b; (i < e) && (tg[i].wid != w); i++);
    return ((i < e) ? i : -1);
}

static int32
lm3g_tg_score(NGRAM_MODEL_TYPE *model, int32 lw1,
              int32 lw2, int32 lw3, int32 *n_used)
{
    ngram_model_t *base = &model->base;
    int32 i, n, score;
    trigram_t *tg;
    tginfo_t *tginfo, *prev_tginfo;
    
    if ((base->n < 3) || (lw1 < 0) || (lw2 < 0))
        return (lm3g_bg_score(model, lw2, lw3, n_used));
    
    prev_tginfo = NULL;
    for (tginfo = model->lm3g.tginfo[lw2]; tginfo; tginfo = tginfo->next) {
        if (tginfo->w1 == lw1)
            break;
        prev_tginfo = tginfo;
    }
    
    if (!tginfo) {
        load_tginfo(model, lw1, lw2);
        tginfo = model->lm3g.tginfo[lw2];
    }
    else if (prev_tginfo) {
        prev_tginfo->next = tginfo->next;
        tginfo->next = model->lm3g.tginfo[lw2];
        model->lm3g.tginfo[lw2] = tginfo;
    }
    
    tginfo->used = 1;
#import "OpenEarsStaticAnalysisToggle.h"
#ifdef STATICANALYZEDEPENDENCIES
#define __clang_analyzer__ 1
#endif
#if !defined(__clang_analyzer__) || defined(STATICANALYZEDEPENDENCIES)
#undef __clang_analyzer__
    
    /* Trigrams for w1,w2 now pointed to by tginfo */
    n = tginfo->n_tg;
    tg = tginfo->tg;
     
    if ((i = find_tg(tg, n, lw3)) >= 0) {
        /* Access mode = trigram */
        *n_used = 3;
        score = model->lm3g.prob3[tg[i].prob3].l;
    }
    else {
        score = tginfo->bowt + lm3g_bg_score(model, lw2, lw3, n_used);
    }
  
    return (score);
#endif      
}

static int32
lm3g_template_score(ngram_model_t *base, int32 wid,
                    int32 *history, int32 n_hist,
                    int32 *n_used)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    switch (n_hist) {
        case 0:
            /* Access mode: unigram */
            *n_used = 1;
            return model->lm3g.unigrams[wid].prob1.l;
        case 1:
            return lm3g_bg_score(model, history[0], wid, n_used);
        case 2:
        default:
            /* Anything greater than 2 is the same as a trigram for now. */
            return lm3g_tg_score(model, history[1], history[0], wid, n_used);
    }
}

static int32
lm3g_template_raw_score(ngram_model_t *base, int32 wid,
                        int32 *history, int32 n_hist,
                        int32 *n_used)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    int32 score;
    
    switch (n_hist) {
        case 0:
            /* Access mode: unigram */
            *n_used = 1;
            /* Undo insertion penalty. */
            score = model->lm3g.unigrams[wid].prob1.l - base->log_wip;
            /* Undo language weight. */
            score = (int32)(score / base->lw);
            /* Undo unigram interpolation */
            if (strcmp(base->word_str[wid], "<s>") != 0) { /* FIXME: configurable start_sym */
                score = logmath_log(base->lmath,
                                    logmath_exp(base->lmath, score)
                                    - logmath_exp(base->lmath, 
                                                  base->log_uniform + base->log_uniform_weight));
            }
            return score;
        case 1:
            score = lm3g_bg_score(model, history[0], wid, n_used);
            break;
        case 2:
        default:
            /* Anything greater than 2 is the same as a trigram for now. */
            score = lm3g_tg_score(model, history[1], history[0], wid, n_used);
            break;
    }
    /* FIXME (maybe): This doesn't undo unigram weighting in backoff cases. */
    return (int32)((score - base->log_wip) / base->lw);
}

static int32
lm3g_template_add_ug(ngram_model_t *base,
                     int32 wid, int32 lweight)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    return lm3g_add_ug(base, &model->lm3g, wid, lweight);
}

static void
lm3g_template_flush(ngram_model_t *base)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    lm3g_tginfo_reset(base, &model->lm3g);
}

typedef struct lm3g_iter_s {
    ngram_iter_t base;
    unigram_t *ug;
    bigram_t *bg;
    trigram_t *tg;
} lm3g_iter_t;

static ngram_iter_t *
lm3g_template_iter(ngram_model_t *base, int32 wid,
                   int32 *history, int32 n_hist)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    lm3g_iter_t *itor = ckd_calloc(1, sizeof(*itor));
    
    ngram_iter_init((ngram_iter_t *)itor, base, n_hist, FALSE);
    
    if (n_hist == 0) {
        /* Unigram is the easiest. */
        itor->ug = model->lm3g.unigrams + wid;
        return (ngram_iter_t *)itor;
    }
    else if (n_hist == 1) {
        int32 i, n, b;
        /* Find the bigram, as in bg_score above (duplicate code...) */
        itor->ug = model->lm3g.unigrams + history[0];
        b = FIRST_BG(model, history[0]);
        n = FIRST_BG(model, history[0] + 1) - b;
        itor->bg = model->lm3g.bigrams + b;
        /* If no such bigram exists then fail. */
        if ((i = find_bg(itor->bg, n, wid)) < 0) {
            ngram_iter_free((ngram_iter_t *)itor);
            return NULL;
        }
        itor->bg += i;
        return (ngram_iter_t *)itor;
    }
    else if (n_hist == 2) {
        int32 i, n;
        tginfo_t *tginfo, *prev_tginfo;
        /* Find the trigram, as in tg_score above (duplicate code...) */
        itor->ug = model->lm3g.unigrams + history[1];
        prev_tginfo = NULL;
        for (tginfo = model->lm3g.tginfo[history[0]];
             tginfo; tginfo = tginfo->next) {
            if (tginfo->w1 == history[1])
                break;
            prev_tginfo = tginfo;
        }
        
        if (!tginfo) {
            load_tginfo(model, history[1], history[0]);
            tginfo = model->lm3g.tginfo[history[0]];
        }
        else if (prev_tginfo) {
            prev_tginfo->next = tginfo->next;
            tginfo->next = model->lm3g.tginfo[history[0]];
            model->lm3g.tginfo[history[0]] = tginfo;
        }
        
        tginfo->used = 1;
        
        /* Trigrams for w1,w2 now pointed to by tginfo */
        n = tginfo->n_tg;
        itor->tg = tginfo->tg;
        if ((i = find_tg(itor->tg, n, wid)) >= 0) {
            itor->tg += i;
            /* Now advance the bigram pointer accordingly.  FIXME:
             * Note that we actually already found the relevant bigram
             * in load_tginfo. */
            itor->bg = model->lm3g.bigrams;
            while (FIRST_TG(model, (itor->bg - model->lm3g.bigrams + 1))
                   <= (itor->tg - model->lm3g.trigrams))
                ++itor->bg;
            return (ngram_iter_t *)itor;
        }
        else {
            ngram_iter_free((ngram_iter_t *)itor);
            return (ngram_iter_t *)NULL;
        }
    }
    else {
        /* Should not happen. */
        oe_assert(n_hist == 0); /* Guaranteed to fail. */
        ngram_iter_free((ngram_iter_t *)itor);
        return NULL;
    }
}

static ngram_iter_t *
lm3g_template_mgrams(ngram_model_t *base, int m)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base;
    lm3g_iter_t *itor = ckd_calloc(1, sizeof(*itor));
    ngram_iter_init((ngram_iter_t *)itor, base, m, FALSE);
    
    itor->ug = model->lm3g.unigrams;
    itor->bg = model->lm3g.bigrams;
    itor->tg = model->lm3g.trigrams;
    
    /* Advance bigram pointer to match first trigram. */
    if (m > 1 && base->n_counts[1] > 1)  {
        while (FIRST_TG(model, (itor->bg - model->lm3g.bigrams + 1))
               <= (itor->tg - model->lm3g.trigrams))
            ++itor->bg;
    }
    
    /* Advance unigram pointer to match first bigram. */
    if (m > 0 && base->n_counts[0] > 1) {
        while (itor->ug[1].bigrams <= (itor->bg - model->lm3g.bigrams))
            ++itor->ug;
    }
    
    return (ngram_iter_t *)itor;
}

static ngram_iter_t *
lm3g_template_successors(ngram_iter_t *bitor)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)bitor->model;
    lm3g_iter_t *from = (lm3g_iter_t *)bitor;
    lm3g_iter_t *itor = ckd_calloc(1, sizeof(*itor));
    
    itor->ug = from->ug;
    switch (bitor->m) {
        case 0:
            /* Next itor bigrams is the same as this itor bigram or
             itor bigrams is more than total count. This means no successors */
            if (((itor->ug + 1) - model->lm3g.unigrams < bitor->model->n_counts[0] &&
                 itor->ug->bigrams == (itor->ug + 1)->bigrams) || 
                itor->ug->bigrams == bitor->model->n_counts[1])
                goto done;
            
            /* Start iterating from first bigram successor of from->ug. */
            itor->bg = model->lm3g.bigrams + itor->ug->bigrams;
            break;
        case 1:
            itor->bg = from->bg;
            
            /* This indicates no successors */
            if (((itor->bg + 1) - model->lm3g.bigrams < bitor->model->n_counts[1] &&
                 FIRST_TG (model, itor->bg - model->lm3g.bigrams) == 
                 FIRST_TG (model, (itor->bg + 1) - model->lm3g.bigrams)) ||
                FIRST_TG (model, itor->bg - model->lm3g.bigrams) == bitor->model->n_counts[2])
                goto done;
    	    
            /* Start iterating from first trigram successor of from->bg. */
            itor->tg = (model->lm3g.trigrams 
                        + FIRST_TG(model, (itor->bg - model->lm3g.bigrams)));
#if 0
            printf("%s %s => %d (%s)\n",
                   model->base.word_str[itor->ug - model->lm3g.unigrams],
                   model->base.word_str[itor->bg->wid],
                   FIRST_TG(model, (itor->bg - model->lm3g.bigrams)),
                   model->base.word_str[itor->tg->wid]);
#endif
            break;
        case 2:
        default:
            /* All invalid! */
            goto done;
    }
    
    ngram_iter_init((ngram_iter_t *)itor, bitor->model, bitor->m + 1, TRUE);
    return (ngram_iter_t *)itor;
done:
    ckd_free(itor);
    return NULL;
}

static int32 const *
lm3g_template_iter_get(ngram_iter_t *base,
                       int32 *out_score, int32 *out_bowt)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base->model;
    lm3g_iter_t *itor = (lm3g_iter_t *)base;
    
    base->wids[0] = itor->ug - model->lm3g.unigrams;
    if (itor->bg) base->wids[1] = itor->bg->wid;
    if (itor->tg) base->wids[2] = itor->tg->wid;
#if 0
    printf("itor_get: %d %d %d\n", base->wids[0], base->wids[1], base->wids[2]);
#endif
#import "OpenEarsStaticAnalysisToggle.h"
#ifdef STATICANALYZEDEPENDENCIES
#define __clang_analyzer__ 1
#endif
#if !defined(__clang_analyzer__) || defined(STATICANALYZEDEPENDENCIES)
#undef __clang_analyzer__
     
    switch (base->m) {
        case 0:
            *out_score = itor->ug->prob1.l;
            *out_bowt = itor->ug->bo_wt1.l;
            break;
        case 1:
            *out_score = model->lm3g.prob2[itor->bg->prob2].l;
            if (model->lm3g.bo_wt2)
                *out_bowt = model->lm3g.bo_wt2[itor->bg->bo_wt2].l;
            else
                *out_bowt = 0;
            break;
        case 2:
            *out_score = model->lm3g.prob3[itor->tg->prob3].l;
            *out_bowt = 0;
            break;
        default: /* Should not happen. */
            return NULL;
    }
    return base->wids;
#endif    
}

static ngram_iter_t *
lm3g_template_iter_next(ngram_iter_t *base)
{
    NGRAM_MODEL_TYPE *model = (NGRAM_MODEL_TYPE *)base->model;
    lm3g_iter_t *itor = (lm3g_iter_t *)base;
    
    switch (base->m) {
        case 0:
            ++itor->ug;
            /* Check for end condition. */
            if (itor->ug - model->lm3g.unigrams >= base->model->n_counts[0])
                goto done;
            break;
        case 1:
            ++itor->bg;
            /* Check for end condition. */
            if (itor->bg - model->lm3g.bigrams >= base->model->n_counts[1])
                goto done;
            /* Advance unigram pointer if necessary in order to get one
             * that points to this bigram. */
            while (itor->bg - model->lm3g.bigrams >= itor->ug[1].bigrams) {
                /* Stop if this is a successor iterator, since we don't
                 * want a new unigram. */
                if (base->successor)
                    goto done;
                ++itor->ug;
                if (itor->ug == model->lm3g.unigrams + base->model->n_counts[0]) {
                    E_ERROR("Bigram %d has no valid unigram parent\n",
                            itor->bg - model->lm3g.bigrams);
                    goto done;
                }
            }
            break;
        case 2:
            ++itor->tg;
            /* Check for end condition. */
            if (itor->tg - model->lm3g.trigrams >= base->model->n_counts[2])
                goto done;
            /* Advance bigram pointer if necessary. */
            while (itor->tg - model->lm3g.trigrams >=
                   FIRST_TG(model, (itor->bg - model->lm3g.bigrams + 1))) {
                if (base->successor)
                    goto done;
                ++itor->bg;
                if (itor->bg == model->lm3g.bigrams + base->model->n_counts[1]) {
                    E_ERROR("Trigram %d has no valid bigram parent\n",
                            itor->tg - model->lm3g.trigrams);
                    
                    goto done;
                }
            }
            /* Advance unigram pointer if necessary. */
            while (itor->bg - model->lm3g.bigrams >= itor->ug[1].bigrams) {
                ++itor->ug;
                if (itor->ug == model->lm3g.unigrams + base->model->n_counts[0]) {
                    E_ERROR("Trigram %d has no valid unigram parent\n",
                            itor->tg - model->lm3g.trigrams);
                    goto done;
                }
            }
            break;
        default: /* Should not happen. */
            goto done;
    }
    
    return (ngram_iter_t *)itor;
done:
    ngram_iter_free(base);
    return NULL;
}

static void
lm3g_template_iter_free(ngram_iter_t *base)
{
    ckd_free(base);
}



























static void
ngram_model_dmp_free(ngram_model_t *base)
{
    ngram_model_dmp_t *model = (ngram_model_dmp_t *)base;

    ckd_free(model->lm3g.unigrams);
    ckd_free(model->lm3g.prob2);
    if (model->dump_mmap) {
        mmio_file_unmap(model->dump_mmap);
    } 
    else {
        ckd_free(model->lm3g.bigrams);
        if (base->n > 2) {
            ckd_free(model->lm3g.trigrams);
            ckd_free(model->lm3g.tseg_base);
        }
    }
    if (base->n > 2) {
        ckd_free(model->lm3g.bo_wt2);
        ckd_free(model->lm3g.prob3);
    }

    lm3g_tginfo_free(base, &model->lm3g);
}

static ngram_funcs_t ngram_model_dmp_funcs = {
    ngram_model_dmp_free,          /* free */
    ngram_model_dmp_apply_weights, /* apply_weights */
    lm3g_template_score,           /* score */
    lm3g_template_raw_score,       /* raw_score */
    lm3g_template_add_ug,          /* add_ug */
    lm3g_template_flush,           /* flush */
    lm3g_template_iter,             /* iter */
    lm3g_template_mgrams,          /* mgrams */
    lm3g_template_successors,      /* successors */
    lm3g_template_iter_get,        /* iter_get */
    lm3g_template_iter_next,       /* iter_next */
    lm3g_template_iter_free        /* iter_free */
};
