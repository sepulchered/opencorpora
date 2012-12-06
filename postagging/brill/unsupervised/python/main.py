#coding: utf-8

import sys
import os
from utils import get_list_words_pos, Rule, numb_amb_corpus, get_list_amb
from rules_stat import scoring_function, apply_rule


if __name__ == '__main__':
    args = sys.argv[1:]
    apply_all = False
    fullcorp = False
    if args != []:
        if args[0] == '-r':
            apply_all = True
        if '-f' in args:
            fullcorp = True
    out = open('rules.txt', 'w')
    input_corpus = sys.stdin.read()
    i = 0
    best_rules = []
    best_score = 0
    #print numb_amb_corpus(input_corpus)
    while True:
        context_freq = get_list_words_pos(input_corpus)
        if fullcorp:
            f = '/data/rubash/brill/full/iter%s.txt' % i
        else:
            f = '/data/rubash/brill/1/iter%s.txt' % i
        with open(f, 'w') as output:
            for amb_tag in context_freq.keys():
                for context in context_freq[amb_tag].keys():
                    if context != 'freq':
                        try:
                            for c_variant in context_freq[amb_tag][context].keys():
                                output.write('\t'.join((amb_tag, context, c_variant, str(context_freq[amb_tag][context][c_variant]))) + '\n')
                        except:
                            print context_freq[amb_tag]
                            print amb_tag
                    else:
                        output.write('\t'.join((amb_tag, 'freq', str(context_freq[amb_tag][context]))) + '\n')
        scores_rule = scoring_function(context_freq, best_rules)
        scores = scores_rule[0]
        best_rule = scores_rule[1]
        best_rules.append(best_rule)
        best_score = scores_rule[2]
        rule = Rule(*best_rule)
        if fullcorp:
            f = '/data/rubash/brill/full/iter%s.scores' % i
        else:
            f = '/data/rubash/brill/1/iter%s.scores' % i
        with open(f, 'w') as output:
            for amb_tag in scores.keys():
                for tag in scores[amb_tag].keys():
                    for context in scores[amb_tag][tag].keys():
                        for c_variant in scores[amb_tag][tag][context].keys():
                            output.write('\t'.join((str(scores[amb_tag][tag][context][c_variant]), amb_tag, tag, context, c_variant)) + '\n')
        input_corpus = apply_rule(rule, input_corpus[:])
        out.write(rule.display() + '\n')
        if apply_all:
            for rule in best_rules[:-1]:
                r = Rule(*rule)
                input_corpus = apply_rule(r, input_corpus[:])
        if fullcorp:
            f = '/data/rubash/brill/full/icorpus.txt' % i
        else:
            f = '/data/rubash/brill/1/icorpus.txt' % i
        with open(f, 'w') as output:
            output.write(input_corpus)
        out.write(str(numb_amb_corpus(input_corpus)) + '\n')
        out.flush()
        os.fsync(out)
        i += 1
        if best_score < 0:
                out.close()
                break