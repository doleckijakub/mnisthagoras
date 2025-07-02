mnisthagoras: src/main.cu
	nvcc -o $@ $^

MNIST_URL := https://storage.googleapis.com/cvdf-datasets/mnist

GZ_FILES := \
	data/train-images-idx3-ubyte.gz \
	data/train-labels-idx1-ubyte.gz \
	data/t10k-images-idx3-ubyte.gz \
	data/t10k-labels-idx1-ubyte.gz

UNZIPPED_FILES := $(patsubst %.gz, %, $(GZ_FILES))

.PHONY: run
run: mnisthagoras $(UNZIPPED_FILES)
	./mnisthagoras

data:
	mkdir -p $@

$(GZ_FILES): data/%.gz: | data
	@if [ ! -f $@ ]; then \
		echo "Downloading $(notdir $@)"; \
		wget -q $(MNIST_URL)/$(notdir $@) -O $@; \
	fi

$(UNZIPPED_FILES): data/%: data/%.gz
	@if [ ! -f $@ ] || [ $< -nt $@ ]; then \
		echo "Extracting $(notdir $<)"; \
		cd data && gunzip -fk $(notdir $<); \
	fi

.PHONY: clean
clean:
	rm -rf data
	rm -f mnisthagoras