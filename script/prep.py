#encoding:utf8
import marshal
import sys

ftr = "../train_c"
fte = "../test_c"
fset = marshal.load(open("../fc"))
rare_d = marshal.load(open("../rare_d"))
ftrain = "../train_pre"
ftest = "../test_pre"

id_day = marshal.load(open("../id_day"))

def prep(input,output,isTest):
    f = open(input)
    out = open(output,"w")
    line = f.readline()
    print >> out,line[:-1]
    count = 0
    bias = 3
    if isTest:
        bias = 2
    while True:
        line = f.readline()
        if not line:
            break
        count += 1
        if count % 100000 == 0:
            print count
        lis = line[:-1].split(",")
        uid = "??"
        for i in xrange(bias,len(lis)):
            name = chr(ord('a') + i - bias)
            # zmc: 下面的j，i，v是不同粒度的userid
            if name == "j":
                ip = name + "_" + lis[i]
                rare = rare_d.get(ip)
                if rare != None:
                    # zmc: 如果该userid是低频用户，则用用户的出现次数来分用户，所有出现次数都一样的统一分配一个id
                    lis[i] = "j_rare_" + str(rare)
                    #print lis[i]
                    continue
            if name == "i":
                id = name + "_" + lis[i]
                rare = rare_d.get(id)
                if rare != None:
                    lis[i] = "i_rare_" + str(rare)
                    #print lis[i]
                    continue
            if name == "v":
                id = name + "_" + lis[i]
                uid = id
                rare = rare_d.get(id)
                if rare != None:
                    lis[i] = "v_rare_" + str(rare)
                    continue
                elif id_day.get(id) == 1:
                    # zmc: 对于该userid，即使其不是低频用户，如果活跃天数是1天，仍然对用户id作改写
                    lis[i] = "v_id_s"
                    continue
            if name + "_" + lis[i] not in fset and i < len(lis) - 6:
                # zmc: fset 中是非低频特征值，故如果不在其中，也就是属于低频特征值，则统一改写特征值
                # zmc: 原始特征中的倒数那几列特征，都是int数字，因为不知道具体含义，有可能不是categorial特征，但是至少这里，把这类特征也当做categorial了，或者说把所有特征都当做categorial处理了. 其实从else可以知道，就连新生成的技术特征，作者都直接给按原本的count数值离散了
                lis[i] = name + "_rare"
            else:
                lis[i] = name + "_" + lis[i]
        # zmc: 添加userid的活跃天数这样一个特征
        lis.append("id_day_"+str(id_day[uid]))
        print >> out,",".join(lis)
    f.close()
    out.close()

prep(ftr,ftrain,False)
prep(fte,ftest,True)
