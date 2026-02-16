@echo off
setlocal

echo [STEP] Starting local Terraform deployment...

REM Required variables
if "%KEYVAULT_NAME%"=="" (
  echo KEYVAULT_NAME is not set.
  echo Please set KEYVAULT_NAME to the Azure Key Vault that stores deployment secrets.
  exit /b 1
)
echo [STEP] Using Key Vault: %KEYVAULT_NAME%

REM Ensure the local user is logged in to Azure to read secrets from Key Vault
echo [STEP] Validating Azure CLI login...
call az account show 1>nul 2>nul
if errorlevel 1 (
  echo Azure CLI is not logged in. Run "az login" first.
  exit /b 1
)

if not "%KEYVAULT_SUBSCRIPTION_ID%"=="" (
  call az account set --subscription "%KEYVAULT_SUBSCRIPTION_ID%" 1>nul
  if errorlevel 1 (
    echo Could not set Azure subscription "%KEYVAULT_SUBSCRIPTION_ID%".
    exit /b 1
  )
)

REM Default secret names (override via KV_SECRET_* variables if needed)
if "%KV_SECRET_ACR_NAME%"=="" set "KV_SECRET_ACR_NAME=acr-name"
if "%KV_SECRET_ACR_RESOURCE_GROUP%"=="" set "KV_SECRET_ACR_RESOURCE_GROUP=acr-resource-group"
if "%KV_SECRET_ACR_LOCATION%"=="" set "KV_SECRET_ACR_LOCATION=acr-location"
if "%KV_SECRET_APP_ID%"=="" set "KV_SECRET_APP_ID=app-id"
if "%KV_SECRET_TENANT_ID%"=="" set "KV_SECRET_TENANT_ID=tenant-id"
if "%KV_SECRET_CLIENT_SECRET%"=="" set "KV_SECRET_CLIENT_SECRET=client-secret"
if "%KV_SECRET_IMAGE_NAME%"=="" set "KV_SECRET_IMAGE_NAME=image-name"
if "%KV_SECRET_IMAGE_TAG%"=="" set "KV_SECRET_IMAGE_TAG=image-tag"
if "%KV_SECRET_TFSTATE_RESOURCE_GROUP%"=="" set "KV_SECRET_TFSTATE_RESOURCE_GROUP=tfstate-resource-group"
if "%KV_SECRET_TFSTATE_STORAGE_ACCOUNT%"=="" set "KV_SECRET_TFSTATE_STORAGE_ACCOUNT=tfstate-storage-account"
if "%KV_SECRET_TFSTATE_CONTAINER%"=="" set "KV_SECRET_TFSTATE_CONTAINER=tfstate-container"
if "%KV_SECRET_TFSTATE_KEY%"=="" set "KV_SECRET_TFSTATE_KEY=tfstate-key"

REM Load required values from Key Vault
echo [STEP] Loading required secrets from Key Vault...
call :load_required_secret ACR_NAME "%KV_SECRET_ACR_NAME%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_ACR_NAME%
  exit /b 1
)
call :load_required_secret ACR_RESOURCE_GROUP "%KV_SECRET_ACR_RESOURCE_GROUP%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_ACR_RESOURCE_GROUP%
  exit /b 1
)
call :load_required_secret ACR_LOCATION "%KV_SECRET_ACR_LOCATION%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_ACR_LOCATION%
  exit /b 1
)
call :load_required_secret APP_ID "%KV_SECRET_APP_ID%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_APP_ID%
  exit /b 1
)
call :load_required_secret TENANT_ID "%KV_SECRET_TENANT_ID%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_TENANT_ID%
  exit /b 1
)
call :load_required_secret CLIENT_SECRET "%KV_SECRET_CLIENT_SECRET%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_CLIENT_SECRET%
  exit /b 1
)
call :load_required_secret TFSTATE_RESOURCE_GROUP "%KV_SECRET_TFSTATE_RESOURCE_GROUP%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_TFSTATE_RESOURCE_GROUP%
  exit /b 1
)
call :load_required_secret TFSTATE_STORAGE_ACCOUNT "%KV_SECRET_TFSTATE_STORAGE_ACCOUNT%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_TFSTATE_STORAGE_ACCOUNT%
  exit /b 1
)
call :load_required_secret TFSTATE_CONTAINER "%KV_SECRET_TFSTATE_CONTAINER%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_TFSTATE_CONTAINER%
  exit /b 1
)
call :load_required_secret TFSTATE_KEY "%KV_SECRET_TFSTATE_KEY%"
if errorlevel 1 (
  echo [ERROR] Failed loading secret: %KV_SECRET_TFSTATE_KEY%
  exit /b 1
)

REM Optional values from Key Vault (with local defaults)
call :load_optional_secret IMAGE_NAME "%KV_SECRET_IMAGE_NAME%"
call :load_optional_secret IMAGE_TAG "%KV_SECRET_IMAGE_TAG%"

REM Azure login (service principal)
echo [STEP] Logging in with service principal...
call az login --service-principal --username "%APP_ID%" --tenant "%TENANT_ID%" --password "%CLIENT_SECRET%" 1>nul
if errorlevel 1 (
  echo Azure login failed.
  exit /b 1
)

REM Build and push image to ACR first
if "%IMAGE_NAME%"=="" set "IMAGE_NAME=cloudprogramming-app"
if "%IMAGE_TAG%"=="" set "IMAGE_TAG=latest"
if "%IMAGE_REVISION%"=="" (
  for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "IMAGE_REVISION=%%i"
)
echo [INFO] ACR_NAME=%ACR_NAME%
echo [INFO] ACR_RESOURCE_GROUP=%ACR_RESOURCE_GROUP%
echo [INFO] ACR_LOCATION=%ACR_LOCATION%
echo [INFO] IMAGE_NAME=%IMAGE_NAME%
echo [INFO] IMAGE_TAG=%IMAGE_TAG%
echo [INFO] IMAGE_REVISION=%IMAGE_REVISION%

call az group create --name "%ACR_RESOURCE_GROUP%" --location "%ACR_LOCATION%"
call az acr create --name "%ACR_NAME%" --resource-group "%ACR_RESOURCE_GROUP%" --location "%ACR_LOCATION%" --sku Basic
call az acr login --name "%ACR_NAME%"
if errorlevel 1 (
  echo ACR login failed.
  exit /b 1
)

docker build -t "%ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%" -t "%ACR_NAME%.azurecr.io/%IMAGE_NAME%:latest" .
if errorlevel 1 (
  echo Docker build failed.
  exit /b 1
)

docker push "%ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%"
if errorlevel 1 (
  echo Docker push failed for tag %IMAGE_TAG%.
  exit /b 1
)

REM Ensure state storage exists
call az group create --name "%TFSTATE_RESOURCE_GROUP%" --location "westeurope"
call az storage account create --name "%TFSTATE_STORAGE_ACCOUNT%" --resource-group "%TFSTATE_RESOURCE_GROUP%" --location "westeurope" --sku Standard_LRS
call az storage container create --name "%TFSTATE_CONTAINER%" --account-name "%TFSTATE_STORAGE_ACCOUNT%" --auth-mode login

REM Terraform init with remote backend
pushd infra
terraform init ^
  -backend-config="resource_group_name=%TFSTATE_RESOURCE_GROUP%" ^
  -backend-config="storage_account_name=%TFSTATE_STORAGE_ACCOUNT%" ^
  -backend-config="container_name=%TFSTATE_CONTAINER%" ^
  -backend-config="key=%TFSTATE_KEY%"

if errorlevel 1 (
  popd
  exit /b 1
)

REM Bootstrap resource group (keep later steps fast)
terraform apply -auto-approve ^
  -target=azurerm_resource_group.main ^
  -var "acr_name=%ACR_NAME%" ^
  -var "acr_resource_group_name=%ACR_RESOURCE_GROUP%" ^
  -var "image_name=%IMAGE_NAME%" ^
  -var "image_tag=%IMAGE_TAG%" ^
  -var "image_revision=%IMAGE_REVISION%" ^
  -var "use_existing_acr=true"

if errorlevel 1 (
  popd
  exit /b 1
)

REM Full apply
terraform apply -auto-approve ^
  -var "acr_name=%ACR_NAME%" ^
  -var "acr_resource_group_name=%ACR_RESOURCE_GROUP%" ^
  -var "image_name=%IMAGE_NAME%" ^
  -var "image_tag=%IMAGE_TAG%" ^
  -var "image_revision=%IMAGE_REVISION%" ^
  -var "use_existing_acr=true"
set TF_EXIT=%errorlevel%
popd
exit /b %TF_EXIT%

:load_required_secret
set "TARGET_VAR=%~1"
set "SECRET_NAME=%~2"
set "SECRET_VALUE="
for /f "usebackq delims=" %%i in (`az keyvault secret show --vault-name "%KEYVAULT_NAME%" --name "%SECRET_NAME%" --query value -o tsv 2^>nul`) do set "SECRET_VALUE=%%i"
if "%SECRET_VALUE%"=="" (
  echo Required Key Vault secret "%SECRET_NAME%" is missing or unreadable.
  exit /b 1
)
set "%TARGET_VAR%=%SECRET_VALUE%"
exit /b 0

:load_optional_secret
set "TARGET_VAR=%~1"
set "SECRET_NAME=%~2"
set "SECRET_VALUE="
for /f "usebackq delims=" %%i in (`az keyvault secret show --vault-name "%KEYVAULT_NAME%" --name "%SECRET_NAME%" --query value -o tsv 2^>nul`) do set "SECRET_VALUE=%%i"
if defined SECRET_VALUE (
  set "%TARGET_VAR%=%SECRET_VALUE%"
)
exit /b 0
