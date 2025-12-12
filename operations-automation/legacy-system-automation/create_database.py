#!/usr/bin/env python3
"""
AI-Powered Legacy System Automation Demo

Creates a database in phpMyAdmin using Amazon Nova Act browser automation.
Demonstrates how AI can automate legacy web interfaces that lack APIs.

Target: https://demo.phpmyadmin.net/master-config/public/

Usage:
    python create_database.py
    python create_database.py --db-name my_test_db
    python create_database.py --cleanup
    python create_database.py --headless
"""

import argparse
import random
import string
from datetime import datetime

PHPMYADMIN_URL = "https://demo.phpmyadmin.net/master-config/public/"
WORKFLOW_NAME = "legacy-system-automation"

try:
    from nova_act import NovaAct
    from nova_act.types.workflow import workflow
    NOVA_ACT_AVAILABLE = True
except ImportError:
    NOVA_ACT_AVAILABLE = False


def generate_db_name() -> str:
    """Generate a unique database name to avoid conflicts on shared demo server."""
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return f"nova_demo_{suffix}"


def create_database(db_name: str, cleanup: bool = False, headless: bool = False) -> dict:
    """
    Create a database in phpMyAdmin using Nova Act browser automation.
    Uses the @workflow decorator for AWS IAM authentication.
    """
    result = {
        "target_url": PHPMYADMIN_URL,
        "database_name": db_name,
        "start_time": datetime.now().isoformat(),
        "steps": [],
        "status": "pending"
    }

    @workflow(workflow_definition_name=WORKFLOW_NAME, model_id="nova-act-latest")
    def run_automation():
        nonlocal result
        
        with NovaAct(starting_page=PHPMYADMIN_URL, headless=headless) as nova:
            # Step 1: Page loaded
            print(f"Step 1: Page loaded - {PHPMYADMIN_URL}")
            result["steps"].append({"step": "navigate", "status": "success"})
            
            # Step 2: Create database
            print(f"Step 2: Creating database '{db_name}'...")
            nova.act(
                f"Click on 'New' in the left sidebar to create a new database. "
                f"Then enter '{db_name}' as the database name and click 'Create'."
            )
            result["steps"].append({"step": "create_database", "status": "success"})
            
            # Step 3: Verify creation
            print("Step 3: Verifying database was created...")
            verification = nova.act_get(
                f"Check if the database '{db_name}' appears in the left sidebar. "
                f"Return 'found' if you can see it, 'not_found' otherwise."
            )
            
            response_text = str(verification.response).lower() if verification.response else ""
            if "found" in response_text and "not_found" not in response_text:
                print(f"✓ Database '{db_name}' created successfully!")
                result["steps"].append({"step": "verify", "status": "success"})
                result["status"] = "success"
            else:
                print(f"⚠ Could not verify database creation")
                result["steps"].append({"step": "verify", "status": "uncertain"})
                result["status"] = "uncertain"
            
            # Step 4: Cleanup (optional)
            if cleanup:
                print(f"Step 4: Dropping database '{db_name}'...")
                nova.act(
                    f"Click on the database '{db_name}' in the left sidebar, "
                    f"then click on 'Operations' tab, "
                    f"then find and click 'Drop the database' and confirm."
                )
                result["steps"].append({"step": "drop_database", "status": "success"})
                print(f"✓ Database '{db_name}' dropped")
        
        return result

    try:
        return run_automation()
    except Exception as e:
        result["status"] = "error"
        result["error"] = str(e)
        result["end_time"] = datetime.now().isoformat()
        print(f"Error: {e}")
        return result


def main():
    parser = argparse.ArgumentParser(
        description="Create a database in phpMyAdmin using Nova Act"
    )
    parser.add_argument(
        "--db-name",
        default=None,
        help="Database name (default: auto-generated)"
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="Drop the database after creation"
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        help="Run browser in headless mode"
    )
    
    args = parser.parse_args()
    db_name = args.db_name or generate_db_name()
    
    print("=" * 60)
    print("phpMyAdmin Database Creation with Nova Act")
    print("=" * 60)
    print(f"Target: {PHPMYADMIN_URL}")
    print(f"Database: {db_name}")
    print(f"Cleanup: {args.cleanup}")
    print("=" * 60)
    
    if not NOVA_ACT_AVAILABLE:
        print("\n[SIMULATION MODE] Nova Act SDK not installed")
        print(f"Would create database: {db_name}")
        print(f"On: {PHPMYADMIN_URL}")
        print("\nInstall with: pip install nova-act")
        return
    
    result = create_database(
        db_name=db_name,
        cleanup=args.cleanup,
        headless=args.headless
    )
    
    print("\n" + "=" * 60)
    print("Result:")
    print(f"  Status: {result['status']}")
    print(f"  Steps: {len([s for s in result['steps'] if s['status'] == 'success'])}/{len(result['steps'])}")
    if not args.cleanup and result["status"] == "success":
        print(f"\n  Database '{db_name}' available at:")
        print(f"  {PHPMYADMIN_URL}?db={db_name}")
    print("=" * 60)


if __name__ == "__main__":
    main()
