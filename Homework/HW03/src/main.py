import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
from fnn_builder import InsectClassifier

# 读取数据函数

def load_data(path):
	data = np.loadtxt(path)
	X = data[:, :2].astype(np.float32)
	y = data[:, 2].astype(np.int64)
	return torch.tensor(X), torch.tensor(y)

# 实验参数
params = {
	'hidden_dims': [16, 32, 64],
	'activation': 'relu',
	'lr': 1e-3,
	'epochs': 100,
	'batch_size': 32
}

# 加载数据
X_train, y_train = load_data('../data/insects/insects-training.txt')
X_test, y_test = load_data('../data/insects/insects-testing.txt')

# 数据加载器
train_dataset = TensorDataset(X_train, y_train)
train_loader = DataLoader(train_dataset, batch_size=params['batch_size'], shuffle=True)

# 模型实例化
model = InsectClassifier(hidden_dims=params['hidden_dims'], activation=params['activation'])
optimizer = optim.Adam(model.parameters(), lr=params['lr'])
criterion = nn.CrossEntropyLoss()

# 训练模型
for epoch in range(params['epochs']):
	model.train()
	loss = float('nan')
	for X_batch, y_batch in train_loader:
		optimizer.zero_grad()
		output = model(X_batch)
		loss = criterion(output, y_batch)
		loss.backward()
		optimizer.step()
	if (epoch + 1) % 10 == 0:
		print(f"Epoch {epoch+1}, Loss: {loss.item():.4f}")

# 测试模型
model.eval()
with torch.no_grad():
	predict = model(X_test).argmax(dim=1)
	acc = torch.eq(predict, y_test).float().mean().item()
	print(f"Test Accuracy: {acc:.4f}")
