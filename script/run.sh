cd ../fm
make
cd ../gbdt
make
cd ../script

pypy addc.py   # train -> train_c: accumulate count feature for hour/day, 生成 train_c: user_id, hour/day count of user_id*C14 and user_id*C17, day count of app_id/site_id. 注意对于count，是随时间累加式的
pypy fcount.py # ./train -> fc非低频特征计数. get all feature value with count >= 10
pypy rare.py   # ./train_c -> rare_d 低频特征统计: for device_id, device_ip, C22(user_id) feature, get all fea with count <10
pypy id_day.py # train_c -> id_day: for device_ip, user_id, get count of days they exist 
pypy prep.py # 重新生成样本数据train_pred。对于 device_id, device_ip, user_id 三个字段，如果是rare值，则生成计数特征；对于 user_id，如果只出现在一天，则统一记为v_id_s取值的特征
pypy id_stat.py # for device_ip, user_id, get count info for every value
pypy gbdt_dense.py # 从 train_c 生成train_dense 给 gbdt 用。用C23~28 6个特征，以及device_id, user_id 统计计数
pypy index1.py # train_pre => fm_train_1, 后七个特征：高频取值的取值统一化，低频的按count分类取值
pypy index2.py # train_pre => fm_train_1_{1,2}, 后七个特征处理同上，但是分app/site数据分别训练. 和4傻一样
../gbdt/gbdt -d 5 -t 19 ../test_dense ../train_dense ../test_gbdt_out ../train_gbdt_out

# fm model 1
pypy append_gbdt.py # 添加 gbdt 特征 fm_train_1 + test_gbdt_out => fm_train_2
../fm/fm -k 8 -t 5 -l 0.00003 ../fm_test_2 ../fm_train_2

# fm model 2
pypy append_gbdt_1.py # train_pre + test_gbdt_out => fm_train_2_1. 数据分为 app/site, 后七个特征处理同上
../fm/fm -k 8 -t 4 -l 0.00004 ../fm_test_2_1 ../fm_train_2_1
../fm/fm -k 8 -t 10 -l 0.00005 ../fm_test_2_2 ../fm_train_2_2
pypy split.py ../fm_test_2_split ../fm_test_2_1.out ../fm_test_2_2.out # 其实是把app/site两份结果merge 到 ../fm_test_2_split

# ftrl model prepare
pypy prep_1.py # train_c =>train_pre_1, for device_id, device_ip, C22(user_id), 低频归count特征, 其他特征低频归一；添加 user_id 的出现天数特征
pypy append.py # train_pre_1 + gbdtoutput => train_pre_1b
pypy genDict.py # 统计 train_c 中 site_category(site_id == NULL时,考虑app_category) 被多少去重后ip访问.
pypy genM.py # 结合上一个，给出 site_category ~ device_ip 的 tf-idf 稀疏矩阵. ip 当doc，site_category当word. 
python lsa.py # LSA 得到 IP向量, 返回每个ip向量中取最大值的那个下标，相当于 max_pooling

# ftrl model 1
pypy ftrl_1.py # train_pre_1b + testcase -> ftrl_1; 用到了特征组合

# ftrl model 2
pypy ftrl_2.py # train_pre_1b -> ftrl_2; 分别训练app、site各一个模型; 特征组合

# ensemble
pypy ensemble.py # p = sigmoid(sum(w_i*rev_sigmoid(p_model_i)))
