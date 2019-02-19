#!/bin/bash
. ./path.sh

if [ $# != 2 ]; then
   echo "Usage: $0 [options] <old-lang-dir> <new-lang-dir>"
   echo "e.g.: $0 data/lang_test data/lang_test_4op"
   exit 1;
fi

# lang是原本有G.fst的目錄
lang=$1
# dir是輸出修改後的
dir=$2

# [ -d $dir ] && mv $dir ${dir}.bak
# cp -r $lang $dir
# mkdir -p $dir/tmp

cat <<EOF > $dir/tmp/O.txt
0	1	壹	壹
1	2	#W	#W
2	3	貳	貳
3	4	#W	#W
4	5	參	參
5	6	#W	#W
6	7	肆	肆
7	8	#W	#W
8
EOF

# O.tmp
# 0       1       17892   17892
# 1       2       89884   89884
# 2       3       74035   74035
# 3       4       89884   89884
# 4       5       12081   12081
# 5       6       89884   89884
# 6       7       63833   63833
# 7       8       89884   89884
# 8

cut -d\  -f 1 $lang/phones/unique_lexicon.txt | grep -v '<eps>' |\
  awk '{printf("0 0 %s %s\n", $1, $1)}END{print "0"}' | \
  fstcompile --isymbols=$lang/words.txt --osymbols=$lang/words.txt > $dir/tmp/w.fst

(cut -d\  -f 1 $lang/words.txt ; echo "#W"; echo "#ROOT") | awk '{print $1 " " NR-1}' > $dir/words.txt

fstcompile --isymbols=$dir/words.txt --osymbols=$dir/words.txt $dir/tmp/O.txt $dir/tmp/O.tmp

fstreplace --epsilon_on_replace $dir/tmp/O.tmp $(echo "#ROOT" | utils/sym2int.pl $dir/words.txt) $dir/tmp/w.fst $(echo "#W" | utils/sym2int.pl $dir/words.txt) | fstminimizeencoded | fstarcsort --sort_type=ilabel > $dir/tmp/O.fst

fstisstochastic $dir/tmp/O.fst

fstprint $dir/tmp/O.fst > $dir/tmp/1.txt
fstprint $dir/tmp/w.fst > $dir/tmp/2.txt
fstprint $dir/tmp/O.tmp > $dir/tmp/3.txt


# fstreplace --epsilon_on_replace $dir/tmp/O.tmp $(echo "#ROOT" | utils/sym2int.pl $dir/words.txt) $dir/tmp/w.fst $(echo "#W" | utils/sym2int.pl $dir/words.txt) |
#   fstdeterminizestar | fstminimizeencoded | fstarcsort --sort_type=ilabel > $dir/tmp/O.fst
# fstisstochastic $dir/tmp/O.fst

# fstarcsort --sort_type=olabel $lang/G.fst | fsttablecompose - $dir/tmp/O.fst | fstarcsort > $dir/G.fst
# set e
# fstisstochastic $dir/G.fst
# exit 0;
