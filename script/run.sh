cd ../fm
make
cd ../gbdt
make
cd ../script

# == 统计得到用户和一些特征的交叉计数特征。注意避免了时间穿越
pypy addc.py   # train -> train_c: accumulate count feature for hour/day, 生成 train_c: user_id, hour/day count of user_id*C14 and user_id*C17, day count of app_id/site_id. 注意对于count，是随时间累加式的. 本步骤只是附加新的conut特征

# == 筛选出特征的低频取值
pypy fcount.py # ./train -> fc '特征名与取值组合'的频次统计. 只留下频次>10的. 因为特征的低频取值没毛用

# == 筛选出低频用户
pypy rare.py   # ./train_c -> rare_d. 筛选出低频用户, 因为低频用户没法根据其id来作为特征做有效预测

# == 得到用户的活跃天数(不同活跃度的用户，大概有不同含义吧)
pypy id_day.py # train_c -> id_day: for device_ip, user_id, get count of days they exist, 也就是得到不同粒度的用户id，一共有多少天有行为数据

# == 主要内容：低频特征归一化，所有特征离散化
#     具体来说：
#     对于几种层次的userid，如果是低频用户，则按出现次数对低频用户分组（通过直接取代原来的userid的方式）
#     对于其他特征，则是所有低频特征统一置为相同的值。
#     需要注意的是，作者把疑似可能不是categorial的特征，以及新添加的count特征，全都按categorial特征做了转化，
pypy prep.py # train_c + fc + rare_d + id_day => train_pre: 重新生成样本数据train_pred。对于 device_id, device_ip, user_id 三个字段，如果是rare值，则生成计数特征；对于 user_id，如果只出现在一天，则统一记为v_id_s取值的特征

# == 对不同粒度的userid，统计其出现频次
pypy id_stat.py # train_c -> id_stat: for device_ip, user_id, get count info for every value

# == 生成gbdt训练集。样本是train_c中新引入的交叉计数特征，以及不同粒度用户的计数特征
#    注意直接用这些计数特征，没有做任何特征归一化等处理
pypy gbdt_dense.py # 从 train_c + id_stat => train_dense , 给gbdt用。用C23~28 6个特征，以及device_id, user_id 统计计数

# == count特征过大的归一化到max，且既然所有特征都离散化了(包括count特征)，所以全转化为one-hot表示
pypy index1.py # train_pre => fm_train_1, 对某些count特征，如果count超过某个值，则统一归一化到max
pypy index2.py # train_pre => fm_train_1_{1,2}, 特征处理同上，但是分app/site数据分别训练. 和4傻一样

# == gbdt 训练，抽取gbdt特征。所抽取的都是one-hot特征
#    注意，tree 个数是多少，gbdt抽取的特征就是多少维。这是因为，gbdt预测时，每棵树只有一个位置会走到。
#    所以这棵树上，只需要记录下走到的是哪个节点即可。虽然这里抽取得到的特征是19维的，但是其实每一维都是one-hot的
#    所以其背后所表示特征维度其实远不止19
../gbdt/gbdt -d 5 -t 19 ../test_dense ../train_dense ../test_gbdt_out ../train_gbdt_out

# fm model 1

# == 附加gbdt抽取的特征。fm_train_1中已经全部one-hot化了，所以这里就是简单地添加更多one-hot
pypy append_gbdt.py # 添加 gbdt 特征 fm_train_1 + test_gbdt_out => fm_train_2

# == note: fm_test_2 与 fm_train_2中的特征都是one-hot特征
../fm/fm -k 8 -t 5 -l 0.00003 ../fm_test_2 ../fm_train_2

# fm model 2
pypy append_gbdt_1.py # train_pre + test_gbdt_out => fm_train_2_1. 数据分为 app/site, 后七个特征处理同上
../fm/fm -k 8 -t 4 -l 0.00004 ../fm_test_2_1 ../fm_train_2_1
../fm/fm -k 8 -t 10 -l 0.00005 ../fm_test_2_2 ../fm_train_2_2
pypy split.py ../fm_test_2_split ../fm_test_2_1.out ../fm_test_2_2.out # 其实是把app/site两份结果merge 到 ../fm_test_2_split

# ftrl model prepare
# == 与 prep.py 大同小异
pypy prep_1.py # train_c + fc + rare_d + id_day =>train_pre_1, for device_id, device_ip, C22(user_id)等userid特征 低频归count特征; 其他特征是低频归一.同时添加 user_id 的出现天数特征
pypy append.py # train_pre_1 + gbdtoutput => train_pre_1b
pypy genDict.py # 统计 train_c 中 site_category(site_id == NULL时,考虑app_category) 被多少去重后ip访问.
pypy genM.py # 结合上一个，给出 site_category ~ device_ip 的 tf-idf 稀疏矩阵. ip 当doc，site_category当word. 
python lsa.py # LSA 得到 IP向量, 返回每个ip向量中取最大值的那个下标，相当于 max_pooling

# ftrl model 1
# == 特征组合, 并hash trick。
#    输入特征没有one-hot化，因为内部还会作特征交叉，然后用hash trick来one-hot化
pypy ftrl_1.py # train_pre_1b + testcase -> ftrl_1; 用到了特征组合. LSA特征用于此

# ftrl model 2
pypy ftrl_2.py # train_pre_1b -> ftrl_2; 分别训练app、site各一个模型; 特征组合

# ensemble
pypy ensemble.py # p = sigmoid(sum(w_i*rev_sigmoid(p_model_i)))
