deploy:
	terraform init
	terraform plan -var-file=".tfvars" -out=infrastructure.tf.plan
	terraform apply -auto-approve infrastructure.tf.plan
	rm -rf infrastructure.tf.plan

destroy:
	terraform destroy -var-file=".tfvars"