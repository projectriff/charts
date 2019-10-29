VERSION ?= $(shell cat VERSION)

.PHONY: package
package: repository

repository: charts/fetch-istio.sh charts/package.sh
	mkdir -p repository
	./charts/fetch-istio.sh istio 1.3.3
	./charts/package.sh cert-manager ${VERSION} repository
	./charts/package.sh istio ${VERSION} repository
	./charts/package.sh keda ${VERSION} repository
	./charts/package.sh knative ${VERSION} repository
	./charts/package.sh kpack ${VERSION} repository
	./charts/package.sh riff-builders ${VERSION} repository
	./charts/package.sh riff-build ${VERSION} repository
	./charts/package.sh riff-core-runtime ${VERSION} repository
	./charts/package.sh riff-knative-runtime ${VERSION} repository
	./charts/package.sh riff-streaming-runtime ${VERSION} repository
	./charts/package.sh riff ${VERSION} repository

.PHONY: templates
templates:
	./charts/update-template.sh cert-manager
	./charts/update-template.sh keda
	./charts/update-template.sh knative
	./charts/update-template.sh kpack
	./charts/update-template.sh riff-builders
	./charts/update-template.sh riff-build
	./charts/update-template.sh riff-core-runtime
	./charts/update-template.sh riff-knative-runtime
	./charts/update-template.sh riff-streaming-runtime

.PHONY: clean
clean:
	rm -rf build
	rm -rf repository
