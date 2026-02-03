@echo off
setlocal enabledelayedexpansion

REM Required environment variables
if "%TFSTATE_RESOURCE_GROUP%"=="" (
  echo TFSTATE_RESOURCE_GROUP is not set.
  exit /b 1
)
if "%TFSTATE_STORAGE_ACCOUNT%"=="" (
  echo TFSTATE_STORAGE_ACCOUNT is not set.
  exit /b 1
)
if "%TFSTATE_CONTAINER%"=="" (
  echo TFSTATE_CONTAINER is not set.
  exit /b 1
)
if "%TFSTATE_KEY%"=="" (
  echo TFSTATE_KEY is not set.
  exit /b 1
)
if "%APP_ID%"=="" (
  echo APP_ID is not set.
  exit /b 1
)
if "%TENANT_ID%"=="" (
  echo TENANT_ID is not set.
  exit /b 1
)
if "%CLIENT_SECRET%"=="" (
  echo CLIENT_SECRET is not set.
  exit /b 1
)
if "%ACR_NAME%"=="" (
  echo ACR_NAME is not set.
  exit /b 1
)
if "%ACR_RESOURCE_GROUP%"=="" (
  echo ACR_RESOURCE_GROUP is not set.
  exit /b 1
)
if "%ACR_LOCATION%"=="" (
  echo ACR_LOCATION is not set.
  exit /b 1
)

REM Azure login (service principal)
call az login --service-principal --username "%APP_ID%" --tenant "%TENANT_ID%" --password "%CLIENT_SECRET%" 1>nul
if errorlevel 1 (
  echo Azure login failed.
  exit /b 1
)

REM Build and push image to ACR first
if "%IMAGE_NAME%"=="" set IMAGE_NAME=cloudprogramming-app
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest
if "%IMAGE_REVISION%"=="" (
  for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set IMAGE_REVISION=%%i
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
