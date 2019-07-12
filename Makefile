VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts fetch-istio.sh package.sh
	mkdir -p repository
	./fetch-istio.sh istio 1.1.7
	./fetch-istio.sh istio-lean 1.1.7
	./package.sh istio ${VERSION} repository
	./package.sh istio-lean ${VERSION} repository
	./package.sh riff ${VERSION} repository

.PHONY: clean
clean:
	rm -rf repository
	rm -rf charts/*/templates
	rm -rf charts/istio*/*
