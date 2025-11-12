. Basic Plan

Use the quay.io/skopeo/stable container image to run skopeo like this:

docker run --rm \
  -v /your/local/dir:/output \
  quay.io/skopeo/stable \
  copy docker://nginx:latest docker-archive:/output/nginx.tar:nginx:latest
  
Let’s say you want to save the nginx image tarball to:

mkdir -p /opt/images
docker run --rm \
  -v /opt/images:/output \
  quay.io/skopeo/stable \
  copy docker://nginx:latest docker-archive:/output/nginx.tar:nginx:latest

Load the Image into Docker

docker load < /opt/images/nginx.tar
docker run -it nginx:latest

Want to Ignore TLS Certs?

docker run --rm \
  -v /opt/images:/output \
  quay.io/skopeo/stable \
  copy --tls-verify=false docker://<your-registry>/nginx:latest docker-archive:/output/nginx.tar:nginx:latest

sudo apt install umoci -y

mkdir -p /tmp/oci-nginx
skopeo copy docker://nginx:latest oci:/tmp/oci-nginx:latest
mkdir -p /tmp/nginx-bundle
umoci unpack --image /tmp/oci-nginx:latest /tmp/nginx-bundle

tar -cvf nginx-bundle.tar -C /tmp/nginx-bundle .
