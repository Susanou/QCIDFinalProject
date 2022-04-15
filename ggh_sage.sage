import argparse
import re

class GGH:
    def __init__(self, n, priv_key=None, pub_key=None):
        self.n = n

        if priv_key == None and pub_key == None:
            self.privkey, self.pubkey = self._generate(n)
            self.write_key("pub.key", "priv.key")

        if priv_key != None:
            self.load_private_key(priv_key)
        if pub_key != None:
            self.load_public_key(pub_key)

    def set_keypair(self, R, B):
        self.privkey = R
        self.pubkey = B
        self.n = R.ncols()

    def encrypt(self, m, r=None, delta=3):
        if r == None:
            r = self._random_error_vector(self.n, delta)
        e = m*self.pubkey + r
        return e

    def decrypt(self, e):
        v = self._babais_algorithm(e)
        m = self.pubkey.solve_left(v)
        return m


    def _generate(self, n):
        l = 4
        k = round(sqrt(n)) * l
        I = matrix.identity(n)
        R = random_matrix(ZZ, n, n, x=-l, y=l+1)
        R = R + I*k

        B = R
        for _ in range(4):
            T = self._random_unimodular_matrix(n)
            B = T * B

        return R, B

    def write_key(self, pub_filename, priv_filename):

        with open(pub_filename, "w") as f:
            f.write('\n'.join(' '.join(str(x) for x in row) for row in self.pubkey))
        
        with open(priv_filename, "w") as f:
            f.write('\n'.join(' '.join(str(x) for x in row) for row in self.privkey))
    
    def load_public_key(self, filename):

        data = open(filename, 'r').read()
        rows = [list(int(re.sub(u"\u2212", "-", r)) for r in row.split()) for row in data.splitlines()]

        self.pubkey = Matrix(ZZ, rows)

    def load_private_key(self, filename):
        data = open(filename, 'r').read()
        rows = [list(int(re.sub(u"\u2212", "-", r)) for r in row.split()) for row in data.splitlines()]

        self.privkey = Matrix(ZZ, rows)

    def _babais_algorithm(self, e):
        hRR = RealField(100)
        VV = MatrixSpace(hRR, self.n, self.n)(self.privkey)
        VV.solve_left(e)
        t = vector([int(round(i))  for i in VV.solve_left(e)])
        v = t * self.privkey
        return v

    def _random_unimodular_matrix(self, n):
        U = matrix(ZZ, n, n)
        for r in range(n):
            for j in range(r, n):
                if random() > 0.5:
                    U[r, j] = 1
                else:
                    U[r, j] = -1

        L = matrix(ZZ, n, n)
        for r in range(n):
            for j in range(r+1):
                if random() > 0.5:
                    L[r, j] = 1
                else:
                    L[r, j] = -1

        T = L*U
        return T

    def _random_error_vector(self, n, delta=3):
        r = vector(ZZ, n)
        for i in range(n):
            if random() > 0.5:
                r[i] = delta
            else:
                r[i] = -delta
        return r

def padding(message, n):
    return message + ''.join(['0' for _ in range(n-len(message))])

def test():
    n = 100
    ggh = GGH(n)
    m = vector(ZZ, [i for i in range(n)])
    e = ggh.encrypt(m)
    assert(ggh.decrypt(e) == m)

if __name__ == "__main__":
    #test()

    parser = argparse.ArgumentParser(description = "GGH Implementation. be careful to not use this in any production environnement")

    parser.add_argument('-e', '--encrypt', action="store_true", help='Encrypt message')
    parser.add_argument('-d', '--decrypt', action="store_true", help='Decrypt message')
    parser.add_argument('-n', type=int, help='Dimension of the public and private key. Should be of a longer length than the message')
    parser.add_argument('-f', '--file', help="File containing the message")
    parser.add_argument('-pub', type=str, nargs='?', help="Public key file")
    parser.add_argument('-priv', type=str, nargs='?', help="private key file")
    parser.add_argument('-o', '--output', type=str, help="output file")

    args = parser.parse_args()

    if args.encrypt:
        
        with open(args.file, 'r') as f:
            message = f.read().strip()
        
        if len(message) > args.n:
            parser.print_help()

        ggh = GGH(args.n)
        m = vector(ZZ, [ord(c) for c in padding(message, args.n)])
        #print(m)
        e = ggh.encrypt(m)

        #print(e)

        with open(args.output, "w") as f:
            f.write('\n'.join(str(row) for row in e))
    
    elif args.decrypt and args.priv:
        
        with open(args.file, 'r') as f:
            encrypted = f.read().strip()

            row = [int(re.sub(u"\u2212", "-", row)) for row in encrypted.splitlines()]

        ggh = GGH(args.n, args.priv, args.pub)

        e = vector(ZZ, row)
        d = ggh.decrypt(e)

        print(d)

        with open(args.output, "w") as f:
            f.write(''.join(chr(i) for i in d))
    else:
        parser.print_help()