#!/usr/bin/env python
import marshal

f = open("../train")
f2 = open("../test")
fc = open("../fc","w")

d = {}
count = 0
line = f.readline()
while True:
    line = f.readline()
    if not line:
        break
    count += 1
    if count % 100000 == 0:
        print count
    lis = line[:-2].split(",")
    for i in xrange(3,len(lis)):
        # zmc: 特征名
        name = chr(ord('a') + i - 3)
        # zmc: 特证名与特征值拼接
        feat = name + "_" + lis[i]
        # zmc: 对‘特证名与特征值拼接’做计数统计
        if feat in d:
            d[feat] += 1
        else:
            d[feat] = 1

count = 0
line = f2.readline()
while True:
    line = f2.readline()
    if not line:
        break
    count += 1
    if count % 100000 == 0:
        print count
    lis = line[:-2].split(",")
    for i in xrange(2,len(lis)):
        name = chr(ord('a') + i - 2)
        feat = name + "_" + lis[i]
        if feat in d:
            d[feat] += 1
        else:
            d[feat] = 1

s = []
dd = {}
for x in d:
    # zmc, only reserve count(.) >= 10
    if d[x] >= 10:
        s.append(x)
marshal.dump(set(s),fc)
