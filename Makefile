mnisthagoras: src/main.cpp
	g++ -o $@ $^

draw: mnisthagoras data/train-images-idx3-ubyte
	./mnisthagoras

data:
	mkdir -p $@

data/train-images-idx3-ubyte.gz: data
	$(shell [ ! -f $@ ] && wget https://storage.googleapis.com/cvdf-datasets/mnist/train-images-idx3-ubyte.gz -O $@)

data/train-labels-idx1-ubyte.gz: data
	$(shell [ ! -f $@ ] && wget https://storage.googleapis.com/cvdf-datasets/mnist/train-labels-idx1-ubyte.gz -O $@)

data/train-images-idx3-ubyte: data/train-images-idx3-ubyte.gz
	cd data && gunzip train-images-idx3-ubyte.gz

data/train-labels-idx1-ubyte: data/train-labels-idx1-ubyte.gz
	cd data && gunzip train-labels-idx1-ubyte.gz
