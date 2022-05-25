# Terraform Account Module (AWS)

Terraform meta-module for providing dynamic account & environment reflection and consistent naming standards.

## Preamble

Building things with Terraform is easy. Scaling Terraform to hundreds of projects, repositories and AWS accounts is the hard part. Whilst Terraform provides some good primer for how to scale up, the Terraform Framework is the reults of years of building enterprise solutions with Terraform, learning from failures and figuring out some good practices. At the heart of the Terraform Framework, is this - the account - module. The account module serves as the foundation of the framework by providing some simple but powerful constructs, such as consistent naming and tagging standards, outputs that are contextually bound to the AWS account being targeted, and a solid concept for handling environments with workspaces. It also provides some helpful outputs for doing inline logic to differ your infrastructure per environments.

Whilst using this module may seem strange at first, it soon becomes apparent where it shines when integrating it with other modules or allowing you to say goodbye to pesky tfvar files and script generated varialble inputs from CI processes. The module has been designed to be incrementally adoptable, and you don't have to use other Terraform Framework modules for it to work, but our other modules are designed to work specifically with this.

We'll discuss some of the above we've touched on later on in the examples.

## Usage

```hcl
module "account" {
  source  = "terraform-framework/account/aws"
  version = "~> 1.0"
}
```
