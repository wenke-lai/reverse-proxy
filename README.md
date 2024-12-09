# Reverse Proxy

A reverse proxy for Elasticsearch.
append to existed services, e.g. load Balancer, security group, iam role, etc., to proxy requests to Elasticsearch.

## Usage

1. update `terraform.tfvars`

```bash
$ cp terraform.tfvars.example terraform.tfvars
$ vim terraform.tfvars
```

2. deploy the infrastructure

```bash
$ terraform init
$ terraform apply
```

3. login to the instance and update the Nginx configs.

```bash
$ aws ssm start-session --target {instance-id}
# create the nginx config file and .htpasswd file.
$ docker exec reverse-proxy nginx -t reload
```

4. update the security group

- allow the load balancer to access the instance.
- allow the user IP to access the load balancer.

## Create BasicAuth password

```bash
$ apt-get install apache2-utils -y
$ htpasswd -c /etc/nginx/.htpasswd {username}
```
