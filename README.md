# AAP Configuration as Code Demo

> [!WARNING]
> **🚧 Work in Progress 🚧**
>
> This repository is under active development. Features may be incomplete, subject to breaking changes, or not fully tested. Please use with caution.

---

## 📖 Table of Contents

* 🧐 [What is This Tool?](#-what-is-this-tool)
* ✨ [Why Use "Configuration as Code" (CaSC)?](#-why-use-configuration-as-code-casc)
* 🚀 [Core Features](#-core-features)
* ⚙️ [How It Works](#-how-it-works)
* 🛠️ [Prerequisites](#-prerequisites)
* 🏁 [Step 1: Setup & Configuration](#-step-1-setup--configuration)
* 👟 [Step 2: Usage / Examples](#-step-2-usage--examples)
    * [Exporting Configuration](#exporting-configuration)
    * [Importing Configuration](#importing-configuration)
* 💡 [Tips and Advanced Usage](#-tips-and-advanced-usage)
* 📦 [Supported AAP Versions](#-supported-aap-versions)
* 📜 [License](#-license)

---

## 🧐 What is This Tool?

This project is a set of Ansible playbooks and helper scripts designed to help you manage your **Ansible Automation Platform (AAP)** setup like code.

It has two primary functions:

1.  **EXPORT:** Read the *current configuration* from your AAP instance (like Job Templates, Credentials, Inventories, Projects, etc.) and save them as human-readable YAML files.
2.  **IMPORT:** Take those YAML configuration files and *apply them* to an AAP instance, automatically creating or updating resources to match what's in the files.

This process is often called **Configuration as Code (CaSC)**.

## ✨ Why Use "Configuration as Code" (CaSC)?

If you're new to CaSC, here's why it's so powerful:

* **Version Control:** You can store your *entire* AAP configuration in Git. This lets you see a full history of who changed what and when.
* **Migration:** Easily move your setup from one environment to another (e.g., from a 'test' server to a 'production' server).
* **Consistency:** Ensure your 'dev' and 'prod' environments are configured identically, reducing "it worked in test" problems.
* **Disaster Recovery:** If a server fails, you can rebuild it and re-apply your configuration from code in minutes.
* **Auditing & Review:** You can use "Pull Requests" to review and approve changes to your AAP configuration *before* they are applied.

## 🚀 Core Features

* **Export from AAP:** Dumps your live AAP configuration into structured YAML files.
* **Import to AAP:** Configures an AAP instance based on your YAML files.
* **Version-Aware:** Includes different logic for different versions of AAP (e.g., 2.4, 2.5, 2.6).
* **Granular Control:** Uses Ansible **tags** to let you export or import only specific pieces of your configuration (e.g., just `controller_projects` or `eda_credentials`).

## ⚙️ How It Works

This tool provides two main wrapper scripts, `export.sh` and `import.sh`, which are the easiest way to get started.

These scripts are user-friendly wrappers for the underlying Ansible playbooks (`export.yml` and `import.yml`). They automatically:
1.  Read your environment's **AAP version** from `orgs_vars/<org_name>/<env_name>/vars.env`.
2.  Read your environment's credentials from an encrypted Ansible Vault.
3.  Validate your command-line tags against the version-specific list.
4.  Run the correct Ansible playbook using **`ansible-navigator`**.
5.  Use a pre-built **Execution Environment (EE)** to ensure all the right Ansible collections and dependencies are present.

You don't need to be an Ansible expert to use them, but you *do* need the prerequisite tools installed.

## 🛠️ Prerequisites

Before you begin, you **must** have the following tools installed on your local machine:

1.  **`ansible-navigator`**: The tool used to run the Ansible playbooks inside their execution environment.
2.  **`Bash 4.3+`**: Required for advanced script features (associative arrays and namerefs).
3.  **Podman** or **Docker**: `ansible-navigator` needs a container runtime to pull and run the Execution Environment.
4.  **Git**: To clone this repository.

---

## 🏁 Step 1: Setup & Configuration

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/lennysh/aap-casc-demo.git
    cd aap-casc-demo
    ```

2.  **Run the Initialization Script:**
    This tool now includes an interactive script to get you started. Run the `start_here.sh` script and provide an organization name and environment name (e.g., `OCP0Lab` and `my_prod`).

    ```bash
    chmod +x start_here.sh
    ./start_here.sh OCP0Lab my_prod
    ```

3.  **What This Script Does:**
    The `start_here.sh` script will automatically:
    * **Create the organization directory** if it doesn't exist (e.g., `orgs_vars/OCP0Lab/`).
    * **Ask you to select an AAP version** (e.g., 2.6, 2.5) for this environment.
    * Create the full directory structure: `orgs_vars/OCP0Lab/my_prod/imports` and `orgs_vars/OCP0Lab/my_prod/exports`.
    * Create the common directory: `orgs_vars/OCP0Lab/common/` for shared configurations.
    * Save your version choice to `orgs_vars/OCP0Lab/my_prod/vars.env`.
    * Copy the `templates/vault.yml` to `orgs_vars/OCP0Lab/my_prod/vault.yml`.
    * Encrypt the new `vault.yml` using `ansible-vault`. (It will ask you to create a new vault password.)
    * Open the new `vault.yml` in your editor so you can add your AAP hostname and credentials.

4.  **(Optional) Edit Your Vault Later:**
    If you need to edit your encrypted vault file again later, you can use the `vault-edit.sh` script:

    ```bash
    chmod +x vault-edit.sh
    ./vault-edit.sh OCP0Lab my_prod
    ```

## 👟 Step 2: Usage / Examples

The two main scripts are `./export.sh` and `./import.sh`. You must make them executable first:

```bash
chmod +x export.sh import.sh
```

### Exporting Configuration

This command reads from your AAP instance and saves the files locally. **Note that you no longer need to provide the version number.**

* **Command:** `./export.sh <org_name> <environment_name> [options]`
* **Arguments:**
    * `<org_name>`: The name of your organization (e.g., `OCP0Lab`, `TAMLab`, `HomeLab`).
    * `<environment_name>`: The name of your config directory (e.g., `my_prod`).
    * `[options]`:
        * `-a` or `--all`: Export *all* supported configurations.
        * `-t "tag1,tag2"`: Export *only* the specific items you list.

**Example: Export only Projects and Credentials**
```bash
./export.sh OCP0Lab my_prod -t "controller_projects,controller_credentials"
```
* **What this does:**
    1.  Reads `orgs_vars/OCP0Lab/my_prod/vars.env` to find this env is for AAP 2.6 (or whichever version you selected).
    2.  Reads connection details from your encrypted `orgs_vars/OCP0Lab/my_prod/vault.yml`.
    3.  Connects to your AAP 2.6 instance.
    4.  Saves the resulting YAML files into a new, timestamped directory like `orgs_vars/OCP0Lab/my_prod/exports/my_prod_export_20251028_193000/`.

---

### Importing Configuration

This command reads from your local files and configures your AAP instance.

* **Command:** `./import.sh <org_name> <environment_name> [options]`
* **Arguments:**
    * `<org_name>`: The name of your organization (e.g., `OCP0Lab`, `TAMLab`, `HomeLab`).
    * `<environment_name>`: The name of your config directory (e.g., `my_prod`).
    * `[options]`:
        * `-a` or `--all`: Import *all* configurations from the `imports` directory and `common` directory.
        * `-t "tag1,tag2"`: Import *only* the specific items you list.

**Example: Import only Projects**

1.  **First, copy your config files:** Before you can import, you must place your configuration files into the `imports` directory for your environment.
    ```bash
    # (Assuming you already exported)
    # cp orgs_vars/OCP0Lab/my_prod/exports/my_prod_export.../controller_projects.yml orgs_vars/OCP0Lab/my_prod/imports/
    ```

2.  **Run the import script:**
    ```bash
    ./import.sh OCP0Lab my_prod -t "controller_projects"
    ```
* **What this does:**
    1.  Reads `orgs_vars/OCP0Lab/my_prod/vars.env` to get the version.
    2.  Reads connection details from your encrypted `orgs_vars/OCP0Lab/my_prod/vault.yml`.
    3.  Connects to your AAP instance.
    4.  Applies *only* the configurations found that match the `controller_projects` tag from both the environment's `imports` directory and the organization's `common` directory.

> **💡 How to find all available tags?**
>
> The available tags are different for each AAP version and are now defined in the `script_vars/` directory.
>
> To see a full list of supported tags, run the script with just an organization name and environment name and no options (like `-a` or `-t`).
>
> ```bash
> ./export.sh OCP0Lab my_prod
> ```
>
> This will show the `Usage:` help text, which dynamically lists all valid tags for the version associated with `my_prod`.

## 💡 Tips and Advanced Usage

### Avoid Typing Your Vault Password
By default, these scripts will securely prompt you for your vault password every time they run.

If you are in a trusted environment and want to avoid this, you can tell Ansible where to find your password in a file.
1.  Create a simple text file containing *only* your vault password (e.g., `.vault_pass.txt`).

2.  **Secure this file:** `chmod 600 .vault_pass.txt`

3.  **Tell Ansible to use it.** You have two common options:

      * **Option 1 (Environment Variable):** Set an environment variable in your `.bashrc` or `.zshrc`:

        ```bash
         export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass.txt
        ```

      * **Option 2 (`ansible.cfg`):** Create a file named `ansible.cfg` (or `cp ansible.cfg.example ansible.cfg`) in this repository's root directory with the following content:

        ```ini
        [defaults]
        vault_password_file = .vault_pass.txt
        ```

4.  **Important:** If you create this `ansible.cfg` file, make sure to add it to your `.gitignore` file so you don't accidentally commit it!

## 📦 Supported AAP Versions

This tool is explicitly designed to support multiple AAP versions by loading different tasks and tag lists for each. Supported versions include:

* **AAP 2.6**
* **AAP 2.5**
* **AAP 2.4**

---

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Lenny Shirley.