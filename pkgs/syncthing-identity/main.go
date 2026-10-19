package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base32"
	"encoding/pem"
	"flag"
	"fmt"
	"math/big"
	"os"
	"strings"
	"time"
)

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

func main() {
	host := flag.String("host", "", "hostname")
	certPath := flag.String("cert", "", "cert.pem output")
	keyPath := flag.String("key", "", "key.pem output")
	idPath := flag.String("id", "", "device-id output")
	flag.Parse()

	if *host == "" || *certPath == "" || *keyPath == "" || *idPath == "" {
		fmt.Fprintln(os.Stderr, "host, cert, key, and id are required")
		os.Exit(2)
	}

	seed := sha256.Sum256([]byte("syncthing-device-v1:" + *host))
	priv := ed25519.NewKeyFromSeed(seed[:])

	// Match upstream Syncthing's tlsDefaultCommonName. The Android client
	// verifies the certificate hostname as "syncthing", so a per-host name
	// breaks the connection. The key is still unique per host through the seed.
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject: pkix.Name{
			CommonName:         "syncthing",
			Organization:       []string{"Syncthing"},
			OrganizationalUnit: []string{"Automatically Generated"},
		},
		DNSNames:              []string{"syncthing"},
		NotBefore:             time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC),
		NotAfter:              time.Date(2120, 1, 1, 0, 0, 0, 0, time.UTC),
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageClientAuth},
		BasicConstraintsValid: true,
		IsCA:                  false,
		SignatureAlgorithm:    x509.PureEd25519,
	}

	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, priv.Public(), priv)
	check(err)
	keyDER, err := x509.MarshalPKCS8PrivateKey(priv)
	check(err)

	check(os.WriteFile(*certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}), 0o644))
	check(os.WriteFile(*keyPath, pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER}), 0o600))

	sum := sha256.Sum256(der)
	id := base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(sum[:])
	check(os.WriteFile(*idPath, []byte(chunkify(luhnify(id))+"\n"), 0o644))
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func luhnify(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i += 13 {
		p := s[i:min(i+13, len(s))]
		b.WriteString(p)
		b.WriteByte(luhn32(p))
	}
	return b.String()
}

func luhn32(s string) byte {
	const n = 32
	factor := 1
	sum := 0
	for i := 0; i < len(s); i++ {
		addend := factor * strings.IndexByte(alphabet, s[i])
		if factor == 2 {
			factor = 1
		} else {
			factor = 2
		}
		addend = addend/n + addend%n
		sum += addend
	}
	return alphabet[(n-sum%n)%n]
}

func chunkify(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i += 7 {
		if i > 0 {
			b.WriteByte('-')
		}
		b.WriteString(s[i:min(i+7, len(s))])
	}
	return b.String()
}
