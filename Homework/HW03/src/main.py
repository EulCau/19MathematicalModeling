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


def main(X_train, y_train, X_test, y_test):
	# 实验参数
	params = {
		'hidden_dims': [16, 32, 64],
		'activation': 'relu',
		'lr': 1e-3,
		'epochs': 100,
		'batch_size': 32
	}

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
	X_test_1 = X_test[:60]
	y_test_1 = y_test[:60]
	X_test_2 = X_test[60:]
	y_test_2 = y_test[60:]

	with torch.no_grad():
		predict = model(X_test_1).argmax(dim=1)
		acc = torch.eq(predict, y_test_1).float().mean().item()
		print(f"Test Accuracy first 60: {acc:.4f}")

	with torch.no_grad():
		predict = model(X_test_2).argmax(dim=1)
		acc = torch.eq(predict, y_test_2).float().mean().item()
		print(f"Test Accuracy last 150: {acc:.4f}")

	with torch.no_grad():
		predict = model(X_test).argmax(dim=1)
		acc = torch.eq(predict, y_test).float().mean().item()
		print(f"Test Accuracy all: {acc:.4f}")


if __name__ == '__main__':
	X_train_, y_train_ = load_data('../data/insects/insects-training.txt')
	X_test_, y_test_ = load_data('../data/insects/insects-testing.txt')
	main(X_train_, y_train_, X_test_, y_test_)

	X_train_, y_train_ = load_data('../data/insects/insects-2-training.txt')
	X_test_, y_test_ = load_data('../data/insects/insects-2-testing.txt')
	main(X_train_, y_train_, X_test_, y_test_)
