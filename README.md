# AWS RDS Multi-AZ Failover & Snapshot Management Lab

This lab demonstrates a foundational high-availability database pattern for the **AWS SysOps Administrator Associate**: building a resilient RDS deployment with automated failover and data recovery.

## Architecture Overview

The system implements a production-ready database tier:

1.  **Multi-AZ Infrastructure:** An RDS DB Subnet Group spanning two Availability Zones (`us-east-1a` and `us-east-1b`).
2.  **Synchronous Replication:** The RDS instance is configured with `multi_az = true`, maintaining a standby replica in a different AZ.
3.  **Automated Failover:** In the event of a primary AZ failure, RDS automatically fails over to the standby instance without manual intervention.
4.  **Backup & Recovery:** Daily automated snapshots are retained for 7 days, enabling point-in-time recovery.
5.  **Network Security:** A VPC Security Group restricts database access to authorized traffic on the default PostgreSQL port (5432).

## Key Components

-   **RDS DB Instance:** PostgreSQL 13.7 configured for high availability.
-   **DB Subnet Group:** The logical grouping of subnets for the database fleet.
-   **VPC Security Group:** Inbound firewall for the database instance.
-   **Automated Backups:** Snapshot management for data durability.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html)
-   [LocalStack](https://localstack.cloud/)
-   [AWS CLI / awslocal](https://github.com/localstack/awscli-local)

## Deployment

1.  **Initialize and Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    ```

## Verification & Testing

To test the database resilience:

1.  **Verify Multi-AZ Status:**
    ```bash
    awslocal rds describe-db-instances --db-instance-identifier <YOUR_DB_ID>
    ```
    Confirm that `MultiAZ` is `true` and check the `SecondaryAvailabilityZone`.

2.  **Manually Take a Snapshot:**
    ```bash
    awslocal rds create-db-snapshot --db-instance-identifier <YOUR_DB_ID> --db-snapshot-identifier manual-snapshot-1
    ```

3.  **Simulate Failover (Conceptual):**
    In a live AWS environment, you can use `reboot-db-instance` with the `force-failover` flag to test the automated failover mechanism.

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```
