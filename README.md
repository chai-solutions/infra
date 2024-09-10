# Chai Solutions Infrastructure

This repository contains the configurations needed to deploy a working
configuration of the required resources needed to run our app.

We use [Terraform](https://terraform.io) to provision the required resources
with [AWS](https://aws.amazon.com), and [NixOS](https://nixos.org) to manage the
configuration options for each machine; it's fully declarative, end to end.
Because who has the time to remember _how_ to deploy things, when you can just
tell the computer _what_ you want and get it built for you for free?

## Overview

**NOTE**: the term "owners", as referenced through this README, refer to the two
members of the organization with the most privileges: @water-sucks and
@elite-whale75.

The Chai app runs on a single EC2 instance that is connected through a VPC to a
private RDS PostgreSQL instance. The EC2 instance is exposed to the public
Internet through an Elastic IP, and access is configured such that only ports
80, 443, and 22 are accessible for HTTP(S) and SSH access, respectively.

A domain name, https://chai-solutions.org, is registered to @water-sucks through
a domain registrar, Porkbun. This has manually configured DNS records that
point to two places:

- `https://chai-solutions.org` :: static website, hosted by [Netlify](https://netlify.com)
- `https://api.chai-solutions.org` :: EC2 instance that houses the Chai API

There are no staging/testing instances; in fact, there are only production and
local development states. This is due to the fact that we need to stay within
the free tier (we're poor) and still want adequate performance, and configuring
a real staging instance seemed to be more trouble than it was worth.

## Infrastructure

The infrastructure is mostly stateless, except for two notable exceptions: the
RDS Postgres instance (of course!), [some secrets](## secrets) and the Terraform
state (`tfstate`) file. Terraform deploys happen with the `terraform apply`
command; Terraform uses the AWS CLI (v2) under the hood to perform deployments.

The `tfstate` file is a record of all the infrastructure that has been
provisioned. This is within the owners' possession, and stays out of the
repository due to the fact that infrastructure changes need to in sync
with everyone at all times; Git version control systems do not allow for this
to happen reliably. All infrastructure deploys are done manually, and only with
express communication between the owners involved. The state file will also
allow us to reliably tear down the infrastructure in case unexpected costs
happen. This is one of the key benefits of Infrastructure as Code.

Other secrets, such as the database username and password, are also stored
privately, and not within the Terraform configuration. These exist in a
different file, `secrets.tfvars`; this file also stays out of this repository
for similar reasons as the `tfstate` file. `terraform apply` is only ever
executed with this file present.

There are two key outputs from this Terraform configuration:

- EC2 Elastic IP
- Private database URL (for use within the EC2 image)

An A record is configured for the `https://api.chai-solutions.org` domain to
point to the Elastic IP, and the private database URL is used in pretty much
every database context where a host is required.

The EC2 instance is configured using a NixOS image. NixOS image deployments are
managed using [`colmena`](https://username.github.io/colmena). The NixOS system
is configured to run the `chaid` API service as a `systemd` daemon, and the
[Caddy](https://caddy.org) web server automatically provisions HTTPS
certificates; Caddy also takes care of reverse proxying any HTTP(S) traffic to
the `chaid` service.

Since there is only one production instance, no automatic deployment is in
place. Rather, production deploys are kicked off using a GitHub Action that
automatically runs `colmena apply` upon any updates to the main branch of
this repository. The API server is provided as a Nix flake input; application
deployments consist of updating this flake input, committing the changes, and
pushing up to `main`.

<!-- TODO: add dbmate deployment documentation -->

## Secrets + Authentication

In order to access the EC2 instance, an SSH key pair is configured through
Terraform; the owners have this key in their personal possession, and the key
itself is also configured in GitHub Actions as a secret.

Credentials to access the database are also in the owners' possession, and
exist inside the `secrets.tfvars` file.

Application secrets (such as database information) are deployed to the NixOS
images using the [`agenix`](https://github.com/ryantm/agenix) tool, which is
managed as a part of the NixOS configuration. `agenix` has its own separate
encryption key (this also happens to be an SSH key) that is copied to the EC2
instance by hand. This is the only instance of real mutability in the EC2
instance.
