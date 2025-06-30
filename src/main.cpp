#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <iostream>
#include <vector>

char pixelToChar(uint8_t pixel) {
    const char* levels = " .:-=+*#%@";
    int index = pixel * 10 / 256;
    return levels[index];
}

uint32_t readBigEndianUInt32(FILE* file) {
    uint8_t bytes[4];
    if (fread(bytes, 1, 4, file) != 4) {
        std::cerr << "Failed to read 4 bytes\n";
        return 0;
    }
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}

int main(int argc, const char **argv) {
    FILE* file = fopen("data/train-images-idx3-ubyte", "rb");
    if (!file) {
        perror("Error opening file");
        return -1;
    }

    uint32_t magic_number = readBigEndianUInt32(file);
    uint32_t num_images   = readBigEndianUInt32(file);
    uint32_t num_rows     = readBigEndianUInt32(file);
    uint32_t num_cols     = readBigEndianUInt32(file);

    if (magic_number != 2051) {
        std::cerr << "Invalid MNIST image file! Magic: " << magic_number << "\n";
        fclose(file);
        return -1;
    }

    size_t image_size = num_rows * num_cols;
    std::vector<uint8_t> image(image_size);

    if (fread(image.data(), 1, image_size, file) != image_size) {
        std::cerr << "Failed to read image data.\n";
        fclose(file);
        return -1;
    }

    for (uint32_t r = 0; r < num_rows; r++) {
        for (uint32_t c = 0; c < num_cols; c++) {
            uint8_t pixel = image[r * num_cols + c];
            std::cout << pixelToChar(pixel);
        }
        std::cout << "\n";
    }

    fclose(file);

}