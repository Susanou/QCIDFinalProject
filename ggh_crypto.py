import math
import random
import numpy as np
from random import randint
import base64
import binascii
from scipy import linalg

def rand_unimod(n):
    """Function to create a random unimodular matrix to use in the transformation of the public key

    Parameters
    ----------
    n : int
        size of the matrix

    Returns
    -------
    np.array
        unimodular matrix
    """

    random_matrix = [ [np.random.randint(-10,10,) for _ in range(n) ] for _ in range(n) ]
    upperTri = np.triu(random_matrix,0)
    lowerTri = [[np.random.randint(-10,10) if x<y else 0 for x in range(n)] for y in range(n)]  

    #we want to create an upper and lower triangular matrix with +/- 1 in the diag  
    for r in range(len(upperTri)):
    	for c in range(len(upperTri)):
            if(r==c):
                if bool(random.getrandbits(1)):
                    upperTri[r][c]=1
                    lowerTri[r][c]=1
                else:
                    upperTri[r][c]=-1
                    lowerTri[r][c]=-1
    uniModular = np.matmul(upperTri,lowerTri);
    return uniModular

def hamdamard_ratio(basis,dimension):
    """Function used to measure the orthogonality of the matrix

    Parameters
    ----------
    basis : np.array
        basis matrix used
    dimension : int
        size of the basis

    Returns
    -------
    float
        ratio representing the orthogonality of the input basis
    """
    det_of_lattice = np.linalg.det(basis)
    mult=1
    for v in basis:
        mult = mult * np.linalg.norm(v)
    hratio = (det_of_lattice / mult) ** (1.0/dimension)
    return hratio

def key_pair_generation(n):
    """Creates a public-private key pair of size nxn

    Parameters
    ----------
    n : int
        size of the private key
    """

    private_key = linalg.orth(np.random.random_integers(-10,10,size=(n,n))).astype(int)
    ratio = 1

    public_key = None

    while public_key == None:
        bad_vector = rand_unimod(n)
        tmp = np.matmul(private_key, bad_vector)

        ratio = hamdamard_ratio(tmp, n)

        if ratio <= .1:
            public_key = tmp
    
    return private_key, public_key, bad_vector