# ocp-web-terminal-advanced-config

OpenShift Web Terminal Advanced Config example.

## Custom Image

The Web Terminal Operator is pre-configured to use a tools image that includes the most common CLI tools that you'd use with OpenShift (oc, kubectl, skopeo, etc...), however, sometimes you need additional tools or configuration.  As an example, the `helm` binary was recently removed from the default WTO image because it is not FIPS compliant (...yet).

This process involves creating a new image based on the current default.  Here is an example Containerfile that adds the helm cli.

```
FROM --platform=linux/amd64 registry.redhat.io/web-terminal/web-terminal-tooling-rhel9:1.14

USER 0

RUN curl -LO https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.19.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-v3.19.0-linux-amd64.tar.gz linux-amd64

USER 1001
```

You can see an example here in the `Containerfile` in the root of this repo.

You can either build this image locally, then push it to your image registry of choice, or you can use the `BuildConfig` supplied in `/files/build` to do the same (you will have to update the `Secret` in that directory to have a valid `.dockerConfigJson` file to allow the build to push to your registry).

```
oc apply -k files/build
```

This will set everything up, you'll just need to edit the secret (add your own dockerconfig value), change the output container registry path, and then "Start" the build.

## Updating WTO to use your new image.

Now that you have an image, you need to tell WTO to use it.

This is done by updating the `web-terminal-tooling` config file that lives in `openshift-operators`.   Two things need to be done to this file:

1. The image reference needs to be changed to your image.
2. An annotation needs to be added to tell the WTO to stop managing this config (or it will overwrite the image when a new one is available from Red Hat).

An example can be found under `/config`.  If you want to try the image that I built (that includes `helm`), simply run:

```
oc apply -f config/web-terminal-tooling.yaml
```

## Additional config - env vars and certs

Env vars (e.g. proxy config) can be easily added with a `ConfigMap` added to the `openshift-termanal` namespace that has the following annotations and labels:

```
  labels:
    controller.devfile.io/mount-to-devworkspace: 'true'
    controller.devfile.io/watch-configmap: 'true'
  annotations:
    controller.devfile.io/mount-as: env
```

This tells the WTO to inject the key/value pairs of the ConfigMap into the Web Terminal instance.

For an example, you can try the configmap in `/config`.  Be warned, it includes fake `http_proxy`, `https_proxy` and `no_proxy` env vars, so applying this will affect how your Web Terminal interacts with external sites and your cluster.  If you want to use this for proxy settings, change them before applying.

```
oc apply -f config/proxy-configmap.yaml
```

If you have an internal CA you want to use, follow the same process.  You will want to create a Secret with your CA in the `openshift-terminal` namespace.  It will need the following annotations and lables in order to mount the CA in your terminal pod:

```
  labels:
    controller.devfile.io/mount-to-devworkspace: 'true'
    controller.devfile.io/watch-secret: 'true'
  annotations:
    controller.devfile.io/mount-path: '<path in the container>'
```

Alternatively, most CLI tools have the equivalant of a `--insecure-skip-tls-verify` flag to skip TLS verification if you're using self-signed certificates.
