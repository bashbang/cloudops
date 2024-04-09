#!/opt/conda/bin/python

import torch

def main():
    # Define a tensor with "Hello, World!" string
    hello_tensor = torch.tensor([72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33])

    # Convert tensor to string
    hello_string = ''.join([chr(char) for char in hello_tensor])

    print(hello_string)

if __name__ == "__main__":
    main()