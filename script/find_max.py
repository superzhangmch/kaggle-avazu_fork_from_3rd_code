import sys
max_val = 0
i = 0
for line in open(sys.argv[1]):
    i += 1
    if i % 1000000 == 0:
        print i, max_val
    LL = line.strip().split(" ")
    LL = [int(L) for L in LL]
    m = max(LL)
    if m > max_val:
        max_val = m
print "--"
print m
