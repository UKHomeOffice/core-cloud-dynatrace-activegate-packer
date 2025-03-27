# Pre-requisites

* An 'aws_secret' named after the default value of the variable 'dynatraceSecretName' in the [packer_config/variables.pkr.hcl](packer_config/variables.pkr.hcl) file. If the secret is named anything else then that name must be passed appropriately from the command line, to the packer. Please refer to the 'AWS Secrets for the Dynatrace tokens' section below for the contents to be made available through this secret.

* An ssm role, with policy 'AmazonSSMManagedInstanceCore', named after the default value of the variable 'ssmRoleName' in the [packer_config/variables.pkr.hcl](packer_config/variables.pkr.hcl) file wit hthe following trust relationship.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

If the role is named anything else, it must be appropriately passed on to the packer.

# Packer variables

All the packer variables are documented in detail within this [variables file](packer_config/variables.pkr.hcl). One can notice that all the variables are configured with default values which in most of the case should be fine. The following command should be run (typically within the github workflow), for building an AMI, from the root of this repo, to utilise the default values:

```
packer build packer_config
```

If, for example, a specific activegate version is to be configured within the AMI, issue the following:

```
packer build -var 'activeGateVersion=1.305.57.20250111-162425' packer_config
```

The above example can be used to pass more variables, if needed, to override default values.

In addition, the [workflow](.github/workflows/validate_or_build.yaml) will automatically include a vars file named <AWS_ENV>.pkvars.hcl. Currently this is used to shared the created AMI with external AWS accounts.

# Environment variables

| Variable name | Description |
| ------------- | ----------- |
| DYNATRACE_ENV_ID     | Dynatrace environment ID. To come from the  AWS secret and read into the github pipeline using the github action as per https://collaboration.homeoffice.gov.uk/display/CORE/Consume+AWS+Secrets+within+GitHub+workflow+using+a+GitHub+action. |
| DYNATRACE_API_TOKEN  | Dynatrace API token. To come from the AWS secret and read into the github pipeline using the github action as per https://collaboration.homeoffice.gov.uk/display/CORE/Consume+AWS+Secrets+within+GitHub+workflow+using+a+GitHub+action. |

For a github pipeline, these variables are made available by retrieving the secrets from AWS. The AWS secret is used within the github workflow and must be named 'DynatraceApiToken' with the above keys with valid values. Please refer to [.github/workflows/validate_or_build.yaml](.github/workflows/validate_or_build.yaml)

# Cleaning up the old AMIs

There is a utility to clean up the old AMIs - older than a configurable number of counts (not age). I.E only the last 'n' number of AMIs will be kept. For example if 'n' is 5 anything other than than the most recent 5 AMIs will be removed; if one creates 5 AMIs in one day or one hour all the other AMIs will be removed. This can be configured inside the [ansible/cleanup_old_amis.yml](ansible/cleanup_old_amis.yml) or more preferrably pass it on from the command line when calling the clean up as below:

```
ansible-playbook ansible/cleanup_old_amis.yml -e "ami_retention_count=10"
```

Note: Currently this feature is not used. However there is a commented out block towards the end of the [github workflow](.github/workflows/validate_or_build.yaml) which if uncommented can enable the feature.

# Inside the AMI

Follwing are the high level operations/configuration steps take place during the AMI creation:

1. The Activegate installer is pulled, using DYNATRACE_ENV_ID/DYNATRACE_API_TOKEN, from the Dynatrace.
2. Activegate installed
3. The environment specific activegate credentials removed.
4. The default Activegate service disable from automatically starting.
5. A 'forking' service (which runs and completes) called 'pulldtsecrets' created, starts when the instance is launched (through the appropriate terraform module) which will pull the target environment specific Dynatrace credentials from the AWS secret and start the Activegate service on successful retrieval of the creedentials (in the target environment).

# Requirements for launch template/aws instance

For the launch template/aws instance to run successfully, in the target environment, the following requirements are to be satisfied.

## IAM Inatance role

An active gate role. This is typically created by an appropriate means as per https://collaboration.homeoffice.gov.uk/display/CORE/0006+Dynatrace+ActiveGate+EC2+Fleet+Deployment and attached to the instances. This role should also be allowed access to the secret created in the following section.

## AWS Secrets for the Dynatrace tokens

| Key name                 | Value |
| ------------------------ | ----- |
| dt_env_id | The Dynatrace environment id from where the activegatescript to be downloaded.|
| dt_tenant_token | Tenant token can be obtained by running `curl https://nuh63189.live.dynatrace.com/api/v1/deployment/installer/agent/connectioninfo -H "Authorization: Api-Token ${DYNATRACE_TOKEN}"` from the command line. Replace the envid with the relevant one. |
| dt_auth_token   | Activegate auth token - refer to https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-api/environment-api/tokens-v2/activegate-tokens/get-activegate-token |

# Upgrading the ActiveGate version

Every time the AMI is built, a complete system upgrade (full ubuntu upgrade) is performed.

If no specific Activegate version is provided, the latest one to date is pulled and installed.

To perform a complete update of AMI, a simple rerunning of the pipeline is sufficient.

# Troubleshooting 

Upon successful implementation of the instance using the AMI, into the target environment, the Activegate instance(s) should appear in the `<Dynatrace Instance Environment> -> Deployment Status`. If not, ensure the following:

1. Check if the Activgate IAM role, with right permissions, is attached to the instance(s) 
2. Check if the AWS secret 'dynatrace_tokens' (or any other name, if chosen to be different) is present with the **right values** (as documented above)
3. Check if the above AWS secret allows the activegate role (in step 1) to read the secrets.

If all the above are correct

1. Log on to the instance through appropriate means. Typically the user name (from the base image to build the image) would be 'ubuntu'. 
2. Check the status of the service called `pulldtsecrets` by running the following:

```
systemctl status pulldtsecrets.service
```
This should show any errors, if the script underneath the service, may have.

3. If the above service do not show any errors, check the dynatrace active gate is running successfully. *Please note that the dynatrace service would be started only if the 'pulldtsecrets' service has completed successfully, by the __pulldtsecrets.service__*. The activegate service can be checked by running the following:

```
systemctl status dynatracegateway.service
```

4. There is a set of logs under `/var/logs/dynatrace`. Look for any signs of error in those logs.

If the activegate is still not working, a new ticket should be raised and investigated further.

# Miscellaneous 

To obtain the available activegate versions from a Dynatrace environment run the following command:

```
curl GET "https://nuh63189.live.dynatrace.com/api/v1/deployment/installer/gateway/versions/unix" -H "Authorization: Api-Token ${DYNATRACE_TOKEN}"
```
