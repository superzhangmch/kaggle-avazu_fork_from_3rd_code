import numpy as np
from sklearn.decomposition import TruncatedSVD
import marshal

d = marshal.load(open("../ip_mat"))

X = []
l = []
for x in d:
    # x: ip
    l.append(x)
    X.append(d[x])
X = np.array(X)

svd = TruncatedSVD(n_components = 16, random_state=42)
X = svd.fit_transform(X)
# X 是 ip 向量(相当于是doc向量)

print X.shape

for i in xrange(len(l)):
    d[l[i]] = int(np.argmax(X[i])) # 取最大值的下标, like max-pooling
marshal.dump(d,open("../testcate","w"))
