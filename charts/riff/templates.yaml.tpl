knative-build: https://storage.googleapis.com/knative-releases/build/previous/v0.7.0/build.yaml # --data-value dropKnativeImageCRD=true
knative-serving: https://storage.googleapis.com/knative-releases/serving/previous/v0.7.1/serving.yaml
riff-system: https://storage.googleapis.com/projectriff/riff-system/snapshots/riff-system-$(curl -s https://storage.googleapis.com/projectriff/riff-system/snapshots/versions/master).yaml
riff-application-build-template: https://storage.googleapis.com/projectriff/riff-buildtemplate/riff-application-clusterbuildtemplate-$(curl -s https://storage.googleapis.com/projectriff/riff-buildtemplate/versions/builds/master).yaml
riff-function-build-template: https://storage.googleapis.com/projectriff/riff-buildtemplate/riff-function-clusterbuildtemplate-$(curl -s https://storage.googleapis.com/projectriff/riff-buildtemplate/versions/builds/master).yaml
