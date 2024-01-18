# vim: shiftwidth=2 tabstop=2 noexpandtab :

DOCKER_USER    := uroesch
DOCKER_TAG     := puppetci
DOCKER_VERSION := $(shell date +%F)

.PHONY: all list to-latest

all: build doc

to-latest:
	docker tag $(DOCKER_USER)/$(DOCKER_TAG):$(DOCKER_VERSION) \
		$(DOCKER_USER)/$(DOCKER_TAG):latest

push-as-latest: to-latest push
	docker push $(DOCKER_USER)/$(DOCKER_TAG):latest

push-only:
	docker push $(DOCKER_USER)/$(DOCKER_TAG):$(DOCKER_VERSION)

push: build push-only

list:
	docker images | grep packer

build: 
	docker build \
		--tag $(DOCKER_USER)/$(DOCKER_TAG):$(DOCKER_VERSION) \
		.
		
build-no-cache:
	docker build \
    --no-cache \
    --tag $(DOCKER_USER)/$(DOCKER_TAG):$(DOCKER_VERSION) \
    .

force: build-no-cache

clean:
	VOLUMES="$(shell docker volume ls -qf dangling=true)"; \
	if [ -n "$${VOLUMES}" ]; then docker volume rm $${VOLUMES}; fi
	EXITED="$(shell docker ps -aqf dangling=exited)"; \
	if [ -n "$${EXITED}" ]; then  docker volume $${EXITED}; fi
	IMAGES="$(shell docker images -qf dangling=true)"; \
	if [ -n "$${IMAGES}" ]; then docker rmi $${IMAGES}; fi


doc:
	asciidoctor -b docbook -a leveloffset=+1 -o - README.adoc | \
		pandoc --markdown-headings=atx --wrap=preserve -t gfm -f docbook - \
		> README.md
