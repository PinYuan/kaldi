# How to dump files for kaldi-inspection

1. cd to project folder
2. [Dump best wer and align txt] for each test set, modify "dir" in script my_local/kaldi-inspection/best.wer and execute
3. [Dump custom files] . ./my_local/kaldi-inspection/mk_ctms.sh
4. [Link to kaldi-inspection] . ./my_local/kaldi-inspection/ln_decodes.sh