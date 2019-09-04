VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts/fetch-istio.sh charts/package.sh
	mkdir -p repository
	./charts/fetch-istio.sh istio 1.2.5
	./charts/package.sh istio ${VERSION} repository
	./charts/package.sh knative ${VERSION} repository
	./charts/package.sh riff ${VERSION} repository

.PHONY: templates
templates:
	./charts/update-template.sh knative
	./charts/update-template.sh riff

.PHONY: clean
clean:
	rm -rf build
	rm -rf repository
