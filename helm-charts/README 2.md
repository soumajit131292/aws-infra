# Git Setup and Repository Cloning

Follow the steps below to set up Git and clone the repository for your project.

## 1. Create `SetGIT.bat` File

Create a batch file named `SetGIT.bat` and add the following lines:

```batch
SET GITHUB_USER=support@craveinfotech.com
SET GITHUB_TOKEN=<Token>
SET GITHUB_REPOSITORY=SupportCrave/AccessHub
SET PATH=%PATH%;<GIT_INSTALL_FOLDER>/bin;
git config --global user.name "<Provide developer name>"
git config --global user.email <Provide developer email id>
```

Replace `<Token>`, `<Provide developer name>`, and `<Provide developer email id>` with the actual values.

## 2. Save and Run the Batch File

Save the `SetGIT.bat` file and run it in the folder where you want to clone the Git repository.

## 3. Update Developer Information

Edit the `SetGIT.bat` file to update the `user.name` and `user.email` variables with your name and email address.

**Note:** This is a mandatory step to ensure that commits are identified with your details instead of the machine name.

## 4. Run the Batch File

Run the `SetGIT.bat` file from the folder where you want to clone the repository.

## 5. Clone the Repository

Use the following command to clone the repository:

```bash
git clone https://%GITHUB_TOKEN%:@github.com/%GITHUB_REPOSITORY%/AccessHubReactUI
```

## 6. Folder Usage Guidelines

Use the following folders for check-ins based on your module development:

- **AccessHubGateway**: Connector Code (Assigned to Asro)
- **AccessHubGRCSoap**: GRC Connector (Assigned to Pramod)
- **AccessHubReactUI**: Frontend UI (Assigned to Pratik)
- **AccessHubRoleContent**: Python Code for Role Content (Assigned to Harish)

## 7. Adding and Committing Code

Use Git commands to add your code to the respective module folder. Example:

```bash
cd AccessHubReactUI
git add <UIFolder>
git commit -m "Adding folders for React front-end UI."
git push origin main
```
