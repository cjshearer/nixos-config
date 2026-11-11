package main

import (
	"bytes"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base32"
	"encoding/json"
	"encoding/pem"
	"encoding/xml"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

type meshConfig struct {
	LocalHost    string        `json:"localHost"`
	MeshHosts    []string      `json:"meshHosts"`
	ExtraDevices []extraDevice `json:"extraDevices"`
	Folders      []folderSpec  `json:"folders"`
}

type extraDevice struct {
	Name      string   `json:"name"`
	ID        string   `json:"id"`
	Addresses []string `json:"addresses"`
}

type folderSpec struct {
	ID      string   `json:"id"`
	Devices []string `json:"devices"`
}

type deviceSpec struct {
	name      string
	id        string
	addresses []string
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "prepare":
		cmdPrepare(os.Args[2:])
	case "apply":
		cmdApply(os.Args[2:])
	default:
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: syncthing-config prepare --host HOST --cert PATH --key PATH")
	fmt.Fprintln(os.Stderr, "       syncthing-config apply --config PATH --config-dir DIR --gui ADDR")
	os.Exit(2)
}

func cmdPrepare(args []string) {
	fs := flag.NewFlagSet("prepare", flag.ExitOnError)
	host := fs.String("host", "", "local hostname")
	certPath := fs.String("cert", "", "certificate output")
	keyPath := fs.String("key", "", "private key output")
	fs.Parse(args)

	if *host == "" || *certPath == "" || *keyPath == "" {
		usage()
	}

	cert, key, _ := identity(*host)
	check(writeAtomic(*certPath, cert, 0o644))
	check(writeAtomic(*keyPath, key, 0o600))
}

func cmdApply(args []string) {
	fs := flag.NewFlagSet("apply", flag.ExitOnError)
	configPath := fs.String("config", "", "mesh configuration")
	configDir := fs.String("config-dir", "", "Syncthing configuration directory")
	gui := fs.String("gui", "", "Syncthing GUI address")
	fs.Parse(args)

	if *configPath == "" || *configDir == "" || *gui == "" {
		usage()
	}

	data, err := os.ReadFile(*configPath)
	check(err)

	var mesh meshConfig
	check(json.Unmarshal(data, &mesh))

	apiKey, err := waitForAPI(*gui, *configDir)
	check(err)

	ids := make(map[string]string, len(mesh.MeshHosts))
	for _, host := range mesh.MeshHosts {
		_, _, ids[host] = identity(host)
	}

	check(applyDevices(*gui, apiKey, deviceSpecs(mesh, ids)))
	check(applyFolders(*gui, apiKey, mesh.Folders, ids))
}

func deviceSpecs(mesh meshConfig, ids map[string]string) []deviceSpec {
	devices := make([]deviceSpec, 0, len(mesh.MeshHosts)+len(mesh.ExtraDevices))
	for _, host := range mesh.MeshHosts {
		addresses := []string{"tcp4://" + host + ":22000"}
		if host == mesh.LocalHost {
			addresses = nil
		}
		devices = append(devices, deviceSpec{
			name:      host,
			id:        ids[host],
			addresses: addresses,
		})
	}
	for _, extra := range mesh.ExtraDevices {
		devices = append(devices, deviceSpec{
			name:      extra.Name,
			id:        extra.ID,
			addresses: extra.Addresses,
		})
	}
	return devices
}

func applyDevices(gui, apiKey string, desired []deviceSpec) error {
	var current []map[string]any
	if err := request("GET", baseURL(gui)+"/rest/config/devices", apiKey, nil, &current); err != nil {
		return err
	}

	wanted := make(map[string]deviceSpec, len(desired))
	for _, device := range desired {
		wanted[device.id] = device
	}

	result := make([]map[string]any, 0, len(desired))
	for _, device := range current {
		id, _ := device["deviceID"].(string)
		spec, ok := wanted[id]
		if !ok {
			continue
		}
		device["name"] = spec.name
		device["addresses"] = stringSlice(spec.addresses)
		result = append(result, device)
		delete(wanted, id)
	}

	for _, spec := range desired {
		if _, ok := wanted[spec.id]; !ok {
			continue
		}
		result = append(result, newDevice(spec))
	}

	return request("PUT", baseURL(gui)+"/rest/config/devices", apiKey, result, nil)
}

func applyFolders(gui, apiKey string, desired []folderSpec, ids map[string]string) error {
	var folders []map[string]any
	if err := request("GET", baseURL(gui)+"/rest/config/folders", apiKey, nil, &folders); err != nil {
		return err
	}

	wanted := make(map[string]folderSpec, len(desired))
	for _, folder := range desired {
		wanted[folder.ID] = folder
	}

	for _, folder := range folders {
		id, _ := folder["id"].(string)
		spec, ok := wanted[id]
		if !ok {
			continue
		}
		devices := make([]map[string]string, 0, len(spec.Devices))
		for _, host := range spec.Devices {
			deviceID, ok := ids[host]
			if !ok {
				return fmt.Errorf("folder %s references unknown host %s", id, host)
			}
			devices = append(devices, map[string]string{"deviceID": deviceID})
		}
		folder["devices"] = devices
		delete(wanted, id)
	}

	if len(wanted) > 0 {
		missing := make([]string, 0, len(wanted))
		for id := range wanted {
			missing = append(missing, id)
		}
		return fmt.Errorf("folders not present in Syncthing: %s", strings.Join(missing, ", "))
	}

	return request("PUT", baseURL(gui)+"/rest/config/folders", apiKey, folders, nil)
}

func newDevice(spec deviceSpec) map[string]any {
	return map[string]any{
		"deviceID":                 spec.id,
		"name":                     spec.name,
		"addresses":                stringSlice(spec.addresses),
		"compression":              "metadata",
		"certName":                 "",
		"introducer":               false,
		"skipIntroductionRemovals": false,
		"introducedBy":             "",
		"paused":                   false,
		"allowedNetworks":          []any{},
		"autoAcceptFolders":        false,
		"maxSendKbps":              0,
		"maxRecvKbps":              0,
		"maxRequestKiB":            0,
		"untrusted":                false,
		"remoteGUIPort":            0,
		"numConnections":           0,
	}
}

func stringSlice(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}

func waitForAPI(gui, configDir string) (string, error) {
	deadline := time.Now().Add(2 * time.Minute)
	var lastErr error
	for time.Now().Before(deadline) {
		apiKey, err := readAPIKey(configDir)
		if err != nil {
			lastErr = err
			time.Sleep(time.Second)
			continue
		}
		if err := health(gui); err != nil {
			lastErr = err
			time.Sleep(time.Second)
			continue
		}
		return apiKey, nil
	}
	return "", fmt.Errorf("waiting for Syncthing API: %w", lastErr)
}

func health(gui string) error {
	response, err := http.Get(baseURL(gui) + "/rest/noauth/health")
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("health returned %s", response.Status)
	}
	return nil
}

func readAPIKey(configDir string) (string, error) {
	data, err := os.ReadFile(filepath.Join(configDir, "config.xml"))
	if err != nil {
		return "", err
	}
	var config struct {
		GUI struct {
			APIKey string `xml:"apikey"`
		} `xml:"gui"`
	}
	if err := xml.Unmarshal(data, &config); err != nil {
		return "", err
	}
	if config.GUI.APIKey == "" {
		return "", errors.New("no API key in config.xml")
	}
	return config.GUI.APIKey, nil
}

func request(method, url, apiKey string, body, out any) error {
	var reader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(data)
	}

	request, err := http.NewRequest(method, url, reader)
	if err != nil {
		return err
	}
	request.Header.Set("X-API-Key", apiKey)
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}

	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return err
	}
	defer response.Body.Close()

	if response.StatusCode/100 != 2 {
		message, _ := io.ReadAll(response.Body)
		return fmt.Errorf("%s %s: %s: %s", method, url, response.Status, strings.TrimSpace(string(message)))
	}

	if out != nil {
		return json.NewDecoder(response.Body).Decode(out)
	}
	return nil
}

func baseURL(gui string) string {
	return "http://" + gui
}

func identity(host string) ([]byte, []byte, string) {
	seed := sha256.Sum256([]byte("syncthing-device-v1:" + host))
	private := ed25519.NewKeyFromSeed(seed[:])

	template := &x509.Certificate{
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

	der, err := x509.CreateCertificate(rand.Reader, template, template, private.Public(), private)
	check(err)
	keyDER, err := x509.MarshalPKCS8PrivateKey(private)
	check(err)

	cert := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der})
	key := pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER})

	sum := sha256.Sum256(der)
	id := base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(sum[:])
	return cert, key, chunkify(luhnify(id))
}

func writeAtomic(path string, data []byte, mode os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	file, err := os.CreateTemp(filepath.Dir(path), ".syncthing-config-*")
	if err != nil {
		return err
	}
	temporary := file.Name()
	defer os.Remove(temporary)

	if _, err := file.Write(data); err != nil {
		file.Close()
		return err
	}
	if err := file.Chmod(mode); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	return os.Rename(temporary, path)
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func luhnify(s string) string {
	var builder strings.Builder
	for i := 0; i < len(s); i += 13 {
		part := s[i:min(i+13, len(s))]
		builder.WriteString(part)
		builder.WriteByte(luhn32(part))
	}
	return builder.String()
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
	var builder strings.Builder
	for i := 0; i < len(s); i += 7 {
		if i > 0 {
			builder.WriteByte('-')
		}
		builder.WriteString(s[i:min(i+7, len(s))])
	}
	return builder.String()
}
