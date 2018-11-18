from collections import defaultdict
import marshal

f_train = "../train"
f_test = "../test"
o_train = "../train_c"
o_test = "../test_c"


def get_id(id,ip,device):
    if id != "i_a99f214a":
        return id
    else:
        return ip + "_" + device

def run(input,output,isTest):
	f = open(input)
	o = open(output,"w")
	d = defaultdict(int)
	d2 = {}
	dh = defaultdict(int)
	line = f.readline()
	print >> o,line[:-2] + ",C22,C23,C24,C25,C26,C27,C28"
	count = 0
	day = "??"
	hour = "??"
	date_idx = 2
	if isTest:
		date_idx = 1
	while True:
		line = f.readline()
		if not line:
			break
		count += 1
		if count % 100000 == 0:
			print count
		lis = line.split(",")
		if lis[date_idx][4:6] != day:
            # 跨天，则清空
			del d
			d = defaultdict(int)
			d2 = {}
			day = lis[date_idx][4:6]
		if lis[date_idx][6:] != hour:
			del dh
			dh = defaultdict(int)
			hour = lis[date_idx][6:]
		time = int(lis[date_idx][6:]) * 60 + int(int(lis[0][:5]) / 100000. * 60)
		id = get_id("i_"+lis[date_idx+9],"j_"+lis[date_idx+10],"k_"+lis[date_idx+11])
        # ZMC: id: 等于是 user_id
        # ZMC: 得到用户id 和不同特征的组合下的出现次数
		d [id + "_n_" + lis[date_idx+14]] += 1
		d [id + "_q_" + lis[date_idx+17]] += 1
		dh[id + "_n_" + lis[date_idx+14]] += 1
		dh[id + "_q_" + lis[date_idx+17]] += 1
        # ZMC: 最近1小时内的用户被广告show的次数
		dh[id] += 1
		
		media_id = "f_"+lis[date_idx+6] 
		if lis[date_idx+6] == "ecad2386": # app_id
			media_id = "c_"+lis[date_idx+3] # site_id
        # ZMC: 最近1天内用户访问媒体(app或site)的次数
		d[id + "_" + media_id] += 1
		t = "-1"

		if id not in d2:
			d2[id] = time
		else:
			t = str(time-d2[id])
			d2[id] = time

        # ZMC: 得到到本条数据为止的统计数，作为特征. 注意这样可以避免特征的时间穿越
		m =    d[id + "_"   + media_id]
		c =    d[id + "_n_" + lis[date_idx+14]]
		c2 =   d[id + "_q_" + lis[date_idx+17]]
		ch =  dh[id + "_n_" + lis[date_idx+14]]
		ch1 = dh[id + "_q_" + lis[date_idx+17]]
		ch2 = dh[id]
		print >> o,line[:-2] + "," + id + "," + str(m) + "," + str(ch1) + "," + str(ch2) + "," +  str(c) + "," + str(c2) + "," + t
	f.close()
	o.close()

run(f_train,o_train,False)
run(f_test,o_test,True)
