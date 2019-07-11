VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts package.sh
	mkdir -p repository
	./package.sh istio ${VERSION} repository
	./package.sh riff ${VERSION} repository

.PHONY: clean
clean:
	rm -rf repository
	rm -rf charts/*/templates
