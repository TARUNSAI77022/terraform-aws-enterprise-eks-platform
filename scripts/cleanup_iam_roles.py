import json
import argparse
import sys
import time
import boto3
from botocore.exceptions import ClientError

def parse_args():
    parser = argparse.ArgumentParser(description="Safely cleanup IAM roles created by Terraform.")
    parser.add_argument("--state", required=True, help="Path to the pre-destroy state JSON file.")
    parser.add_argument("--dry-run", action="store_true", help="Perform checks without deleting resources.")
    parser.add_argument("--region", default="ap-south-1", help="Target AWS region (default: ap-south-1).")
    return parser.parse_args()

def extract_resources(module_node):
    resources = []
    if "resources" in module_node:
        resources.extend(module_node["resources"])
    if "child_modules" in module_node:
        for child in module_node["child_modules"]:
            resources.extend(extract_resources(child))
    return resources

def discover_roles_from_state(state_path):
    print(f"Reading state backup from {state_path}...")
    try:
        with open(state_path, "r") as f:
            state_data = json.load(f)
    except Exception as e:
        print(f"Error reading state file: {e}")
        sys.exit(1)
        
    root_module = state_data.get("values", {}).get("root_module", {})
    all_resources = extract_resources(root_module)
    
    custom_roles = []
    service_linked_roles = []
    
    for res in all_resources:
        res_type = res.get("type")
        res_values = res.get("values", {})
        arn = res_values.get("arn")
        
        if not arn:
            continue
            
        role_name = arn.split("/")[-1]
        
        if res_type == "aws_iam_role":
            custom_roles.append(role_name)
        elif res_type == "aws_iam_service_linked_role":
            # For SLR, the role name might also be derived from aws_service_name or role_name in values
            slr_name = res_values.get("role_name") or role_name
            service_linked_roles.append(slr_name)
            
    # Remove duplicates
    custom_roles = list(set(custom_roles))
    service_linked_roles = list(set(service_linked_roles))
    
    # Also add standard dynamic SLRs to check if they are in the backup or configuration
    standard_slrs = [
        "AWSServiceRoleForAmazonEKS",
        "AWSServiceRoleForAmazonEKSNodegroup",
        "AWSServiceRoleForAutoScaling",
        "AWSServiceRoleForEC2Spot",
        "AWSServiceRoleForResourceExplorer"
    ]
    for s_slr in standard_slrs:
        if s_slr not in service_linked_roles:
            service_linked_roles.append(s_slr)
            
    return custom_roles, service_linked_roles

def check_eks_clusters(region):
    try:
        client = boto3.client("eks", region_name=region)
        clusters = client.list_clusters().get("clusters", [])
        return len(clusters), None
    except Exception as e:
        return -1, str(e)

def check_asgs(region):
    try:
        client = boto3.client("autoscaling", region_name=region)
        asgs = client.describe_auto_scaling_groups().get("AutoScalingGroups", [])
        return len(asgs), None
    except Exception as e:
        return -1, str(e)

def check_spot_requests(region):
    try:
        client = boto3.client("ec2", region_name=region)
        requests = client.describe_spot_instance_requests(
            Filters=[{"Name": "state", "Values": ["open", "active"]}]
        ).get("SpotInstanceRequests", [])
        return len(requests), None
    except Exception as e:
        return -1, str(e)

def check_resource_explorer(region):
    try:
        client = boto3.client("resource-explorer-2", region_name=region)
        indexes = client.list_indexes().get("Indexes", [])
        return len(indexes), None
    except Exception as e:
        # If resource explorer is not active, treat as 0
        return 0, None

def check_instance_profiles(role_name):
    try:
        client = boto3.client("iam")
        profiles = client.list_instance_profiles_for_role(RoleName=role_name).get("InstanceProfiles", [])
        return [p["InstanceProfileName"] for p in profiles], None
    except Exception as e:
        return [], str(e)

def is_protected_role(role_name):
    protected_prefixes = [
        "AWSServiceRoleForSupport",
        "AWSServiceRoleForTrustedAdvisor",
        "AWSServiceRoleForResourceExplorer",
        "AWSReservedSSO_"
    ]
    for prefix in protected_prefixes:
        if role_name.startswith(prefix):
            return True
    return False

def detach_policies(role_name, dry_run=False):
    iam = boto3.client("iam")
    try:
        attached = iam.list_attached_role_policies(RoleName=role_name).get("AttachedPolicies", [])
        for policy in attached:
            policy_arn = policy["PolicyArn"]
            print(f"Detaching policy {policy_arn} from {role_name}...")
            if not dry_run:
                iam.detach_role_policy(RoleName=role_name, PolicyArn=policy_arn)
    except Exception as e:
        print(f"Error detaching policies from {role_name}: {e}")

def delete_inline_policies(role_name, dry_run=False):
    iam = boto3.client("iam")
    try:
        inline = iam.list_role_policies(RoleName=role_name).get("PolicyNames", [])
        for policy_name in inline:
            print(f"Deleting inline policy {policy_name} from {role_name}...")
            if not dry_run:
                iam.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
    except Exception as e:
        print(f"Error deleting inline policies from {role_name}: {e}")

def remove_from_instance_profiles(role_name, dry_run=False):
    iam = boto3.client("iam")
    try:
        profiles = iam.list_instance_profiles_for_role(RoleName=role_name).get("InstanceProfiles", [])
        for profile in profiles:
            profile_name = profile["InstanceProfileName"]
            print(f"Removing role {role_name} from instance profile {profile_name}...")
            if not dry_run:
                iam.remove_role_from_instance_profile(InstanceProfileName=profile_name, RoleName=role_name)
    except Exception as e:
        print(f"Error removing {role_name} from instance profiles: {e}")

def delete_custom_role(role_name, dry_run=False):
    if dry_run:
        print(f"[DRY-RUN] Would delete role: {role_name}")
        return True, 0, None
        
    iam = boto3.client("iam")
    retries = 5
    delay = 5
    for attempt in range(retries):
        try:
            iam.delete_role(RoleName=role_name)
            return True, attempt, None
        except iam.exceptions.NoSuchEntityException:
            return True, attempt, None
        except iam.exceptions.DeleteConflictException as e:
            print(f"Attempt {attempt + 1}: Deletion conflict for {role_name}. Retrying in {delay}s...")
            time.sleep(delay)
            delay *= 2
        except Exception as e:
            return False, attempt, str(e)
    return False, retries, "Max retries reached with DeletionConflictException"

def main():
    args = parse_args()
    
    custom_roles, service_linked_roles = discover_roles_from_state(args.state)
    
    report = {
        "Inventory": [],
        "Deleted": [],
        "Skipped": [],
        "Still In Use": [],
        "Failed": [],
        "Retries": {}
    }
    
    # 1. Populating Inventory
    report["Inventory"].extend(custom_roles)
    report["Inventory"].extend([role for role in service_linked_roles if role not in report["Inventory"]])
    
    print("\n=== Performing Dependency Checks for Service-Linked Roles ===")
    
    # Pre-fetch AWS counts for SLR verification
    eks_count, eks_err = check_eks_clusters(args.region)
    asg_count, asg_err = check_asgs(args.region)
    spot_count, spot_err = check_spot_requests(args.region)
    re_count, re_err = check_resource_explorer(args.region)
    
    print(f"Active EKS Clusters: {eks_count}")
    print(f"Active AutoScaling Groups: {asg_count}")
    print(f"Active Spot Requests: {spot_count}")
    print(f"Active Resource Explorer Indexes: {re_count}")
    
    # 2. Process Custom Roles
    print("\n=== Processing Custom Roles ===")
    for role in custom_roles:
        if is_protected_role(role):
            print(f"Skipping protected default AWS role: {role}")
            report["Skipped"].append((role, "AWS Protected Default Role"))
            continue
            
        # Verify if exists
        iam = boto3.client("iam")
        try:
            iam.get_role(RoleName=role)
        except iam.exceptions.NoSuchEntityException:
            print(f"Role {role} does not exist in AWS, skipping.")
            continue
        except Exception as e:
            print(f"Could not verify role {role}: {e}")
            report["Failed"].append((role, f"Verification failed: {e}"))
            continue
            
        # Dependency check
        profiles, err = check_instance_profiles(role)
        if profiles:
            print(f"Role {role} is still attached to Instance Profiles: {profiles}. Skipping.")
            report["Still In Use"].append((role, f"Instance Profiles: {profiles}"))
            continue
            
        # Perform teardown
        detach_policies(role, args.dry_run)
        delete_inline_policies(role, args.dry_run)
        remove_from_instance_profiles(role, args.dry_run)
        
        success, attempts, err_msg = delete_custom_role(role, args.dry_run)
        if success:
            report["Deleted"].append(role)
            if attempts > 0:
                report["Retries"][role] = attempts
        else:
            report["Failed"].append((role, err_msg))
            
    # 3. Process Service-Linked Roles
    print("\n=== Processing Service-Linked Roles ===")
    for role in service_linked_roles:
        if is_protected_role(role):
            print(f"Skipping protected default AWS SLR: {role}")
            report["Skipped"].append((role, "AWS Protected Default Role"))
            continue
            
        # Check SLR exist
        iam = boto3.client("iam")
        try:
            iam.get_role(RoleName=role)
        except iam.exceptions.NoSuchEntityException:
            continue
        except Exception as e:
            continue
            
        # Verify specific SLR dependency
        safe_to_delete = True
        reason = ""
        
        if role in ["AWSServiceRoleForAmazonEKS", "AWSServiceRoleForAmazonEKSNodegroup"]:
            if eks_count > 0:
                safe_to_delete = False
                reason = f"Active EKS Clusters count: {eks_count}"
        elif role == "AWSServiceRoleForAutoScaling":
            if asg_count > 0:
                safe_to_delete = False
                reason = f"Active AutoScaling Groups count: {asg_count}"
        elif role == "AWSServiceRoleForEC2Spot":
            if spot_count > 0:
                safe_to_delete = False
                reason = f"Active Spot Instance Requests count: {spot_count}"
        elif role == "AWSServiceRoleForResourceExplorer":
            if re_count > 0:
                safe_to_delete = False
                reason = f"Active Resource Explorer Indexes count: {re_count}"
                
        if not safe_to_delete:
            print(f"SLR {role} is still in use: {reason}. Skipping.")
            report["Still In Use"].append((role, reason))
            continue
            
        # Attempt SLR Deletion (Asynchronous, fail-safe)
        if args.dry_run:
            print(f"[DRY-RUN] Would delete service-linked role: {role}")
            report["Deleted"].append(role)
        else:
            print(f"Attempting deletion of service-linked role: {role}...")
            try:
                # delete-service-linked-role is asynchronous and returns task id
                output = iam.delete_service_linked_role(RoleName=role)
                task_id = output.get("DeletionTaskId")
                print(f"Deletion task initiated for {role} (Task ID: {task_id})")
                report["Deleted"].append(role)
            except Exception as e:
                # Do not crash the workflow if SLR deletion fails (e.g. if AWS internally claims in-use)
                print(f"Warning: Could not delete SLR {role}. Reason: {e}")
                report["Failed"].append((role, f"SLR Deletion failed: {e}"))
                
    # 4. Generate Final Markdown Report
    print("\n" + "="*40)
    print("FINAL EXECUTION REPORT")
    print("="*40)
    
    md = []
    md.append("### IAM Roles Cleanup Execution Report")
    md.append("")
    md.append(f"**Mode**: `{'DRY-RUN (No modifications)' if args.dry_run else 'LIVE APPLY'}`")
    md.append(f"**Region**: `{args.region}`")
    md.append("")
    
    md.append("#### Summary Status")
    md.append("| Status | Count | Roles |")
    md.append("| :--- | :---: | :--- |")
    md.append(f"| **Discovered (Inventory)** | {len(report['Inventory'])} | {', '.join(report['Inventory']) if report['Inventory'] else '_None_'} |")
    md.append(f"| **Successfully Deleted** | {len(report['Deleted'])} | {', '.join(report['Deleted']) if report['Deleted'] else '_None_'} |")
    md.append(f"| **Still In Use (Active Dependencies)** | {len(report['Still In Use'])} | {', '.join([f'{r[0]} ({r[1]})' for r in report['Still In Use']]) if report['Still In Use'] else '_None_'} |")
    md.append(f"| **Skipped (Protected Default Roles)** | {len(report['Skipped'])} | {', '.join([f'{r[0]} ({r[1]})' for r in report['Skipped']]) if report['Skipped'] else '_None_'} |")
    md.append(f"| **Failed** | {len(report['Failed'])} | {', '.join([f'{r[0]} ({r[1]})' for r in report['Failed']]) if report['Failed'] else '_None_'} |")
    md.append("")
    
    if report["Retries"]:
        md.append("#### Propagation Delay Retries")
        md.append("| Role | Attempts Required |")
        md.append("| :--- | :---: |")
        for role, att in report["Retries"].items():
            md.append(f"| `{role}` | {att} |")
        md.append("")
        
    report_content = "\n".join(md)
    print(report_content)
    
    # Save the output to a text file for step summary integration
    try:
        with open("iam-cleanup-report.md", "w", encoding="utf-8") as f:
            f.write(report_content)
        print("\nReport saved to iam-cleanup-report.md")
    except Exception as e:
        print(f"Error saving report file: {e}")

if __name__ == "__main__":
    main()
