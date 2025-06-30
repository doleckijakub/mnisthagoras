mnisthagoras: src/main.cpp
	g++ -o $@ $^

draw: mnisthagoras data/train-images-idx3-ubyte
	./mnisthagoras

data:
	mkdir -p $@

data/train-images-idx3-ubyte.gz: data
	$(shell [ ! -f data/train-images-idx3-ubyte.gz ] && wget https://storage.googleapis.com/cvdf-datasets/mnist/train-images-idx3-ubyte.gz -O $@)

data/train-images-idx3-ubyte: data/train-images-idx3-ubyte.gz
	cd data && gunzip train-images-idx3-ubyte.gz