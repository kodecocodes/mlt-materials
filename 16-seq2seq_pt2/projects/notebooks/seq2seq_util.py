import keras
import random
from collections import defaultdict
from keras.utils import Sequence

"""
This Sequence subclass produces batched sequences with the following
properties:
  1. Derived from the samples object passed to init.
  2. Grouped so input sequences are similar in length.
  3. Characters in sequences are one-hot encoded and padded with zeros
  using batch_encoder passed to init.
  4. Each batch will have no more than batch_size items, but may have
  fewer if there are not enough sequences of similar length.
  5. Sequences are considered similar in length if they require no more
  than bin_size-1 padding steps to line up to next nearest multiple of bin_size.
  
  For example:
    If bin_size is 10, all sequences of length <= 10 will appear in batches together,
    sequences of length 11-20 will be together, then 21-30, etc.    
"""
class Seq2SeqBatchGenerator(Sequence):
    """
    
    """
    def __init__(self, samples, batch_size, batch_encoder, bin_size=5):
        self.bin_size = bin_size
        self.batch_size = batch_size
        self.batch_encoder = batch_encoder
        
        # arrange samples in bins grouped by similar sequence sizes
        binned_samples = defaultdict(list)
        for sample in samples:
            bin_id = (len(sample[0]) - 1) // bin_size
            binned_samples[bin_id].append(sample)
        self.binned_samples = binned_samples

        # count how many batches in each bin
        batches_per_bin = {
            bin_id : (len(bin_samples) // batch_size + 
                      (1 if len(bin_samples) % batch_size != 0 else 0))
            for bin_id, bin_samples in binned_samples.items()}
        self.num_batches = sum(batches_per_bin.values())
        
        self.available_bins = sorted(self.binned_samples.keys())
        
        # Bookkeeping to help figure out which batches go in which bins
        self.bin_batch_cutoff = {}
        self.batch_offsets = {}
        bin_offset = 0
        for b in self.available_bins:
            num_batches = batches_per_bin[b]
            self.batch_offsets[b] = bin_offset
            bin_offset += num_batches
            self.bin_batch_cutoff[b] = bin_offset
                    
    """
    Required function for all subclasses of Sequence. This returns the total
    number of batches that make up one epoch. This may be more than you expect
    for a given batch size, because some batches will be smaller. 
    """
    def __len__(self):
        return self.num_batches
    
    """
    Option function for subclasses of Sequence. Called after each epoch, this
    implementation shuffles the dataset so that batches will differ from
    epoch to epoch. This improves the performance of the optimization algorithm.
    """
    def on_epoch_end(self):
        for bin_id in self.binned_samples.values():
            random.shuffle(bin_id)
        
    """
    Required function for all subclasses of Sequence. This returns the batch
    with the given index, idx. Batches may be requested out of order and may
    even be called from multiple processes.
    """
    def __getitem__(self, idx):
        # find proper bin for batch
        for bin_id in self.available_bins: 
            cutoff_id = self.bin_batch_cutoff[bin_id]
            if idx < cutoff_id:
                break

        # find location of batch within bin
        idx -= self.batch_offsets[bin_id]
        
        # grab samples for batch and encode them
        sample_bin = self.binned_samples[bin_id]
        batch_samples = sample_bin[idx * self.batch_size : (idx+1) * self.batch_size]        
        enc_in, dec_in, dec_out = self.batch_encoder(batch_samples)
        
        return [enc_in, dec_in], dec_out
    
    
def test_predictions(samples, encoder, decoder, batch_encoder, sequence_decoder):
    """
    Helper function to test model. samples should be a list of tuples with 
    Spanish-English sequence pairs. Encoder and decoder should work with 
    sequence_decoder and sequence encoded by batch_encoder.
    """
    for sample in samples:
        encoded_seq, _, _ = batch_encoder([sample])
        decoded_sentence = sequence_decoder(encoded_seq, encoder, decoder)

        print("-----------------------------------------")
        print("Input sentence:", sample[0])
        print("Dataset translation:", sample[1])
        print("Model output:", decoded_sentence)