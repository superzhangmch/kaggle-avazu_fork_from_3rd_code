分析此代码有如下值得学习的地方：
- 原始数据是时间序列类型的，应该不随便打乱这种顺序。拆分训练、验证、测试集的时候不应该打乱后拆，而应该按时间拆分。而且，得到计数count特征的时候，也应该反映时间性：比如可以统计一些feature在不同时间段（小时、天）的计数；即使在同一个时间段内，可以得到总计数，但也可以“针对单个样本得到截止该样本时间点的该时间段内的计数”（script/addc.py中就是这样处理的）


以下是原始 README.md
------------
Random Walker's solution for Avazu Click-Through rate prediction

The introduction of our approach could be found in doc.pdf.

System Requirement
------------------
- 64-bit Unix-like os
- Python 2.7
- g++
- pypy
- sklearn
- at least 20GB memory and 50GB disk space

To reproduce our submission:
-------------------
- Download tha data("train" and "test") to this folder.
- Change directory to script:
	cd script
- Run the code:
	./run.sh
