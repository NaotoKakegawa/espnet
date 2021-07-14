#!env python

import sys, io
import argparse
import re
import pprint as pp
import json

table0 = {
    "カ゜": "ガ",
    "カ°": "ガ",
    "キ゜": "ギ",
    "キ°": "ギ",
    "ク゜": "グ",
    "ク°": "グ",
    "ケ゜": "ゲ",
    "ケ°": "ゲ",
    "コ゜": "ゴ",
    "コ°": "ゴ",
    "キ^": "KY^ ",
    "ク^": "K^ ",
    "スィ^": "S^ ",
    "ス^": "S^ ",
    "シ^": "SY^ ",
    "シュ^": "c^ ",
    "ツ^": "TS^ ",
    "チ^": "TY^ ",
    "ヒ^": "HY^ ",
    "フ^": "F^ ",
    "ピ^": "PY^ ",
    "プ^": "P^ ",
    };
table1 = {
    "ビャ": "B y A ",
    "ビィ": "B y I ",
    "ビュ": "B y U ",
    "ビェ": "B y E ",
    "ビョ": "B y O ",
    "トゥ": "T U ",
    "ドゥ": "D U ",
    "デャ": "D y A ",
    "デュ": "D y U ",
    "デョ": "D y O ",
    "ミャ": "M y A ",
    "ミィ": "M y I ",
    "ミュ": "M y U ",
    "ミェ": "M y E ",
    "ミョ": "M y O ",
    "ニャ": "N y A ",
    "ニィ": "N y I ",
    "ニュ": "N y U ",
    "ニェ": "N y E ",
    "ニョ": "N y O ",
    "ピャ": "PY y A ",
    "ピィ": "PY y I ",
    "ピュ": "PY y U ",
    "ピェ": "PY y E ",
    "ピョ": "PY y O ",
    "リャ": "R y A ",
    "リィ": "R y I ",
    "リュ": "R y U ",
    "リェ": "R y E ",
    "リョ": "R y O ",
    "ヒャ": "HY y A ",
    "ヒィ": "HY I ",
    "ヒュ": "HY y U ",
    "ヒェ": "HY y E ",
    "ヒョ": "HY y O ",
    "チャ": "TY y A ",
    "チィ": "TY I ",
    "チュ": "TY y U ",
    "チェ": "TY y E ",
    "チョ": "TY y O ",
    "ギャ": "G y A ",
    "ギィ": "G y I ",
    "ギュ": "G y U ",
    "ギェ": "G y E ",
    "ギョ": "G y O ",
    "キャ": "KY y A ",
    "キィ": "KY I ",
    "キュ": "KY y U ",
    "キェ": "KY y E ",
    "キョ": "KY y O ",
    "シャ": "SY y A ",
    "シィ": "SY I ",
    "シュ": "SY y U ",
    "シェ": "SY y E ",
    "ショ": "SY y O ",
    "ジャ": "ZY y A ",
    "ジュ": "ZY y U ",
    "ジェ": "ZY y E ",
    "ジョ": "ZY y O ",
    "ファ": "F A ",
    "フィ": "F I ",
    "フェ": "F E ",
    "フォ": "F O ",
    "フャ": "F y A ",
    "フュ": "F y U ",
    "フョ": "F y O ",
    "ヴァ": "B A ",
    "ヴィ": "B I ",
    "ヴェ": "B E ",
    "ヴォ": "B O ",
    "ウィ": "W I ",
    "ウェ": "W E ",
    "ウォ": "W O ",
    "ティ": "T I ",
    "ディ": "D I ",
    "ツァ": "TS A ",
    "ツィ": "TS I ",
    "ツェ": "TS E ",
    "ツォ": "TS O ",
    "クァ": "K A ",
    "クィ": "K I ",
    "クェ": "K E ",
    "クォ": "K O ",
    "テュ": "T y U ",
    "ズィ": "Z I ",
    "ジィ": "ZY I ",
    "スィ": "S I ",
    "パァ": "P A ",
    };
table2 = {
    "カ": "K A ",
    "キ": "KY I ",
    "ク": "K U ",
    "ケ": "K E ",
    "コ": "K O ",
    "サ": "S A ",
    "シ": "SY I ",
    "ス": "S U ",
    "セ": "S E ",
    "ソ": "S O ",
    "タ": "T A ",
    "チ": "TY I ",
    "ツ": "TS U ",
    "テ": "T E ",
    "ト": "T O ",
    "ハ": "H A ",
    "ヒ": "HY I ",
    "フ": "F U ",
    "ヘ": "H E ",
    "ホ": "H O ",
    "ナ": "N A ",
    "ニ": "N I ",
    "ヌ": "N U ",
    "ネ": "N E ",
    "ノ": "N O ",
    "マ": "M A ",
    "ミ": "M I ",
    "ム": "M U ",
    "メ": "M E ",
    "モ": "M O ",
    "ラ": "R A ",
    "リ": "R I ",
    "ル": "R U ",
    "レ": "R E ",
    "ロ": "R O ",
    "ヤ": "Y A ",
    "ユ": "Y U ",
    "ヨ": "Y O ",
    "ワ": "W A ",
    "ヲ": "W O ",
    "ン": "n ",
    "ガ": "G A ",
    "ギ": "G I ",
    "グ": "G U ",
    "ゲ": "G E ",
    "ゴ": "G O ",
    "ザ": "Z A ",
    "ジ": "ZY I ",
    "ズ": "Z U ",
    "ゼ": "Z E ",
    "ゾ": "Z O ",
    "ダ": "D A ",
    "ヂ": "ZY I ",
    "ヅ": "Z U ",
    "デ": "D E ",
    "ド": "D O ",
    "バ": "B A ",
    "ビ": "B I ",
    "ブ": "B U ",
    "ベ": "B E ",
    "ボ": "B O ",
    "パ": "P A ",
    "ピ": "PY I ",
    "プ": "P U ",
    "ペ": "P E ",
    "ポ": "P O ",
    "ヴ": "B U ",
    };
table3 = {
    "ア": "A ",
    "イ": "I ",
    "ウ": "U ",
    "エ": "E ",
    "オ": "O ",
    "ッ": "Q ",
    "、": "pau ",
    "，": "pau ",
    };

def kana2phn(token):
# 順番にテーブルを使って変換していく
    ret = token
    if ret in table0:
        ret = table0[ret]
    if ret in table1:
        ret = table1[ret]
    if ret in table2:
        ret = table2[ret]
    if ret in table3:
        ret = table3[ret]
    return ret

def isKana(token):
    pros_list = ['\'', '.', '@', '/', '?', '^']
    return not token in pros_list

def isMuseiHaretsu(token):
    musei_haretsu_list = ['P', 'T', 'K', 'PY', 'TY', 'KY', 'TS',
                          'P^', 'T^', 'K^', 'PY^', 'TY^', 'KY^', 'TS^']
    return token in musei_haretsu_list

def isSilent(token):
    silent_list = ['pau', 'sil']
    return token in silent_list or re.fullmatch(r'Q.*', token) != None

def insertString(tgt, insertStr, idx):
    return tgt[:idx] + insertStr + tgt[idx:]

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

def main(filename, mode, prefix):
#    ID_PREFIX = 'FREE-'
    ID_PREFIX = prefix + '-'
    txt_cnt = 0
    with open(filename, 'r', encoding=guess_charset(filename), errors='backslashreplace') as f:
        for line in f:
# アクセント核'を一つのトークンとして切り分ける
            token_list = line.replace('\'',' \'').split()

            phn_list = ['sil']
            nuclear_passed = False
            HL = 'L'

            for idx, token in enumerate(token_list):
# 句境界が来たらリセット
              is_bound = token == '.' or token == '@' or token == '/' or token == '?'
              if is_bound:
                nuclear_passed = False
                HL = 'L'
# 核がついてたらH
              if idx + 1 < len(token_list) and token_list[idx + 1] == '\'':
                nuclear_passed = True
                HL = 'H'

# 長音の場合，直前の音素を書き換えながら，長音も置き換える
# WARNING: アクセント句の頭に長音が出たらHLとかが狂う
              if token == 'ー':
                back = 1
                if len(phn_list) - back < 0 or phn_list[-back] == 'sil':
                  continue
# アクセント核があった場合更に戻る
                if phn_list[-back] == '\'':
                  back = 2
                if len(phn_list) - back < 0:
                  continue
                last_phn = phn_list[-back]
#                phn_list[-back] = last_phn + '1'
#                phn_list.append(last_phn + '2')
                phn_list[-back] = insertString(last_phn, '1', last_phn.rfind('H|L|/'))
                phn_list.append(insertString(last_phn, '2', last_phn.rfind('H|L|/')))

# 大小ポーズはpauに変換
              elif token == '@' or token == '.':
                phn_list.append('pau')

# カナの場合
              elif isKana(token):
                append_list = (kana2phn(token).split())
# 無声破裂音（P, T, K, PY, TY, KY, TS）のひとつ前の音素が無音（pau, sil, Q（促音））でない場合clを無声破裂音前に挿入
                if isMuseiHaretsu(append_list[0]) and not isSilent(phn_list[-1]):
                  append_list.insert(0, 'cl')

# /を音素にくっつける
                nopause_bound =''
                if idx + 1 < len(token_list) and token_list[idx + 1] == '/':
                 nopause_bound ='/'

# 音素はHLをくっつけて出力
                append_list = [s + nopause_bound + HL for s in append_list]
                phn_list = phn_list + append_list

# 核を過ぎたらL, 過ぎてないならH
              if not is_bound:
                if nuclear_passed:
                  HL = 'L'
                else:
                  HL = 'H'

# 最初か最後でsilとpauが連続する場合，pau削除
            if phn_list[1] == 'pau':
              phn_list.pop(1)
            if phn_list[-1] == 'pau':
              phn_list.pop(-1)
            phn_list.append('sil')
            if mode == 'make_esp_input':
              print(ID_PREFIX + '{:0=4} '.format(txt_cnt), end='')
              txt_cnt += 1
            print(" ".join(phn_list))
    return


if __name__ == "__main__":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    
    parser = argparse.ArgumentParser(description='convert kana + accent to phn + HL')
    parser.add_argument('mode', help='Mode', choices=['kana2phn', 'make_esp_input'])
    parser.add_argument('--input', help='Input kana file', default="test_input.txt")
    parser.add_argument('--prefix', help='prefix', default="FREE")
    args = parser.parse_args()

    main(args.input, args.mode, args.prefix)
