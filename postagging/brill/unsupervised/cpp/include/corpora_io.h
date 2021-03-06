#include <list>
#include <vector>
#include <string>

#include "sentence.h"
#include "tag.h"

#ifndef __CORPORA_IO_H
#define __CORPORA_IO_H

typedef std::vector<Sentence> SentenceCollection;

void readCorpus(const std::string &fn, SentenceCollection &sc);

std::set<MorphInterp> makeVariants(const std::string &s);

#endif
