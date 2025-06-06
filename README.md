
#   Deploying a Highly Available Three-Tier Architecture in AWS with Terraform cloud

# Overview
Three-tier architecture comprises a client-server framework organized into three distinct layers: the web layer, the application layer, and the data storage layer.
The web or presentation tier, also known as the front end, encompasses the user-facing components of the application, including web servers and the interface.
The application tier, often referred to as the back end, hosts the backend logic and source code necessary for data processing and function execution.
The data tier is responsible for housing and overseeing the application data, typically serving as the storage location for databases.
**Consist of:**
* A Virtual private cloud
* 2 public subnet for our presentation layer, 2 private subnet for our application layer and 2 private subnet for our data layer
* Route tables. This is a set of rules, called routes, that determine where network traffic from your subnet or gateway is directed.
* Set up an Application Load Balancer to route traffic to the resources located in the public subnets. Additionally, another Application Load Balancer will be configured to manage traffic flow from the web tier to the app tier, ensuring efficient communication between the two tiers.
* Deploy an EC2 Auto Scaling Group in each of the public subnets, which correspond to the web tier, as well as in the private subnets, which correspond to the app tier. This setup ensures high availability by distributing resources across multiple subnets and tiers.
* A bastion host to connect to our private applications
* A database instance for our RDS MySQL database


# Pre-Requisite
* AWS account is needed
* IDE of your choice (I will be using VS code)
* Terraform cloud account
* Terraform installed.
* GitHub account

# Step 1: Create a GitHub Repositories

# Step 2: Create & Configure Terraform Cloud Workspace with Github Permission Access
* Create a new workspace in Terraform Cloud and connect it to your version control system (e.g., GitHub). Configure variables and environment settings as needed.
* 2a. Go to Terraform Cloud by HashiCorp and create your Terraform cloud account.
* 2b. Create a New workspace and click Version Control
* 2c. Click on GitHUb App
* 2d. Add the repository to your code on this page and click create.

# Step 3: Setup a AWS - Github OIDC

# Step 4: Start building our Infrastructure
* 4a.  Create a provider.tf file to state the cloud provider we are using and the region where our resources will be managed.
* 4b. create a variables.tf file for the cidr_block for code resusabibilty.
* 4c. Create  Create VPC (virtual private cloud) in a main.tf file which gives us full control over our virtual networking environment, including resource placement, connectivity, and security.
* 4d. cretae a ec2 autoscaling group 
* 4e. create security group for our EC2 ASG in the public and private subnets
* 4f. create Database instance and database security group in our data tier private subnet.
* 4g. create a "Bastion host" and its security group to assist in providing access to our private network from an external network, such as the Internet.
* 4h. create an "Internet gateway" to help enable our ec2 instance in the public subnet to connect to the internet.
* 4i. create a two "Route table" To make the web tier and applivcation tier talk to each other. one for each tier.
* 4j. Create a "NAT gateway and an elastic ip. this allows our instances in private subnet to connect to services outside our VPC but external services cannot initiate a connection with the instances.
* 4k. Lastly, create "application load balancer" to enable us to automatically distributes incoming application traffic accross multiple targets and virtual appliances in one or more Availability Zones (AZs)

# Step 5: Create Github Action workflows.

# Step 6: Push to Github and apply run in Terraform cloud.
