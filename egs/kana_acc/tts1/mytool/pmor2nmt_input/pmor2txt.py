#!env python

import sys, io
import argparse
import re
import pprint as pp
import json


# Guess encoding
def guess_charset(filename):
    _max_item = lambda d: max(d.items(), key=lambda x: x[1])[0]
    th = 0.99
    charsets = ['utf8', 'cp932', 'ujis', 'iso2022jp']
    counts = {key: 1 for key in charsets}
    with open(filename, 'rb') as f:
        for line in f:
            # skip ascii-only strings
            try:
                line.decode('ascii', errors="strict")
                continue
            except UnicodeDecodeError: pass
            # check encoding
            for c in charsets:
                try:
                    line.decode(c)
                    counts[c] += len(line)
                    break
                except UnicodeDecodeError: pass
            # finish?
            if th < max(counts.values()) / sum(counts.values()):
                break
    return _max_item(counts)


def main(filename):
# エンコーディングはeuc_jpで決め打ちしてる
    with open(filename, 'r', encoding='euc_jp', errors='backslashreplace') as f:
        for line in f:
# 空行と末尾が]の行は捨てる
          if len(line) <= 1 or line[-2] == ']':
            continue
          print(line.split(',')[0], end='')
    print('')
    return


if __name__ == "__main__":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    
    parser = argparse.ArgumentParser(description='convert kana + accent to phn + HL')
    parser.add_argument('mode', help='Mode', choices=['convert'])
    parser.add_argument('--input', help='Input kana file', default="test_input.txt")
    args = parser.parse_args()

    if args.mode == "convert":
        main(args.input)
