#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <vector>

#define IMG_W 28
#define IMG_H 28

#define IMG_C 60000

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

uint8_t *readDataset(const char *dataset_filepath) {
    FILE *fp = fopen(dataset_filepath, "rb");
    uint8_t *data = nullptr;

    if (!fp) goto error;

    {
        uint32_t magic_number = readBigEndianUInt32(fp);
        uint32_t num_images   = readBigEndianUInt32(fp);
        uint32_t num_rows     = readBigEndianUInt32(fp);
        uint32_t num_cols     = readBigEndianUInt32(fp);

        if (magic_number != 2051) goto error;
        if (num_images != IMG_C) goto error;
        if (num_cols != IMG_W) goto error;
        if (num_rows != IMG_H) goto error;
    }

    #define DATA_SIZE (IMG_C * IMG_SIZE)
    data = new uint8_t[DATA_SIZE];
    if (fread(data, 1, DATA_SIZE, fp) != DATA_SIZE) goto error;
    #undef DATA_SIZE

    fclose(fp);

    return data;

error:

    perror("Error reading dataset");
    if (fp) fclose(fp);
    if (data) delete[] data;
    return nullptr;
}

uint8_t *readLabels(const char *labels_filepath) {
    FILE *fp = fopen(labels_filepath, "rb");
    uint8_t *labels = nullptr;

    if (!fp) goto error;

    {
        uint32_t magic_number = readBigEndianUInt32(fp);
        uint32_t num_labels   = readBigEndianUInt32(fp);

        if (magic_number != 2049) goto error;
        if (num_labels != IMG_C) goto error;
    }

    labels = new uint8_t[IMG_C];
    if (fread(labels, 1, IMG_C, fp) != IMG_C) goto error;

    fclose(fp);
    return labels;

error:

    perror("Error reading labels");
    if (fp) fclose(fp);
    if (labels) delete[] labels;
    return nullptr;
}

int main(int argc, const char **argv) {
    uint8_t *dataset = readDataset("data/train-images-idx3-ubyte");
    if (!dataset) return 1;

    uint8_t *labels = readLabels("data/train-labels-idx1-ubyte");
    if (!labels) return 2;

    for (int i = 0; i < IMG_C; i++) {
        printf("%d", labels[i]);

        for (uint32_t r = 0; r < 28; r++) {
            for (uint32_t c = 0; c < 28; c++) {
                uint8_t pixel = dataset[IMG_SIZE * i + r * 28 + c];
                for (int i = 0; i < 2; i++) {
                    printf("%c", pixelToChar(pixel));
                }
            }
            printf("\n");
        }
    }

    return 0;
}