#include <cuda_runtime.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <vector>

#define IMG_W 28
#define IMG_H 28

#define IMG_C 60000
#define IMG_C_TEST 10000

#define IMG_SIZE (IMG_W * IMG_H)

char pixelToChar(uint8_t pixel) {
    const char* levels = " .:-=+*#%@";
    int index = pixel * 10 / 256;
    return levels[index];
}

uint32_t readBigEndianUInt32(FILE* fp) {
    uint8_t bytes[4];
    if (fread(bytes, 1, 4, fp) != 4) {
        fprintf(stderr, "Failed to read 4 bytes\n");
        return 0;
    }
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}

uint8_t *readDataset(const char *dataset_filepath, uint32_t &num_images) {
    FILE *fp = fopen(dataset_filepath, "rb");
    uint8_t *data = nullptr;

    if (!fp) goto error;

    {
        uint32_t magic_number = readBigEndianUInt32(fp);
        num_images            = readBigEndianUInt32(fp);
        uint32_t num_rows     = readBigEndianUInt32(fp);
        uint32_t num_cols     = readBigEndianUInt32(fp);

        if (magic_number != 2051) goto error;
        if (num_cols != IMG_W) goto error;
        if (num_rows != IMG_H) goto error;
    }

    data = new uint8_t[num_images * IMG_SIZE];
    if (fread(data, 1, num_images * IMG_SIZE, fp) != num_images * IMG_SIZE) goto error;

    fclose(fp);

    return data;

error:

    perror("Error reading dataset");
    if (fp) fclose(fp);
    if (data) delete[] data;
    return nullptr;
}

uint8_t *readLabels(const char *labels_filepath, uint32_t &num_labels) {
    FILE *fp = fopen(labels_filepath, "rb");
    uint8_t *labels = nullptr;

    if (!fp) goto error;

    {
        uint32_t magic_number = readBigEndianUInt32(fp);
        num_labels            = readBigEndianUInt32(fp);

        if (magic_number != 2049) goto error;
    }

    labels = new uint8_t[num_labels];
    if (fread(labels, 1, num_labels, fp) != num_labels) goto error;

    fclose(fp);
    return labels;

error:

    perror("Error reading labels");
    if (fp) fclose(fp);
    if (labels) delete[] labels;
    return nullptr;
}

__global__ void computeDistances(const uint8_t *dataset, const uint8_t *query, uint32_t *distances) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < IMG_C) {
        uint32_t sum = 0.0f;
        for (int i = 0; i < IMG_SIZE; i++) {
            uint32_t diff = dataset[idx * IMG_SIZE + i] - query[i];
            sum += diff * diff;
        }
        distances[idx] = sum;
    }
}

int findMinIndex(const uint32_t *distances, int size) {
    uint32_t min_val = UINT32_MAX;
    int min_idx = -1;
    for (int i = 0; i < size; i++) {
        if (distances[i] < min_val) {
            min_val = distances[i];
            min_idx = i;
        }
    }
    return min_idx;
}

int main(int argc, const char **argv) {
    uint32_t num_images_dataset = 0;
    uint8_t *dataset = readDataset("data/train-images-idx3-ubyte", num_images_dataset);
    if (!dataset || num_images_dataset != IMG_C) return 1;

    uint32_t num_labels_dataset = 0;
    uint8_t *labels = readLabels("data/train-labels-idx1-ubyte", num_labels_dataset);
    if (!labels || num_labels_dataset != IMG_C) return 2;

    uint32_t num_images_test = 0;
    uint8_t *dataset_test = readDataset("data/t10k-images-idx3-ubyte", num_images_test);
    if (!dataset_test || num_images_test != 10000) return 3;
    
    uint32_t num_labels_test = 0;
    uint8_t *labels_test = readLabels("data/t10k-labels-idx1-ubyte", num_labels_test);
    if (!labels_test || num_labels_test != IMG_C_TEST) return 4;

    uint8_t *d_dataset, *d_query;
    uint32_t *d_distances;
    cudaMalloc(&d_dataset, IMG_C * IMG_SIZE);
    cudaMalloc(&d_query, IMG_SIZE);
    cudaMalloc(&d_distances, IMG_C * sizeof(uint32_t));

    cudaMemcpy(d_dataset, dataset, IMG_C * IMG_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_query, dataset_test, IMG_SIZE, cudaMemcpyHostToDevice);

    int threadsPerBlock = 256;
    int blocksPerGrid = (IMG_C + threadsPerBlock - 1) / threadsPerBlock;

    computeDistances<<<blocksPerGrid, threadsPerBlock>>>(d_dataset, d_query, d_distances);

    uint32_t *distances = new uint32_t[IMG_C];
    cudaMemcpy(distances, d_distances, IMG_C * sizeof(uint32_t), cudaMemcpyDeviceToHost);

    int nearestIdx = findMinIndex(distances, IMG_C);
    printf("Guess: %d\n", labels[nearestIdx]);
    printf("Actual: %d\n", labels_test[0]);

    return 0;
}