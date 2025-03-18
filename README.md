# Pre-requisites

* An 'aws_secret' named after the default value of the variable 'dynatraceSecretName' in the [packer_config/variables.pkr.hcl](packer_config/variables.pkr.hcl) file. If the secret is named anything else then that name must be passed appropriately from the command line, to the packer. Please refer to the 'AWS Secrets for the Dynatrace tokens' section below for the contents to be made available through this secret.

* An ssm role, with policy 'AmazonSSMManagedInstanceCore', named after the default value of the variable 'ssmRoleName' in the [packer_config/variables.pkr.hcl](packer_config/variables.pkr.hcl) file. If the role is named anything else, it must be appropriately passed on to the packer. Please refer to 'EC2_SSM_Role' in the DynatraceSandbox account for reference.

* An active gate role. This is typically created by an appropriate means as per https://collaboration.homeoffice.gov.uk/display/CORE/0006+Dynatrace+ActiveGate+EC2+Fleet+Deployment


# AWS Secrets for the Dynatrace tokens
| Key name                 | Value
| ------------------------ | _____ |
| dt_env_id | The Dynatrace environment id from where the activegatescript to be downloaded.|
| dt_tenant_token | Tenant token can be obtained by running `curl https://nuh63189.live.dynatrace.com/api/v1/deployment/installer/agent/connectioninfo -H "Authorization: Api-Token ${DYNATRACE_TOKEN}"` from the command line. Replace the envid with the relevant one. |
| dt_auth_token   | Activegate auth token - refer to https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-api/environment-api/tokens-v2/activegate-tokens/get-activegate-token |
| dt_api_token    | Token to use to pull the script |

During the creation of the AMI the above secret will be consumed in the github actions (through an action). 

Note:
For the created AMI to work in the target environment, where the AMI is going to be used to deploy an instance, the above secret must be present with appropriate targets and tokens. The secret should be configured for the activegate role to access it to pull the environment id and the tokens.

# Packer variables

All the packer variables are documented in detail within this [variables file](packer_config/variables.pkr.hcl). One can notice that all the variables are configured with default values which in most of the case should be fine. The following command should be run, for building an AMI, form the root of this repo, to utilise the default values:

```
packer build packer_config
```

If, for example, a specific activegate version is to be configured within the AMI, issue the following:

```
packer build -var 'activeGateVersion=1.305.57.20250111-162425' packer_config
```

The above example can be used to pass more variables, if needed, to override default values.

# Environment variables

| Variable name | Description |
| ------------- | ----------- |
| DT_ENV_ID     | Dynatrace environment ID. To come from the above AWS secret and read into the github pipeline using the github action as per https://collaboration.homeoffice.gov.uk/display/CORE/Consume+AWS+Secrets+within+GitHub+workflow+using+a+GitHub+action. |
| DT_AUTH_TOKEN | Dynatrace auth token. To come from the AWS secret and read into the github pipeline using the github action as per https://collaboration.homeoffice.gov.uk/display/CORE/Consume+AWS+Secrets+within+GitHub+workflow+using+a+GitHub+action. |

# Cleaning up the old AMIs

There a utility to clean up the old AMIs - older than a configurable number of counts (it is not age). I.E only the last 'n' number of AMIs will be kept. For example if 'n' is 5 anything othere thans than the most recent 5 AMIs will be removed; if one created 5 AMIs in one day or one hour all the other AMIs will be removed. This can be configure inside the [ansible/cleanup_old_amis.yml](ansible/cleanup_old_amis.yml) or more preferrably pass it on from the command line when calling the clean up as below:

```
ansible-playbook ansible/cleanup_old_amis.yml -e "ami_retention_count=10"
```

# Miscellaneous 

To obtain the available activegate versions from a Dynatrace environment run the following command:

```
curl GET "https://nuh63189.live.dynatrace.com/api/v1/deployment/installer/gateway/versions/unix" -H "Authorization: Api-Token ${DYNATRACE_TOKEN}"
```