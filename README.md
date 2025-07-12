# 🛒 Shopping App Infrastructure Automation (Terraform + Packer + GitHub Actions)

This repository showcases a **production-grade Infrastructure as Code (IaC)** setup built using **Terraform**, **Packer**, and **GitHub Actions**, inspired by real-world work I performed on an internal company project.

It automates the provisioning of a scalable shopping web application infrastructure on **AWS**, including image building, load balancing, high availability, and DNS configuration.

---

## 🧱 Tech Stack

- **Terraform**: Infrastructure provisioning (VPC, Subnets, EC2, ALB, ASG, etc.)
- **Packer**: AMI baking with web server and app content
- **GitHub Actions**: CI/CD pipelines for image building and infrastructure deployment
- **AWS**: Cloud platform used for deploying the application

---

## 🌐 What This Project Does

- Builds a **custom Amazon Machine Image (AMI)** with application code using Packer
- Provisions a **highly available, scalable AWS infrastructure** using Terraform:
  - VPC with public/private subnets across 3 Availability Zones
  - Internet Gateway, NAT Gateway
  - Auto Scaling Group (ASG) with Launch Template using custom AMI
  - Application Load Balancer (ALB) with HTTPS support
  - Bastion Host for SSH access
  - Route53 DNS record for domain routing
- Integrates **CI/CD pipelines** with GitHub Actions to automate:
  - AMI builds
  - Infrastructure deployments
  - Infrastructure teardown

---

## 📌 Key Features

### 🔧 Terraform: Infrastructure Automation
- Creates a **custom VPC** with a user-specified CIDR block. Inside the VPC, created three public subnets and three private subnets, each distributed across three different Availability Zones for high availability.
- Configures:
  - **Internet Gateway**, **NAT Gateway**
  - **Route Tables**, **EIPs**
- Security Groups
  - **Bastion Host SG:** Allows SSH access from anywhere to connect to private instances.
  - **Load Balancer SG:** Allows HTTP and HTTPS traffic from the public.
  - **Backend Instances SG:** Allows traffic from the load balancer on HTTP and from the bastion host over SSH.
- **Bastion Host:** A single EC2 instance is provisioned in a public subnet. It acts as a bastion/jump box to securely connect to backend servers located in private subnets.
- Launch Template & Auto Scaling Group to define backend EC2 instance configuration
  - Deploys instances across private subnets
  - Supports rolling updates and automatic instance refresh
  - Uses a custom AMI built with Packer 
  - This setup ensures fault tolerance and scalability.
- Application Load Balancer (ALB) is deployed in the public subnets to:
  - Handle incoming web traffic
  - Redirect HTTP to HTTPS
  - Forward requests to backend instances via a target group
- Outputs
  - Terraform outputs the ALB DNS name and full URLs (both HTTP and HTTPS), allowing easy access after deployment.

### 📦 Packer: AMI Creation
- Uses Packer to build a custom Amazon Machine Image (AMI), which is used by backend EC2 instances in the ASG
- Uses **Amazon Linux** as the base image
- **Provisioning** with shell scripts:
  - Installs Apache
  - Copies web application from local directory
  - Sets permissions and deploys to `/var/www/html`
- **AMI tagging** with project and environment
- Dynamically named with timestamp for versioning


### 🔁 GitHub Actions: CI/CD Pipelines

#### ✅ `build-ami.yml`
- Manually triggered workflow to:
  - Install Packer
  - Validate template
  - Build the AMI

#### ✅ `deploy-infra.yml`
- Initializes and deploys infrastructure using Terraform
- Performs `fmt`, `validate`, `plan`, and `apply` steps

#### ✅ `destroy-infra.yml`
- Safely destroys all resources
- Includes prompt to confirm destruction before proceeding

---

## 🧠 Learning Outcomes

- Designed and deployed **highly available, fault-tolerant infrastructure**
- Learned best practices in **Terraform modules, remote state, tagging, and CI/CD**
- Built and integrated **custom AMIs** with Packer
- Automated full deployment lifecycle with **GitHub Actions**

---
