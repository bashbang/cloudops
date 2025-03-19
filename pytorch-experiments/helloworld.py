#!/opt/conda/bin/python

import torch
import numpy

def main():
    # Define a tensor with "Hello, World!" string
    helloworld_array = numpy.array([72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33])
    tensor_array = torch.from_numpy(helloworld_array)

    print(tensor_array)

if __name__ == "__main__":
    main()