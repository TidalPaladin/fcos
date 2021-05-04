# FCOS

My implementation of a variant of [FCOS](https://arxiv.org/abs/1904.01355v5). FCOS is a fully convolutional
one-stage object detector. My implementation uses [EfficientDet](https://arxiv.org/abs/1911.09070) as a backbone.
The EfficientDet backbone implementation is provided [here](https://github.com/rwightman/efficientdet-pytorch).

## Training

Setup instructions are as follows:

  1. Run `make init` to clone submodules and set up a virtual environment.
  2. Edit [`coco.yaml`](conf/dataset/coco.yaml) to specify dataset location
  3. Edit [`local.yaml`](conf/trainer/local.yaml) to specify output location
  4. Edit [`fcos.yaml`](conf/model/fcos.yaml) to change model properties
