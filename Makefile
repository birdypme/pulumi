PROJECT_NAME := Pulumi SDK
SUB_PROJECTS := sdk/dotnet sdk/nodejs sdk/python sdk/go
include build/common.mk

PROJECT         := github.com/pulumi/pulumi/pkg/cmd/pulumi
PROJECT_PKGS    := $(shell cd ./pkg && go list ./... | grep -v /vendor/)
EXAMPLES_PKGS   := $(shell cd ./examples && go list ./... | grep -v tests/templates | grep -v /vendor/)
TESTS_PKGS      := $(shell cd ./tests && go list ./... | grep -v tests/templates | grep -v /vendor/)
VERSION         := $(shell scripts/get-version HEAD)

TESTPARALLELISM := 10

ensure::
	$(call STEP_MESSAGE)
ifeq ($(NOPROXY), true)
	@echo "cd sdk && GO111MODULE=on go mod tidy"; cd sdk && GO111MODULE=on go mod tidy
	@echo "cd sdk && GO111MODULE=on go mod download"; cd sdk && GO111MODULE=on go mod download
	@echo "cd pkg && GO111MODULE=on go mod tidy"; cd pkg && GO111MODULE=on go mod tidy
	@echo "cd pkg && GO111MODULE=on go mod download"; cd pkg && GO111MODULE=on go mod download
	@echo "cd examples && GO111MODULE=on go mod tidy"; cd examples && GO111MODULE=on go mod tidy
	@echo "cd examples && GO111MODULE=on go mod download"; cd examples && GO111MODULE=on go mod download
	@echo "cd tests && GO111MODULE=on go mod tidy"; cd tests && GO111MODULE=on go mod tidy
	@echo "cd tests && GO111MODULE=on go mod download"; cd tests && GO111MODULE=on go mod download
else
	@echo "cd sdk && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy"; cd sdk && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy
	@echo "cd sdk && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download"; cd sdk && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download
	@echo "cd pkg && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy"; cd pkg && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy
	@echo "cd pkg && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download"; cd pkg && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download
	@echo "cd examples && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy"; cd examples && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy
	@echo "cd examples && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download"; cd examples && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download
	@echo "cd tests && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy"; cd tests && GO111MODULE=on GOPROXY=$(GOPROXY) go mod tidy
	@echo "cd tests && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download"; cd tests && GO111MODULE=on GOPROXY=$(GOPROXY) go mod download
endif


build-proto::
	cd sdk/proto && ./generate.sh

.PHONY: generate
generate::
	$(call STEP_MESSAGE)
	echo "Generate static assets bundle for docs generator"
	go generate ./pkg/codegen/docs/

build::
	cd pkg && go install -ldflags "-X github.com/pulumi/pulumi/pkg/version.Version=${VERSION}" ${PROJECT}

install::
	cd pkg && GOBIN=$(PULUMI_BIN) go install -ldflags "-X github.com/pulumi/pulumi/pkg/version.Version=${VERSION}" ${PROJECT}

dist::
	cd pkg && go install -ldflags "-X github.com/pulumi/pulumi/pkg/version.Version=${VERSION}" ${PROJECT}

lint::
	for DIR in "examples" "pkg" "sdk" "tests" ; do \
		pushd $$DIR && golangci-lint run -c ../.golangci.yml --deadline 5m && popd ; \
	done

test_fast::
	cd pkg && $(GO_TEST_FAST) ${PROJECT_PKGS}

test_all::
	cd pkg && $(GO_TEST) ${PROJECT_PKGS}
	cd examples && $(GO_TEST) -v -p=1 ${EXAMPLES_PKGS}
	cd tests && $(GO_TEST) -v -p=1 ${TESTS_PKGS}

.PHONY: publish_tgz
publish_tgz:
	$(call STEP_MESSAGE)
	./scripts/publish_tgz.sh

.PHONY: publish_packages
publish_packages:
	$(call STEP_MESSAGE)
	./scripts/publish_packages.sh

.PHONY: coverage
coverage:
	$(call STEP_MESSAGE)
	./scripts/gocover.sh

# The travis_* targets are entrypoints for CI.
.PHONY: travis_cron travis_push travis_pull_request travis_api
travis_cron: all coverage
travis_push: only_build publish_tgz only_test publish_packages
travis_pull_request: all
travis_api: all
