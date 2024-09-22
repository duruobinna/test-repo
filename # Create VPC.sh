# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=Grp2-VPC

# Public subnets
Pub_Subnet_1=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pub_Subnet_1 --tags Key=Name,Value=Grp2-Public1

Pub_Subnet_2=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pub_Subnet_2 --tags Key=Name,Value=Grp2-Public2

# Private subnets1
Pri_Subnet_1=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pri_Subnet_1 --tags Key=Name,Value=Grp2-Private1

Pri_Subnet_2=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pri_Subnet_2 --tags Key=Name,Value=Grp2-Private2

# Private subnets2
Pri_Subnet_DB1=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.5.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pri_Subnet_DB1 --tags Key=Name,Value=Grp2-Pri-DB1

Pri_Subnet_DB2=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.6.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text) 
aws ec2 create-tags --resources $Pri_Subnet_DB2 --tags Key=Name,Value=Grp2-Pri-DB2


# IGW
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text) 
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $vpc_id
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=Grp2_IGW

# Route Table
ROUTE_TABLE_1=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text) 
aws ec2 create-tags --resources $ROUTE_TABLE_1 --tags Key=Name,Value=Grp2-RT
aws ec2 create-route --route-table-id $ROUTE_TABLE_1 --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --subnet-id $Pub_Subnet_1 --route-table-id $ROUTE_TABLE_1
aws ec2 associate-route-table --subnet-id $Pub_Subnet_2 --route-table-id $ROUTE_TABLE_1


# Security Groups
# Create Security Group For ALB
ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name Grp2-ALB-SG \
    --description "Grp2-ALB-SG" \
    --vpc-id $vpc_id \
    --query 'GroupId' \
    --output text)

# Add Inbound Rule (HTTP on port 80 from anywhere)
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 
# Allow HTTPS traffic from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Add Outbound Rule (HTTP on port 80 to anywhere)
aws ec2 authorize-security-group-egress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Tag Security Group
aws ec2 create-tags \
    --resources $ALB_SG_ID \
    --tags Key=Name,Value=Grp2-ALB-SG


# Create Security Group For EC2 Instances
EC2_SG_ID=$(aws ec2 create-security-group \
    --group-name Grp2-EC2-SG \
    --description "Grp2-EC2-SG" \
    --vpc-id $vpc_id \
    --query 'GroupId' \
    --output text)

# Add Inbound Rule (HTTP on port 80 from anywhere)
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
# Allow HTTPS traffic from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
# Allow SSH traffic from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Allow traffic from ALB SG
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 80 \
    --source-group $ALB_SG_ID

# Add Outbound Rule (HTTP on port 80 to anywhere)
aws ec2 authorize-security-group-egress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Tag Security Group
aws ec2 create-tags \
    --resources $EC2_SG_ID \
    --tags Key=Name,Value=Grp2-EC2-SG


# Create Security Group for DB
DB_SG_ID=$(aws ec2 create-security-group \
    --group-name Grp2-DB-SG \
    --description "Grp2-DB-SG" \
    --vpc-id $vpc_id \
    --query 'GroupId' \
    --output text)

# Add Inbound Rule (HTTP on port 80 from anywhere)
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
# Allow traffic from EC2 SG
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 80 \
    --source-group $EC2_SG_ID 

# Add Outbound Rule (HTTP on port 80 to anywhere)
aws ec2 authorize-security-group-egress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Tag Security Group
aws ec2 create-tags \
    --resources $DB_SG_ID \
    --tags Key=Name,Value=Grp2-DB-SG


# Create two EC2 instances
EC2_ID_1=$(aws ec2 run-instances \
    --image-id ami-0ae8f15ae66fe8cda \
    --instance-type t2.micro \
    --key-name EC2-test2 \
    --security-group-ids $EC2_SG_ID \
    --subnet-id $Pri_Subnet_1 \
    --count 1 \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Grp2-EC2a}]' \
    --query 'Instances[0].InstanceId' \
    --user-data '#!/bin/bash\naws s3 cp s3://grp2s3/Store-IDs_Names/user-data.sh /tmp/user-data.sh\nbash /tmp/user-data.sh' \
    --output text)

EC2_ID_2=$(aws ec2 run-instances \
    --image-id ami-0ae8f15ae66fe8cda \
    --instance-type t2.micro \
    --key-name EC2-test2 \
    --security-group-ids $EC2_SG_ID \
    --subnet-id $Pri_Subnet_2 \
    --count 1 \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Grp2-EC2b}]' \
    --query 'Instances[0].InstanceId' \
    --user-data '#!/bin/bash\naws s3 cp s3://grp2s3/Store-IDs_Names/user-data.sh /tmp/user-data.sh\nbash /tmp/user-data.sh' \
    --output text)

# Print instance IDs
echo "Instance in subnet $SUBNET_ID_1: $EC2_ID_1"
echo "Instance in subnet $SUBNET_ID_2: $EC2_ID_2"


###### CREATING ALB
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name Grp2-ALB \
    --subnets $Pub_Subnet_1 $Pub_Subnet_2\
    --security-groups $ALB_SG_ID \
    --scheme internet-facing \
    --type application \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

# Create Target Group
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name Grp2-ALP-TG \
    --protocol HTTP \
    --port 80 \
    --vpc-id $vpc_id \
    --health-check-protocol HTTP \
    --health-check-port 80 \
    --health-check-path /health \
    --matcher HttpCode=200 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# REGISTER TARGETS
aws elbv2 register-targets \
    --target-group-arn $TARGET_GROUP_ARN \
    --targets Id=$EC2_ID_1 Id=$EC2_ID_2

# Create Listener
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

#Verify Target Registration via health check
aws elbv2 describe-target-health \
    --target-group-arn $TARGET_GROUP_ARN


## CREATING ASG
aws autoscaling create-launch-configuration \
  --launch-configuration-name Grp2-ASG-Launch-Config \
  --image-id ami-0ae8f15ae66fe8cda \
  --instance-type t2.micro \
  --key-name EC2-test2 \
  --security-group $EC2_SG_ID \
  --user-data '#!/bin/bash\naws s3 cp s3://grp2s3/Store-IDs_Names/user-data.sh /tmp/user-data.sh\nbash /tmp/user-data.sh'

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name Grp2-ASG \
  --launch-configuration-name Grp2-ASG-Launch-Config \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 1 \
  --vpc-zone-identifier "$Pri_Subnet_1, $Pri_Subnet_2" \
  --tags Key=Name,Value=Grp2ASGInstance,PropagateAtLaunch=true

aws autoscaling put-scaling-policy \
  --policy-name ScaleOutPolicy \
  --auto-scaling-group-name Grp2-ASG \
  --scaling-adjustment 1 \
  --adjustment-type ChangeInCapacity \
  --cooldown 300
aws autoscaling put-scaling-policy \
  --policy-name ScaleInPolicy \
  --auto-scaling-group-name Grp2-ASG \
  --scaling-adjustment -1 \
  --adjustment-type ChangeInCapacity \
  --cooldown 300

aws cloudwatch put-metric-alarm \
    --alarm-name my-scale-out-alarm \
    --alarm-description "Alarm when CPU exceeds 60%" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value=Grp2-ASG \
    --statistic Average \
    --period 300 \
    --threshold 60 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:us-east-1:767398064359:scalingPolicy:eea091de-af14-45ff-bef3-a1f3b777fe53:autoScalingGroupName/Grp2-ASG:policyName/ScaleOutPolicy 

aws cloudwatch put-metric-alarm \
    --alarm-name my-cpu-alarm \
    --alarm-description "Alarm when CPU exceeds 50%" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value=Grp2-ASG \
    --statistic Average \
    --period 300 \
    --threshold 50 \
    --comparison-operator LessThanOrEqualToThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:us-east-1:767398064359:scalingPolicy:df5eef0e-2134-42ac-a24c-88470346eed0:autoScalingGroupName/Grp2-ASG:policyName/ScaleInPolicy


#Associate ASG to Target Groups
aws autoscaling attach-load-balancer-target-groups \
    --auto-scaling-group-name Grp2-ASG \
    --target-group-arns $TARGET_GROUP_ARN

#Verify Association of ASG with Target Groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names Grp2-ASG
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN



echo $vpc_id > vpc-id.txt && aws s3 cp vpc-id.txt s3://grp2s3/Store-IDs_Names/vpc-id.txt
echo $Pub_Subnet_1 > Pub_Subnet_1.txt && aws s3 cp Pub_Subnet_1.txt s3://grp2s3/Store-IDs_Names/Pub_Subnet_1.txt
echo $Pub_Subnet_2 > Pub_Subnet_2.txt && aws s3 cp Pub_Subnet_2.txt s3://grp2s3/Store-IDs_Names/Pub_Subnet_2.txt
echo $Pri_Subnet_1 > Pri_Subnet_1.txt && aws s3 cp Pri_Subnet_1.txt s3://grp2s3/Store-IDs_Names/Pri_Subnet_1.txt
echo $Pri_Subnet_2 > Pri_Subnet_2.txt && aws s3 cp Pri_Subnet_2.txt s3://grp2s3/Store-IDs_Names/Pri_Subnet_2.txt
echo $Pri_Subnet_DB1 > Pri_Subnet_DB1.txt && aws s3 cp Pri_Subnet_DB1.txt s3://grp2s3/Store-IDs_Names/Pri_Subnet_DB1.txt
echo $Pri_Subnet_DB2 > Pri_Subnet_DB2.txt && aws s3 cp Pri_Subnet_DB2.txt s3://grp2s3/Store-IDs_Names/Pri_Subnet_DB2.txt
echo $IGW_ID > IGW_ID.txt && aws s3 cp IGW_ID.txt s3://grp2s3/Store-IDs_Names/IGW_ID.txt
echo $ROUTE_TABLE_1> ROUTE_TABLE_1.txt && aws s3 cp ROUTE_TABLE_1.txt s3://grp2s3/Store-IDs_Names/ROUTE_TABLE_1.txt
echo $ALB_SG_ID> ALB_SG_ID.txt && aws s3 cp ALB_SG_ID.txt s3://grp2s3/Store-IDs_Names/ALB_SG_ID.txt
echo $ALB_ARN> ALB_ARN.txt && aws s3 cp ALB_ARN.txt s3://grp2s3/Store-IDs_Names/ALB_ARN.txt
echo $EC2_SG_ID> EC2_SG_ID.txt && aws s3 cp EC2_SG_ID.txt s3://grp2s3/Store-IDs_Names/EC2_SG_ID.txt
echo $EC2_ID_1> EC2_ID_1.txt && aws s3 cp EC2_ID_1.txt s3://grp2s3/Store-IDs_Names/EC2_ID_1.txt
echo $EC2_ID_2> EC2_ID_2.txt && aws s3 cp EC2_ID_2.txt s3://grp2s3/Store-IDs_Names/EC2_ID_2.txt
echo $ALB_ARN> ALB_ARN.txt && aws s3 cp ALB_ARN.txt s3://grp2s3/Store-IDs_Names/ALB_ARN.txt
echo $TARGET_GROUP_ARN> TARGET_GROUP_ARN.txt && aws s3 cp TARGET_GROUP_ARN.txt s3://grp2s3/Store-IDs_Names/TARGET_GROUP_ARN.txt
echo $DB_SG_ID DB_SG_ID.txt && aws s3 cp DB_SG_ID.txt s3://grp2s3/Store-IDs_Names/DB_SG_ID.txt


vpc_id=$(aws s3 cp s3://grp2s3/Store-IDs_Names/vpc-id.txt -)
Pub_Subnet_1=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pub_Subnet_1.txt -)
Pub_Subnet_2=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pub_Subnet_2.txt -)
Pri_Subnet_1=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pri_Subnet_1.txt -)
Pri_Subnet_2=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pri_Subnet_2.txt -)
Pri_Subnet_DB1=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pri_Subnet_DB1.txt -)
Pri_Subnet_DB2=$(aws s3 cp s3://grp2s3/Store-IDs_Names/Pri_Subnet_DB2.txt -)
IGW_ID=$(aws s3 cp s3://grp2s3/Store-IDs_Names/IGW_ID.txt -)
ROUTE_TABLE_1=$(aws s3 cp s3://grp2s3/Store-IDs_Names/ROUTE_TABLE_1.txt -)
ALB_SG_ID=$(aws s3 cp s3://grp2s3/Store-IDs_Names/ALB_SG_ID.txt -)
ALB_ARN=$(aws s3 cp s3://grp2s3/Store-IDs_Names/ALB_ARN.txt -)
EC2_SG_ID=$(aws s3 cp s3://grp2s3/Store-IDs_Names/EC2_SG_ID.txt -)
EC2_ID_1=$(aws s3 cp s3://grp2s3/Store-IDs_Names/EC2_ID_1.txt -)
EC2_ID_2=$(aws s3 cp s3://grp2s3/Store-IDs_Names/EC2_ID_2.txt -)
ALB_ARN=$(aws s3 cp s3://grp2s3/Store-IDs_Names/ALB_ARN.txt -)
TARGET_GROUP_ARN=$(aws s3 cp s3://grp2s3/Store-IDs_Names/TARGET_GROUP_ARN.txt -)
DB_SG_ID=$(aws s3 cp s3://grp2s3/Store-IDs_Names/DB_SG_ID.txt -)



DB_ID=$(aws rds create-db-instance \
    --db-instance-identifier Grp2-RDS \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username grp2_admin \
    --master-user-password grp2password \
    --allocated-storage 20 \
    --vpc-security-group-ids $DB_SG_ID \
    --db-subnet-group mydbsubnetgroup \
    --backup-retention-period 7 \
    --no-publicly-accessible \
    --tags Key=Name,Value=Grp2-RDS-DB \
    --query 'DBInstance.DBInstanceIdentifier' \
    --output text)

aws rds create-db-subnet-group \
    --db-subnet-group-name mydbsubnetgroup \
    --db-subnet-group-description "My DB subnet group" \
    --subnet-ids $Pri_Subnet_DB1 $Pri_Subnet_DB2



### RUNNING FLASK
python --version
python -m venv myenv
source myenv/bin/activate
pip install Flask

#Create the Project Directory
mkdir flask_project
cd flask_project

#Create the Flask Application File
touch app.py






# S3 Bucket
aws s3api create-bucket --bucket grp2s3 --region us-east-1
aws s3 website s3://grp2s3 --index-document about.html --error-document error.html



aws route53domains register-domain --domain-name <your-domain-name> --duration-in-years 1 --auto-renew

aws route53 create-hosted-zone --name <your-domain-name> --caller-reference <unique-string>

