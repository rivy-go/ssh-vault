.PHONY: all bintray build clean compile cover get goxc install test

GO ?= go
GOEXE ?=$(shell ${GO} env GOEXE)
GOPATH ?=$(shell ${GO} env GOPATH)
GOBIN ?=${GOPATH}/bin

NAME=ssh-vault
BIN_NAME = ${NAME}${GOEXE}
VERSION=$(shell git describe --tags --always)

GO_XC = ${GOPATH}/bin/goxc -os="freebsd netbsd openbsd darwin linux windows" -bc="!386"
GOXC_FILE = .goxc.json
GOXC_FILE_LOCAL = .goxc.local.json

CP=cp
RM=rm

all: clean build

get:
	${GO} get
	${GO} get -u github.com/kr/pty
	${GO} get -u github.com/ssh-vault/crypto
	${GO} get -u github.com/ssh-vault/crypto/aead
	${GO} get -u github.com/ssh-vault/crypto/oaep
	${GO} get -u github.com/ssh-vault/go-keychain
	${GO} get -u github.com/ssh-vault/ssh2pem
	${GO} get -u golang.org/x/crypto/ssh/terminal

build: get
	${GO} build -ldflags "-s -w -X main.version=${VERSION}" -o ${BIN_NAME} ./cmd/ssh-vault/main.go

install: build
	${CP} ${BIN_NAME} ${GOBIN}/${BIN_NAME}"

clean:
	@${RM} -rf ssh-vault-* ${BIN_NAME} ${BIN_NAME}.debug *.out build debian

test: get
	${GO} test -race -v

cover:
	${GO} test -cover && \
	${GO} test -coverprofile=coverage.out  && \
	${GO} tool cover -html=coverage.out

compile: clean goxc

goxc:
	$(shell printf '{\n  "ConfigVersion": "0.9",' > $(GOXC_FILE))
	$(shell printf '  "AppName": "ssh-vault",' >> $(GOXC_FILE))
	$(shell printf '  "ArtifactsDest": "build",' >> $(GOXC_FILE))
	$(shell printf '  "PackageVersion": "${VERSION}",' >> $(GOXC_FILE))
	$(shell printf '  "TaskSettings": {' >> $(GOXC_FILE))
	$(shell printf '    "bintray": {' >> $(GOXC_FILE))
	$(shell printf '      "downloadspage": "bintray.md",' >> $(GOXC_FILE))
	$(shell printf '      "package": "ssh-vault",' >> $(GOXC_FILE))
	$(shell printf '      "repository": "ssh-vault",' >> $(GOXC_FILE))
	$(shell printf '      "subject": "nbari"' >> $(GOXC_FILE))
	$(shell printf '    }\n  },' >> $(GOXC_FILE))
	$(shell printf '  "BuildSettings": {' >> $(GOXC_FILE))
	$(shell printf '    "LdFlags": "-s -w -X main.version=${VERSION}"' >> $(GOXC_FILE))
	$(shell printf '  }\n}' >> $(GOXC_FILE))
	$(shell printf '{\n "ConfigVersion": "0.9",' > $(GOXC_FILE_LOCAL))
	$(shell printf ' "TaskSettings": {' >> $(GOXC_FILE_LOCAL))
	$(shell printf '  "bintray": {\n   "apikey": "$(BINTRAY_APIKEY)"' >> $(GOXC_FILE_LOCAL))
	$(shell printf '  }\n } \n}' >> $(GOXC_FILE_LOCAL))
	${GO_XC}

bintray:
	${GO_XC} bintray
