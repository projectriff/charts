VERSION ?= $(shell cat VERSION)
export ISTIO_VERSION = 1.3.3

.PHONY: package
package: repository

repository: charts/*.sh
	mkdir -p repository
	mkdir -p uncharted

	./charts/package.sh cert-manager ${VERSION}
	./charts/unpackage.sh cert-manager

	./charts/fetch-istio.sh istio-init $(ISTIO_VERSION)
	./charts/package.sh istio-init ${VERSION}
	./charts/unpackage.sh istio-init

	./charts/fetch-istio.sh istio $(ISTIO_VERSION)
	./charts/package.sh istio ${VERSION}
	./charts/unpackage.sh istio

	./charts/fetch-kafka.sh kafka 0.20.5
	./charts/package.sh kafka ${VERSION}
	./charts/unpackage.sh kafka
	
	./charts/package.sh keda ${VERSION}
	./charts/unpackage.sh keda
	
	./charts/package.sh knative ${VERSION}
	./charts/unpackage.sh knative
	
	./charts/package.sh kpack ${VERSION}
	./charts/unpackage.sh kpack
	
	./charts/package.sh riff-builders ${VERSION}
	./charts/unpackage.sh riff-builders
	
	./charts/package.sh riff-build ${VERSION}
	./charts/unpackage.sh riff-build
	
	./charts/package.sh riff-core-runtime ${VERSION}
	./charts/unpackage.sh riff-core-runtime
	
	./charts/package.sh riff-knative-runtime ${VERSION}
	./charts/unpackage.sh riff-knative-runtime
	
	./charts/package.sh riff-streaming-runtime ${VERSION}
	./charts/unpackage.sh riff-streaming-runtime
	
	./charts/package.sh riff ${VERSION}

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
	rm -rf uncharted
