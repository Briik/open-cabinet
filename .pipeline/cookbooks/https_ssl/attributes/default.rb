default[:myuscis][:https_ssl][:bucket_name] = "devopsbootcamp-certs"
#default[:myuscis][:https_ssl][:cert_object_name] = "bootcamp-jenkins.crt.encrypted"
default[:myuscis][:https_ssl][:cert_object_name] = "bootcamp-opencab.crt.encrypted"
#default[:myuscis][:https_ssl][:key_object_name] = "bootcamp-jenkins.key.encrypted"
default[:myuscis][:https_ssl][:key_object_name] = "bootcamp-opencab.key.encrypted"

default[:myuscis][:https_ssl][:config_dir] = "/etc/nginx/"
default[:myuscis][:https_ssl][:cert_flename] = "bootcamp-opencab.crt"
default[:myuscis][:https_ssl][:key_filename] = "bootcamp-opencab.key"
