VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts package.sh
	mkdir -p repository
	./package.sh projectriff-istio ${VERSION} repository
	./package.sh projectriff-riff ${VERSION} repository

.PHONY: clean
clean:
	rm -rf repository
	rm -rf charts/*/templates
