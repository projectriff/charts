VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts/fetch-istio.sh charts/package.sh
	mkdir -p repository
	./charts/fetch-istio.sh istio 1.1.7
	./charts/package.sh istio ${VERSION} repository
	./charts/package.sh riff ${VERSION} repository

.PHONY: clean
clean:
	rm -rf repository
	rm -rf charts/istio/istio
	rm -rf charts/riff/riff
