# Fiskaly - Take Home Assignment

Role: Site Reliability Engineer role at fiskaly

This challenge is designed to reflect typical responsibilities and scenarios of the role. We're less focused on perfection and more on how you approach problems, structure your work, and document your reasoning.

You’ll find four short exercises below. Please complete them in your own time over the next 7 days and share a link to your solution (GitHub repository). We’ll then schedule a 1-hour review call with the team.

## General Instructions

Please include a README (or comments) for each exercise explaining:

- Your approach and reasoning
- Any assumptions you made
- Trade-offs or alternatives you considered

You are welcome to use AI tools to support your work, but make sure you understand and can explain the output in the review session.

## The Tasks

### 1. Docker – “Hello World” Web App

Create a simple Dockerfile that builds a containerized web app responding with "Hello World" to HTTP requests on port 8080.

- Use a language of your choice (e.g., TypeScript or Python).
  You can write your own app or use a simple containerized server (e.g., nginx, Apache, lighttpd + static HTML).
- Include a docker run command that launches the container.
- The service should be accessible from your local machine and ideally from other devices on the same network (firewall configs can be skipped).

### 2. Kubernetes Deployment

Using the web app from Task 1:

- Create Kubernetes deployment manifests that:
  - Deploy at least 2 replicas (scale up to 4 under higher load)
  - Use nginx as a load balancer
  - Include resource configurations and basic security settings

Optional: Suggest any alternatives to nginx for load balancing and explain when you’d use them.

### 3. Infrastructure as Code (IaC)

Use Terraform (preferred) or another IaC tool to define a simple infrastructure setup in GCP or AWS:

- A VPC with subnets
- A Kubernetes cluster with 4 nodes (GKE or EKS) capable of hosting the app from Task 2
- A network security configuration that only allows necessary traffic

We’d like to see how you structure infrastructure and make decisions around cloud architecture.

### 4. Ansible Playbook

Write a playbook that does the following across a fleet of Linux servers (Ubuntu + RedHat):

- Gather system facts
- Update package repositories
- Upgrade packages
- On Ubuntu only:
  - Ensure Apache is installed
  - Serve a static HTML page with "Hello World"
  - Restart Apache after config changes
- On RedHat only:
  - Ensure MariaDB is installed
