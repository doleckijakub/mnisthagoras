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
    FILE *fp = fopen("data/train-images-idx3-ubyte", "rb");
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

    if (fp) fclose(fp);
    if (data) delete[] data;
    return nullptr;
}

int main(int argc, const char **argv) {
    uint8_t *dataset = readDataset("data/train-images-idx3-ubyte");
    if (!dataset) return 1;

    for (uint32_t r = 0; r < 28; r++) {
        for (uint32_t c = 0; c < 28; c++) {
            uint8_t pixel = dataset[r * 28 + c];
            printf("%c", pixelToChar(pixel));
        }
        printf("\n");
    }

    return 0;
}