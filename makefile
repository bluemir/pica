IMPORT_PATH:=github.com/bluemir/pica
BIN_NAME:=$(notdir $(IMPORT_PATH))

default: build

VERSION?=$(shell git describe --long --tags --dirty --always)
export VERSION

DOCKER_IMAGE_NAME:=bluemir/$(BIN_NAME)
DOCKER_SERVICE_NAME:=$(BIN_NAME)

# BE source
GO_SOURCES   = $(shell find . -name "vendor"  -prune -o \
                              -type f -name '*.go' -print)
# FE source
JS_SOURCES    = $(shell find app/js       -type f -name '*.js'   -print)
HTML_SOURCES  = $(shell find app/html     -type f -name '*.html' -print)
CSS_SOURCES   = $(shell find app/css      -type f -name '*.css'  -print)
WEB_LIBS      = $(shell find app/lib      -type f                -print)

DISTS =
DISTS += $(JS_SOURCES:app/js/%=dist/js/%)
DISTS += $(CSS_SOURCES:app/css/%=dist/css/%)
DISTS += $(WEB_LIBS:app/lib/%=dist/lib/%)

reset:
	ps -e | grep make | grep -v grep | awk '{print $$1}' | xargs kill

$(BIN_NAME).unpacked:  $(GO_SOURCES) makefile
	go build -v -ldflags "-X main.VERSION=$(VERSION)" -o $(BIN_NAME).unpacked ./cmd

$(BIN_NAME): $(HTML_SOURCES) $(DISTS) $(BIN_NAME).unpacked
	cp $(BIN_NAME).unpacked $(BIN_NAME).tmp
	rice append -v --exec $(BIN_NAME).tmp \
		-i $(IMPORT_PATH)/pkg/server
	mv $(BIN_NAME).tmp  $(BIN_NAME)
test:
	go test -v ./pkg/...
run: $(BIN_NAME)
	./$(BIN_NAME)
auto-run:
	while true; do \
		make .sources | \
		entr -rd make test run ;  \
		echo "hit ^C again to quit" && sleep 1  \
	; done
.sources:
	@echo \
	makefile \
	$(GO_SOURCES) \
	$(JS_SOURCES) \
	$(HTML_SOURCES) \
	$(CSS_SOURCES) \
	$(WEB_LIBS) \
	| tr " " "\n"

## Web dist
#dist/css/%.css: $(CSS_SOURCES)
#	lessc app/less/entry/$*.less $@
dist/%: app/%
	@mkdir -p $(dir $@)
	cp $< $@

clean:
	rm -rf build/ dist/ \
		datatype/*.go .pb_mark .docker-image \
		$(BIN_NAME) $(BIN_NAME).unpacked
	go clean

build: $(BIN_NAME) .docker-image
.docker-image: $(GO_SOURCES) $(HTML_TEMPLATE) $(DISTS) dockerfile
	docker build \
		--build-arg VERSION=$(VERSION) \
		-t $(DOCKER_IMAGE_NAME):$(VERSION) .
	echo $(DOCKER_IMAGE_NAME):$(VERSION) > $@
.docker-image.pushed: .docker-image
	docker push $(shell cat .docker-image)
	echo $(shell cat .docker-image) > $@

# uncomment if feel like not working
#.PRECIOUS: build/%/$(BIN_NAME).bin $(GO_SOURCES) $(PROTO_SOURCE:%.proto=%.pb.go)
.PHONY: .sources run auto-run reset clean deploy
