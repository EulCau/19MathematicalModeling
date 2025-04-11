import torch.nn as nn

class InsectClassifier(nn.Module):
	def __init__(self, input_dim=2, hidden_dims=None, output_dim=3, activation='relu'):
		super(InsectClassifier, self).__init__()
		if hidden_dims is None:
			hidden_dims = [16, 32]
		layers: list[nn.Module] = []
		dims = [input_dim] + hidden_dims

		act_fn = {
			'relu': nn.ReLU(),
			'tanh': nn.Tanh(),
			'sigmoid': nn.Sigmoid()
		}[activation]

		for i in range(len(dims)-1):
			layers.append(nn.Linear(dims[i], dims[i+1]))
			layers.append(act_fn)
		layers.append(nn.Linear(dims[-1], output_dim))

		self.model = nn.Sequential(*layers)

	def forward(self, x):
		return self.model(x)
